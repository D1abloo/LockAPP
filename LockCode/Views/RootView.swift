import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.isConfigurationLoading {
                VStack(spacing: 14) {
                    BrandLogoView(size: 72)
                    ProgressView("Iniciando protección…")
                }
            } else if !model.isConfigured {
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
        .tint(Color(red: 0.78, green: 0.08, blue: 0.12))
    }
}

private struct ManagementView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: Section = .applications

    enum Section: String, CaseIterable, Identifiable {
        case applications = "Aplicaciones"
        case settings = "Ajustes"
        case audit = "Registro"
        case help = "Ayuda y soporte"
        case updates = "Actualizaciones"
        case about = "Acerca de"
        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .applications: return "square.grid.2x2"
            case .settings: return "gearshape"
            case .audit: return "list.bullet.clipboard"
            case .help: return "questionmark.circle"
            case .updates: return "arrow.triangle.2.circlepath"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List([Section.applications, .settings, .audit, .updates], selection: $selection) { section in
                    Label(section.rawValue, systemImage: section.systemImage)
                        .tag(section)
                }

                Divider()

                VStack(spacing: 4) {
                    sidebarButton(for: .help)
                    sidebarButton(for: .about)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Button {
                        model.lockNow()
                    } label: {
                        Label("Bloquear ahora", systemImage: "lock.fill")
                    }
                        .buttonStyle(.borderedProminent)
                    Button {
                        model.lockManagement()
                    } label: {
                        Label("Bloquear configuración", systemImage: "gearshape.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("LockCode")
        } detail: {
            switch selection {
            case .applications:
                ApplicationsView()
            case .settings:
                SettingsView()
            case .audit:
                AuditLogView(auditLog: model.auditLog)
            case .help:
                HelpSupportView()
            case .updates:
                UpdatesView()
            case .about:
                AboutView()
            }
        }
    }

    private func sidebarButton(for section: Section) -> some View {
        Button {
            selection = section
        } label: {
            HStack {
                Label(section.rawValue, systemImage: section.systemImage)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                selection == section ? Color.accentColor.opacity(0.16) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
