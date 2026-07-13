import AppKit
import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var searchText = ""

    private var filteredApplications: [InstalledApplication] {
        guard !searchText.isEmpty else { return model.installedApplications }
        return model.installedApplications.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aplicaciones")
                        .font(.largeTitle.bold())
                    Text("Activa la protección para las aplicaciones privadas.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await model.refreshApplications() }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                }
            }
            .padding()

            if model.isLoadingApplications {
                ProgressView("Buscando aplicaciones…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApplications) { application in
                    ApplicationRow(
                        application: application,
                        settings: model.settings,
                        onSetProtected: { model.setProtected($0, application: application) }
                    )
                }
                .searchable(text: $searchText, prompt: "Buscar aplicación")
            }
        }
    }
}

private struct ApplicationRow: View {
    let application: InstalledApplication
    @ObservedObject var settings: SettingsStore
    let onSetProtected: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: application.bundleURL.path))
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(application.displayName)
                Text(application.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Proteger", isOn: Binding(
                get: { settings.isProtected(application.bundleIdentifier) },
                set: { value in onSetProtected(value) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
