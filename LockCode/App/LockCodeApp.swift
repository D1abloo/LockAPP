import SwiftUI

@main
@MainActor
struct LockCodeApp: App {
    @NSApplicationDelegateAdaptor(LockCodeApplicationDelegate.self) private var appDelegate
    @StateObject private var model: AppModel

    init() {
        let model = AppModel()
        _model = StateObject(wrappedValue: model)
        appDelegate.model = model
        model.start()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 520)
                .onDisappear { model.lockManagement() }
        }
        .defaultSize(width: 860, height: 600)

        MenuBarExtra("LockCode", systemImage: "lock.shield") {
            MenuBarContentView()
                .environmentObject(model)
        }

        Settings {
            Group {
                if !model.isConfigured {
                    OnboardingView()
                } else if !model.isManagementUnlocked {
                    ManagementUnlockView()
                } else {
                    SettingsView()
                }
            }
            .environmentObject(model)
            .frame(width: 520, height: 430)
            .onDisappear { model.lockManagement() }
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Salir de LockCode") {
                    model.requestQuit()
                }
                .keyboardShortcut("q")
            }
        }
    }
}
