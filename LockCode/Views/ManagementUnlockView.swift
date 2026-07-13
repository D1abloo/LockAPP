import SwiftUI

struct ManagementUnlockView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @FocusState private var pinFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            BrandLogoView(size: 72)

            Text("Configuración bloqueada")
                .font(.title.bold())
            Text("Autentícate para administrar las aplicaciones protegidas.")
                .foregroundStyle(.secondary)

            SecureField("Código", text: $pin)
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)
                .focused($pinFocused)
                .onChange(of: pin) { pin = PINPolicy.normalized($0) }
                .onSubmit(unlockWithPIN)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }

            HStack {
                if model.settings.touchIDEnabled && model.canUseBiometrics() {
                    Button("Touch ID") { unlockWithBiometrics() }
                }
                Button("Desbloquear", action: unlockWithPIN)
                    .buttonStyle(.borderedProminent)
                    .disabled(!PINPolicy.isValid(pin) || isWorking)
            }
        }
        .padding(40)
        .onAppear {
            pinFocused = true
            if model.settings.touchIDEnabled && model.canUseBiometrics() {
                unlockWithBiometrics()
            }
        }
    }

    private func unlockWithPIN() {
        guard !isWorking else { return }
        let candidate = pin
        pin = ""
        if model.authenticateManagement(pin: candidate) {
            errorMessage = nil
        } else {
            errorMessage = model.pinFailureMessage()
            pinFocused = true
        }
    }

    private func unlockWithBiometrics() {
        guard !isWorking else { return }
        isWorking = true
        Task { @MainActor in
            let success = await model.authenticateManagementWithBiometrics()
            isWorking = false
            if !success { pinFocused = true }
        }
    }
}
