import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsContentView(
            model: model,
            settings: model.settings,
            launchAtLoginService: model.launchAtLoginService
        )
    }
}

private struct SettingsContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: SettingsStore
    @ObservedObject var launchAtLoginService: LaunchAtLoginService

    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmation = ""
    @State private var pinMessage: String?

    var body: some View {
        Form {
            Section("Protección") {
                Toggle("Protección activa", isOn: Binding(
                    get: { settings.protectionEnabled },
                    set: { model.setProtectionEnabled($0) }
                ))
                Toggle("Permitir Touch ID", isOn: $settings.touchIDEnabled)
                    .disabled(!model.canUseBiometrics())

                Picker("Volver a pedir el código", selection: $settings.unlockDuration) {
                    ForEach(UnlockDuration.allCases) { duration in
                        Text(duration.title).tag(duration)
                    }
                }

                if settings.unlockDuration == .custom {
                    HStack {
                        Text("Minutos de desbloqueo")
                        Spacer()
                        TextField(
                            "Minutos",
                            value: $settings.customUnlockMinutes,
                            format: .number
                        )
                        .frame(width: 80)
                        Stepper(
                            "",
                            value: $settings.customUnlockMinutes,
                            in: 1...1_440
                        )
                        .labelsHidden()
                    }
                }

                Text(unlockDurationExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    model.lockNow()
                } label: {
                    Label("Bloquear ahora", systemImage: "lock.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Inicio de sesión") {
                Toggle("Iniciar LockCode con macOS", isOn: Binding(
                    get: { settings.launchAtLoginEnabled },
                    set: { newValue in
                        Task { await model.setLaunchAtLoginEnabled(newValue) }
                    }
                ))

                Text(loginItemStatusText)
                    .font(.caption)
                    .foregroundStyle(loginItemStatusColor)

                if launchAtLoginService.state == .requiresApproval {
                    Button("Abrir Ítems de inicio") {
                        launchAtLoginService.openSystemSettings()
                    }
                }
                if let error = launchAtLoginService.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section("Cambiar código") {
                Text("Usa entre 4 y 64 caracteres. Se admiten letras, números, espacios y símbolos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Código actual", text: $currentPIN)
                    .onChange(of: currentPIN) { currentPIN = PINPolicy.normalized($0) }
                SecureField("Código nuevo", text: $newPIN)
                    .onChange(of: newPIN) { newPIN = PINPolicy.normalized($0) }
                SecureField("Repetir código nuevo", text: $confirmation)
                    .onChange(of: confirmation) { confirmation = PINPolicy.normalized($0) }

                Button("Cambiar código") {
                    let currentCandidate = currentPIN
                    let newCandidate = newPIN
                    let confirmationCandidate = confirmation
                    currentPIN = ""
                    newPIN = ""
                    confirmation = ""

                    guard newCandidate == confirmationCandidate else {
                        pinMessage = "Los códigos nuevos no coinciden."
                        return
                    }
                    if model.changePIN(currentPIN: currentCandidate, newPIN: newCandidate) {
                        pinMessage = "Código actualizado."
                    } else {
                        pinMessage = model.pinFailureMessage()
                    }
                }
                .disabled(!PINPolicy.isValid(currentPIN) || !PINPolicy.isValid(newPIN))

                if let pinMessage {
                    Text(pinMessage).font(.caption)
                }
            }

            Section("Nivel de protección") {
                Label(
                    "Este MVP reduce accesos casuales, pero no sustituye una extensión de seguridad del sistema.",
                    systemImage: "exclamationmark.shield"
                )
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Ajustes")
        .padding()
        .onAppear { launchAtLoginService.refresh() }
        .onChange(of: settings.unlockDuration) { _ in
            model.unlockPolicyDidChange()
        }
        .onChange(of: settings.customUnlockMinutes) { _ in
            guard settings.unlockDuration == .custom else { return }
            model.unlockPolicyDidChange()
        }
    }

    private var unlockDurationExplanation: String {
        if settings.unlockDuration.keepsAccessUntilApplicationCloses {
            return "La autorización termina en cuanto se cierra la aplicación protegida."
        }
        if settings.unlockDuration == .custom {
            let minutes = min(max(settings.customUnlockMinutes, 1), 1_440)
            return "La aplicación volverá a bloquearse después de \(minutes) minuto\(minutes == 1 ? "" : "s")."
        }
        return "La aplicación volverá a bloquearse cuando finalice este intervalo."
    }

    private var loginItemStatusText: String {
        switch launchAtLoginService.state {
        case .enabled:
            return "El inicio automático está habilitado."
        case .notRegistered:
            return "El inicio automático está deshabilitado."
        case .requiresApproval:
            return "macOS requiere aprobación en Ajustes del Sistema > General > Ítems de inicio."
        case .unavailable:
            return "macOS no puede localizar o gestionar esta copia de LockCode. Instálala en /Applications y comprueba la firma."
        }
    }

    private var loginItemStatusColor: Color {
        switch launchAtLoginService.state {
        case .requiresApproval, .unavailable: return .orange
        case .enabled, .notRegistered: return .secondary
        }
    }
}
