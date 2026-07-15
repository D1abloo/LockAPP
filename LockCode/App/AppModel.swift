import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var installedApplications: [InstalledApplication] = []
    @Published private(set) var isConfigured: Bool
    @Published private(set) var isConfigurationLoading = true
    @Published var isManagementUnlocked = false
    @Published var isLoadingApplications = false
    @Published var errorMessage: String?

    let settings: SettingsStore
    lazy var launchAtLoginService = LaunchAtLoginService()
    lazy var auditLog = AuditLogStore()
    lazy var updateService = UpdateService()

    private let authenticationService: AuthenticationService
    private let catalogService = AppCatalogService()
    private let protectionService: AppProtectionService
    private let unlockPanelController = UnlockPanelController()
    private lazy var updateNotificationService = UpdateNotificationService { [weak self] in
        await self?.installAvailableUpdate()
    }
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
        self.protectionService = AppProtectionService(
            settings: settings,
            ownBundleIdentifier: ownBundleIdentifier
        )
        // Keychain can take several seconds to answer immediately after login.
        // Start with a closed UI state; protection is started before querying it.
        self.isConfigured = false

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
        Task {
            let hasPIN = await Task.detached(priority: .userInitiated) {
                KeychainPINStore().hasPIN
            }.value
            isConfigured = hasPIN
            isConfigurationLoading = false
        }
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
        let scanned = await catalogService.loadInstalledApplications(
            excluding: protectionService.excludedBundleIdentifiers
        )
        var applications = Dictionary(uniqueKeysWithValues: scanned.map { ($0.bundleIdentifier, $0) })
        for application in settings.manuallyAddedApplications
        where !protectionService.excludedBundleIdentifiers.contains(application.bundleIdentifier)
            && FileManager.default.fileExists(atPath: application.bundleURL.path) {
            applications[application.bundleIdentifier] = application
        }
        installedApplications = applications.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        isLoadingApplications = false
    }

    func addApplicationManually() {
        let panel = NSOpenPanel()
        panel.title = "Añadir aplicación a LockCode"
        panel.prompt = "Añadir y proteger"
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        guard panel.runModal() == .OK, let url = panel.url,
              let application = catalogService.application(
                at: url,
                excluding: protectionService.excludedBundleIdentifiers
              ) else {
            if panel.url != nil { errorMessage = "Selecciona una aplicación .app válida distinta de LockCode." }
            return
        }
        settings.addManually(application)
        setProtected(true, application: application)
        Task { await refreshApplications() }
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

    func unlockPolicyDidChange() {
        protectionService.unlockPolicyDidChange()
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

    func installAvailableUpdate() async {
        if !updateService.updateAvailable {
            await updateService.checkForUpdates()
        }
        guard let applicationURL = await updateService.installAvailableUpdate() else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) {
            [weak self] _, error in
            Task { @MainActor in
                if let error {
                    self?.errorMessage = "La actualización se instaló, pero no pudo reiniciarse: \(error.localizedDescription)"
                    return
                }
                self?.isQuitAuthorized = true
                NSApp.terminate(nil)
            }
        }
    }

    func requestQuit() {
        guard !unlockPanelController.isPresented else { return }
        guard !isConfigurationLoading else { return }
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
        // Refresh an existing registration once after each installed build.
        // This repairs stale Background Task Management records left by an
        // in-place replacement or a change from ad-hoc to stable signing.
        await launchAtLoginService.setEnabled(true, repairAfterUpdate: true)
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
            protectedBundleIdentifier: request.bundleIdentifier,
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
