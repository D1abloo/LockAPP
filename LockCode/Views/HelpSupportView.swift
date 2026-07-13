import SwiftUI

struct HelpSupportView: View {
    private let donationURL = URL(
        string: "https://www.paypal.com/donate/?business=kin_coriano14%40hotmail.com&no_recurring=0&currency_code=EUR"
    )!
    private let supportURL = URL(string: "https://github.com/D1abloo/LockAPP/issues")!
    private let emailURL = URL(string: "mailto:kin_coriano14@hotmail.com")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                HelpCard(title: "Primeros pasos", systemImage: "1.circle.fill") {
                    Text("Crea un código de 4 a 16 letras o números. Después abre Aplicaciones, busca cada app privada y activa su interruptor de protección.")
                    Text("El código distingue entre mayúsculas y minúsculas; combina ambas con números para hacerlo más resistente.")
                    Text("LockCode debe permanecer abierto. El icono de la barra de menús permite pausar la protección, bloquear todas las autorizaciones o volver a los ajustes.")
                }

                HelpCard(title: "Desbloqueo y Touch ID", systemImage: "touchid") {
                    Text("Cuando abras o actives una aplicación protegida, LockCode la ocultará y solicitará autenticación. Si Touch ID está habilitado y disponible, el diálogo biométrico aparecerá automáticamente; siempre puedes cancelar y usar el código.")
                }

                HelpCard(title: "Cuándo vuelve a bloquearse", systemImage: "timer") {
                    Text("El modo «Al cerrar la aplicación» mantiene el acceso únicamente mientras esa aplicación siga abierta. Los intervalos por minutos conservan la autorización hasta que se cumpla el tiempo elegido, aunque cambies de aplicación.")
                    Text("«Bloquear ahora» invalida inmediatamente todas las autorizaciones, independientemente del modo seleccionado.")
                }

                HelpCard(title: "Inicio con macOS", systemImage: "power") {
                    Text("Activa «Iniciar LockCode con macOS» en Ajustes. Si macOS solicita aprobación, abre Ítems de inicio y permite LockCode. La aplicación debe estar instalada en /Applications y correctamente firmada.")
                }

                HelpCard(title: "Privacidad y límites", systemImage: "exclamationmark.shield") {
                    Text("LockCode es una protección de privacidad de tipo best effort. Reacciona después de que macOS lanza o activa una aplicación; no sustituye controles parentales, una cuenta separada ni una solución basada en Endpoint Security.")
                    Text("El código no se guarda en texto plano: solo se conserva en Keychain una credencial derivada con sal aleatoria.")
                }

                HelpCard(title: "Ayuda y soporte", systemImage: "questionmark.bubble") {
                    Text("Si encuentras un error, describe qué aplicación estabas protegiendo, la versión de macOS y los pasos para reproducirlo. No incluyas tu código ni nombres de aplicaciones privadas si no es necesario.")
                    HStack {
                        Link("Abrir incidencias en GitHub", destination: supportURL)
                        Spacer()
                        Link("Contactar por correo", destination: emailURL)
                    }
                }

                HelpCard(title: "Proyecto y donaciones", systemImage: "heart.fill") {
                    Text("LockCode es de uso gratuito y no necesitas realizar ninguna donación. Si quieres apoyar voluntariamente el desarrollo, puedes hacerlo ;)")
                    Link(destination: donationURL) {
                        Label("Donar con PayPal", systemImage: "heart.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Text("Cuenta de donación: kin_coriano14@hotmail.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Software realizado por Isaac Silva Jiménez.")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(28)
        }
        .navigationTitle("Ayuda y soporte")
    }

    private var header: some View {
        HStack(spacing: 18) {
            BrandLogoView(size: 76)
            VStack(alignment: .leading, spacing: 5) {
                Text("Ayuda y soporte")
                    .font(.largeTitle.bold())
                Text("Guía rápida para configurar y utilizar LockCode con seguridad.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HelpCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
        }
    }
}
