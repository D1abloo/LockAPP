import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        MenuBarContent(
            model: model,
            settings: model.settings
        )
    }
}

private struct MenuBarContent: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: SettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Abrir aplicaciones") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Abrir ajustes") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Bloquear ahora") {
            model.lockNow()
        }

        Divider()

        Toggle("Protección activa", isOn: Binding(
            get: { settings.protectionEnabled },
            set: { model.setProtectionEnabled($0) }
        ))

        Divider()

        Button("Salir…") {
            model.requestQuit()
        }
    }
}
