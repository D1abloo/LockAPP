import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 18) {
            BrandLogoView(size: 88)
            Text("LockCode")
                .font(.largeTitle.bold())
            Text("Versión \(version) — MVP")
                .foregroundStyle(.secondary)
            Text("Software realizado por Isaac Silva Jiménez")
                .font(.headline)
            Text("Copyright © 2026 Isaac SJ. Todos los derechos reservados.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            GroupBox("Aviso de seguridad") {
                Text("LockCode observa lanzamientos y activaciones después de que ocurren. Está pensado para privacidad casual y no puede resistir a un administrador o a alguien que cierre el proceso.")
                    .frame(maxWidth: 460, alignment: .leading)
                    .padding(4)
            }

            Text("Una edición reforzada deberá usar una System Extension con Endpoint Security y permisos aprobados por Apple.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
        }
        .padding(40)
        .navigationTitle("Acerca de")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0.4.2"
    }
}
