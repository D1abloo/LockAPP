import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if !model.isConfigured {
                OnboardingView()
            } else if !model.isManagementUnlocked {
                ManagementUnlockView()
            } else {
                ManagementView()
            }
        }
        .alert("LockCode", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

private struct ManagementView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: Section = .applications

    enum Section: String, CaseIterable, Identifiable {
        case applications = "Aplicaciones"
        case settings = "Ajustes"
        case help = "Ayuda y soporte"
        case updates = "Actualizaciones"
        case about = "Acerca de"
        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .applications: return "square.grid.2x2"
            case .settings: return "gearshape"
            case .help: return "questionmark.circle"
            case .updates: return "arrow.triangle.2.circlepath"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("LockCode")
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button("Bloquear ahora") { model.lockNow() }
                        .buttonStyle(.borderedProminent)
                    Button("Bloquear configuración") { model.lockManagement() }
                        .buttonStyle(.plain)
                }
                .padding()
            }
        } detail: {
            switch selection {
            case .applications:
                ApplicationsView()
            case .settings:
                SettingsView()
            case .help:
                HelpSupportView()
            case .updates:
                UpdatesView()
            case .about:
                AboutView()
            }
        }
    }
}
