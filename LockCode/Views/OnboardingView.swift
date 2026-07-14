import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var localError: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case pin
        case confirmation
    }

    var body: some View {
        VStack(spacing: 22) {
            BrandLogoView(size: 96)

            VStack(spacing: 8) {
                Text("Configura LockCode")
                    .font(.largeTitle.bold())
                Text("Crea un código de 4 a 64 caracteres. Puedes combinar letras, números, espacios y símbolos.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Código")
                        .font(.headline)
                    SecureField("Introduce de 4 a 64 caracteres", text: $pin)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .focused($focusedField, equals: .pin)
                        .onChange(of: pin) {
                            pin = PINPolicy.normalized($0)
                            localError = nil
                        }
                        .onSubmit { focusedField = .confirmation }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Repetir código")
                        .font(.headline)
                    SecureField("Vuelve a introducir el código", text: $confirmation)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .focused($focusedField, equals: .confirmation)
                        .onChange(of: confirmation) {
                            confirmation = PINPolicy.normalized($0)
                            localError = nil
                        }
                        .onSubmit(createProtection)
                }
            }
            .frame(width: 360)

            if let localError {
                Text(localError).foregroundStyle(.red)
            }

            Button("Crear protección", action: createProtection)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!PINPolicy.isValid(pin) || confirmation.isEmpty)

            Text("El código se guarda en el Keychain de macOS.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("El código distingue entre mayúsculas y minúsculas y admite símbolos.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .onAppear { focusedField = .pin }
    }

    private func createProtection() {
        guard PINPolicy.isValid(pin) else {
            localError = "El código debe contener entre 4 y 64 caracteres y no puede incluir saltos de línea."
            focusedField = .pin
            return
        }
        guard pin == confirmation else {
            localError = "Los códigos no coinciden."
            confirmation = ""
            focusedField = .confirmation
            return
        }
        let candidate = pin
        pin = ""
        confirmation = ""
        focusedField = nil
        model.completeOnboarding(pin: candidate)
    }
}
