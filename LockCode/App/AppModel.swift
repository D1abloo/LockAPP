import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var installedApplications: [InstalledApplication] = []
    @Published private(set) var isConfigured: Bool
    @Published var isManagementUnlocked = false
    @Published var isLoadingApplications = false
    @Published var errorMessage: String?

    let settings: SettingsStore
    let launchAtLoginService: LaunchAtLoginService
    let auditLog: AuditLogStore
    let updateService: UpdateService

    private let authenticationService: AuthenticationService
    private let catalogService = AppCatalogService()
    private let protectionService: AppProtectionService
    private let unlockPanelController = UnlockPanelController()
    private let updateNotificationService: UpdateNotificationService
    private var queuedRequests: [AccessRequest] = []
    private var isStarted = false
    private var isQuitAuthorized = false

    init() {
        let pinStore = KeychainPINStore()
        let authenticationService = AuthenticationService(pinStore: pinStore)
        let settings = SettingsStore()
        let ownBundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.LockCode"

        self.authenticationService = authenticationService
        self.settings = settings
        self.launchAtLoginService = LaunchAtLoginService()
        self.auditLog = AuditLogStore()
        self.updateService = UpdateService()
        self.updateNotificationService = UpdateNotificationService()
        self.protectionService = AppProtectionService(
            settings: settings,
            ownBundleIdentifier: ownBundleIdentifier
        )
        self.isConfigured = authenticationService.hasPIN

        protectionService.onBlocked = { [weak self] request in
            self?.enqueue(request)
        }
        protectionService.onSessionInvalidated = { [weak self] in
            self?.isManagementUnlocked = false
        }
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        protectionService.start()
        Task { await refreshApplications() }
        if settings.launchAtLoginEnabled {
            Task { await configureLaunchAtLogin() }
        }
        Task {
            await updateService.checkForUpdates()
            if updateService.updateAvailable, let release = updateService.latestRelease {
                await updateNotificationService.notifyIfNeeded(for: release)
            }
        }
    }

    func completeOnboarding(pin: String) {
        do {
            try authenticationService.setPIN(pin)
            isConfigured = true
            isManagementUnlocked = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePIN(currentPIN: String, newPIN: String) -> Bool {
        guard PINPolicy.isValid(currentPIN),
              PINPolicy.isValid(newPIN),
              authenticationService.validatePIN(currentPIN) else {
            return false
        }
        do {
            try authenticationService.setPIN(newPIN)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func authenticateManagement(pin: String) -> Bool {
        let valid = authenticationService.validatePIN(pin)
        if valid {
            isManagementUnlocked = true
        } else {
            auditLog.record(.failedAttempt)
        }
        return valid
    }

    func authenticateManagementWithBiometrics() async -> Bool {
        do {
            try await authenticationService.authenticateWithBiometrics(
                reason: "Acceder a la configuración de LockCode"
            )
            isManagementUnlocked = true
            return true
        } catch {
            return false
        }
    }

    func canUseBiometrics() -> Bool {
        authenticationService.canUseBiometrics()
    }

    func pinFailureMessage() -> String {
        authenticationService.pinFailureMessage()
    }

    func lockManagement() {
        isManagementUnlocked = false
    }

    func refreshApplications() async {
        isLoadingApplications = true
        installedApplications = await catalogService.loadInstalledApplications(
            excluding: protectionService.excludedBundleIdentifiers
        )
        isLoadingApplications = false
    }

    func setProtected(_ protected: Bool, application: InstalledApplication) {
        settings.setProtected(protected, bundleIdentifier: application.bundleIdentifier)
        if protected {
            protectionService.concealRunningApplication(
                bundleIdentifier: application.bundleIdentifier
            )
        } else {
            protectionService.invalidateAccess(for: application.bundleIdentifier)
        }
    }

    func lockNow() {
        protectionService.invalidateAllAccess()
        isManagementUnlocked = false
    }

    func setProtectionEnabled(_ enabled: Bool) {
        settings.protectionEnabled = enabled
        if enabled {
            protectionService.protectionDidBecomeEnabled()
        }
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) async {
        settings.launchAtLoginEnabled = enabled
        await launchAtLoginService.setEnabled(enabled)
    }

    func requestQuit() {
        guard !unlockPanelController.isPresented else { return }
        guard isConfigured else {
            isQuitAuthorized = true
            NSApp.terminate(nil)
            return
        }

        unlockPanelController.present(
            applicationName: "LockCode",
            bundleURL: Bundle.main.bundleURL,
            promptMessage: "Autentícate para salir de LockCode.",
            touchIDEnabled: settings.touchIDEnabled,
            touchIDAvailable: authenticationService.canUseBiometrics(),
            verifyPIN: { [weak self] pin in
                guard let self else { return false }
                let valid = self.authenticationService.validatePIN(pin)
                if !valid { self.auditLog.record(.failedAttempt) }
                return valid
            },
            pinFailureMessage: { [weak self] in
                self?.authenticationService.pinFailureMessage() ?? "Código incorrecto."
            },
            verifyBiometrics: { [weak self] in
                guard let self else { return false }
                do {
                    try await self.authenticationService.authenticateWithBiometrics(
                        reason: "Confirmar que quieres salir de LockCode"
                    )
                    return true
                } catch {
                    return false
                }
            },
            onApproved: {
                self.isQuitAuthorized = true
                NSApp.terminate(nil)
            },
            onCancelled: {}
        )
    }

    func consumeQuitAuthorization() -> Bool {
        guard isQuitAuthorized else { return false }
        isQuitAuthorized = false
        return true
    }

    private func configureLaunchAtLogin() async {
        await launchAtLoginService.setEnabled(true)
        if let lastError = launchAtLoginService.lastError, isConfigured {
            errorMessage = "No se pudo activar el inicio automático: \(lastError)"
        } else if launchAtLoginService.state == .requiresApproval, isConfigured {
            errorMessage = "LockCode necesita aprobación en Ajustes del Sistema > General > Ítems de inicio para arrancar automáticamente."
        }
    }

    private func enqueue(_ request: AccessRequest) {
        guard !queuedRequests.contains(where: { $0.bundleIdentifier == request.bundleIdentifier }) else {
            return
        }
        queuedRequests.append(request)
        presentNextRequestIfNeeded()
    }

    private func presentNextRequestIfNeeded() {
        guard !unlockPanelController.isPresented, let request = queuedRequests.first else { return }

        unlockPanelController.present(
            applicationName: request.applicationName,
            bundleURL: request.bundleURL,
            touchIDEnabled: settings.touchIDEnabled,
            touchIDAvailable: authenticationService.canUseBiometrics(),
            verifyPIN: { [weak self] pin in
                guard let self else { return false }
                let valid = self.authenticationService.validatePIN(pin)
                if !valid { self.auditLog.record(.failedAttempt) }
                return valid
            },
            pinFailureMessage: { [weak self] in
                self?.authenticationService.pinFailureMessage() ?? "Código incorrecto."
            },
            verifyBiometrics: { [weak self] in
                guard let self else { return false }
                do {
                    try await self.authenticationService.authenticateWithBiometrics(
                        reason: "Abrir \(request.applicationName)"
                    )
                    return true
                } catch {
                    return false
                }
            },
            onApproved: { [weak self] in
                guard let self else { return }
                self.queuedRequests.removeAll { $0.id == request.id }
                self.auditLog.record(.unlocked)
                self.protectionService.approve(request)
                self.presentNextRequestIfNeeded()
            },
            onCancelled: { [weak self] in
                guard let self else { return }
                self.queuedRequests.removeAll { $0.id == request.id }
                self.protectionService.deny(request)
                self.presentNextRequestIfNeeded()
            }
        )
    }
}
