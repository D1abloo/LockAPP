import SwiftUI

struct HelpSupportView: View {
    private let donationURL = URL(string: "https://www.paypal.com/paypalme/kin_coriano14")!
    private let supportURL = URL(string: "https://github.com/D1abloo/LockAPP/issues")!
    private let emailURL = URL(string: "mailto:isaaccoria46@gmail.com")!

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

                HelpCard(title: "Soporte técnico", systemImage: "questionmark.bubble") {
                    Text("Si necesitas ayuda, explica qué estabas intentando hacer, los pasos para reproducir el problema y las versiones de macOS y LockCode.")
                    Text("No envíes tu código, datos biométricos, registros privados ni información de las aplicaciones protegidas.")
                    Link("Abrir una incidencia en GitHub", destination: supportURL)
                    HStack(spacing: 6) {
                        Text("Correo de soporte:")
                        Link("isaaccoria46@gmail.com", destination: emailURL)
                    }
                }

                HelpCard(title: "Proyecto y donaciones", systemImage: "heart.fill") {
                    Text("LockCode es gratuito y todas sus funciones pueden utilizarse sin donar. Si deseas apoyar voluntariamente su mantenimiento y futuras mejoras, puedes hacerlo mediante PayPal ;)")
                    Link(destination: donationURL) {
                        Label("Donar con PayPal", systemImage: "heart.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Text("Copyright © 2026 Isaac Silva Jiménez.")
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
                Text("Guía práctica para configurar la protección, resolver dudas y contactar con soporte.")
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
