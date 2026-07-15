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
                    Text("Crea un código de 4 a 64 caracteres. Admite letras, números, espacios y símbolos, y distingue entre mayúsculas y minúsculas.")
                    Text("Abre Aplicaciones y activa la protección en cada programa que quieras controlar. Si ya está abierto, LockCode lo ocultará.")
                    Text("Mantén LockCode en ejecución. Desde su icono de la barra de menús puedes abrir la gestión, pausar la protección o usar «Bloquear ahora».")
                }

                HelpCard(title: "Desbloqueo y Touch ID", systemImage: "touchid") {
                    Text("Cuando abras o actives una aplicación protegida, LockCode la ocultará y solicitará autenticación. Si Touch ID está habilitado y disponible, el diálogo biométrico aparecerá automáticamente; siempre puedes cancelar y usar el código.")
                }

                HelpCard(title: "Cuándo vuelve a bloquearse", systemImage: "timer") {
                    Text("El modo «Al cerrar la aplicación» conserva el acceso solamente mientras esa aplicación siga abierta. Los intervalos por minutos mantienen la autorización hasta que termine el tiempo elegido.")
                    Text("«Bloquear ahora» invalida inmediatamente todas las autorizaciones, independientemente del modo seleccionado.")
                }

                HelpCard(title: "Registro de acceso", systemImage: "list.bullet.clipboard") {
                    Text("La sección Registro muestra la fecha y hora de los desbloqueos y de los intentos fallidos. Puedes borrar todo el historial cuando quieras.")
                    Text("Para reducir la información almacenada, no se incluyen códigos, datos biométricos ni nombres de aplicaciones.")
                }

                HelpCard(title: "Inicio con macOS", systemImage: "power") {
                    Text("Activa «Iniciar LockCode con macOS» en Ajustes. Si macOS solicita aprobación, abre Ítems de inicio y permite LockCode. La aplicación debe estar instalada en /Applications y correctamente firmada.")
                }

                HelpCard(title: "Actualizaciones", systemImage: "arrow.triangle.2.circlepath") {
                    Text("LockCode comprueba GitHub Releases al iniciarse. Si existe una versión posterior, macOS mostrará una notificación con las opciones «Sí, actualizar» y «No ahora».")
                    Text("Al aceptar, LockCode descarga el ZIP oficial, verifica su SHA-256, sustituye la copia instalada y se reinicia. Nunca instala una descarga sin tu intervención.")
                }

                HelpCard(title: "Ayuda y soporte", systemImage: "questionmark.bubble") {
                    Text("Si encuentras un problema, indica la versión de macOS, la versión de LockCode y los pasos necesarios para reproducirlo. Nunca envíes tu código de acceso.")
                    Link("Abrir una incidencia en GitHub", destination: supportURL)
                    HStack(spacing: 6) {
                        Text("Correo de contacto:")
                        Link("kin_coriano14@hotmail.com", destination: emailURL)
                    }
                }

                HelpCard(title: "Proyecto y donaciones", systemImage: "heart.fill") {
                    Text("LockCode es de uso gratuito y no necesitas realizar ninguna donación. Si quieres apoyar voluntariamente el desarrollo, puedes hacerlo ;)")
                    Link(destination: donationURL) {
                        Label("Donar con PayPal", systemImage: "heart.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Text("Software realizado por Isaac Silva Jiménez. Copyright © 2026 Isaac SJ.")
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
                Text("Guía de instalación, configuración, registro y actualizaciones.")
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
