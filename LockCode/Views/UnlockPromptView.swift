import AppKit
import SwiftUI

struct UnlockPromptView: View {
    let applicationName: String
    let bundleURL: URL?
    let promptMessage: String
    let touchIDEnabled: Bool
    let touchIDAvailable: Bool
    let verifyPIN: (String) async -> Bool
    let pinFailureMessage: () -> String
    let verifyBiometrics: () async -> Bool
    let onApproved: () -> Void
    let onCancelled: () -> Void

    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @FocusState private var pinFocused: Bool

    var body: some View {
        VStack(spacing: 18) {
            appIcon

            VStack(spacing: 6) {
                Text("Aplicación protegida")
                    .font(.title2.weight(.semibold))
                Text(promptMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SecureField("Código", text: $pin)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .focused($pinFocused)
                .onChange(of: pin) { newValue in
                    pin = PINPolicy.normalized(newValue)
                    errorMessage = nil
                }
                .onSubmit(unlockWithPIN)

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancelar", role: .cancel, action: onCancelled)

                if touchIDEnabled && touchIDAvailable {
                    Button("Touch ID") {
                        unlockWithBiometrics()
                    }
                }

                Button("Desbloquear", action: unlockWithPIN)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!PINPolicy.isValid(pin) || isWorking)
            }
        }
        .padding(28)
        .frame(width: 390)
        .onAppear {
            pinFocused = true
            if touchIDEnabled && touchIDAvailable {
                unlockWithBiometrics()
            }
        }
    }

    private var appIcon: some View {
        Group {
            if let bundleURL {
                Image(nsImage: NSWorkspace.shared.icon(forFile: bundleURL.path))
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "lock.app.dashed")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 72, height: 72)
    }

    private func unlockWithPIN() {
        guard PINPolicy.isValid(pin), !isWorking else { return }
        let candidate = pin
        pin = ""
        isWorking = true
        Task { @MainActor in
            let valid = await verifyPIN(candidate)
            isWorking = false
            if valid {
                onApproved()
            } else {
                errorMessage = pinFailureMessage()
                pinFocused = true
            }
        }
    }

    private func unlockWithBiometrics() {
        guard !isWorking else { return }
        isWorking = true
        Task { @MainActor in
            let valid = await verifyBiometrics()
            isWorking = false
            if valid {
                onApproved()
            } else {
                pinFocused = true
            }
        }
    }
}
