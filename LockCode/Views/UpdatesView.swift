import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        UpdatesContent(updateService: model.updateService)
    }
}

private struct UpdatesContent: View {
    @ObservedObject var updateService: UpdateService

    private let releasesURL = URL(string: "https://github.com/D1abloo/LockAPP/releases")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 18) {
                    BrandLogoView(size: 76)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Actualizaciones")
                            .font(.largeTitle.bold())
                        Text("Versión instalada: \(updateService.installedVersion)")
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("Buscar nuevas versiones") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            updateService.statusMessage,
                            systemImage: updateService.updateAvailable
                                ? "arrow.down.circle.fill"
                                : "checkmark.circle"
                        )
                        .foregroundStyle(updateService.updateAvailable ? .orange : .secondary)

                        HStack {
                            Button {
                                Task { await updateService.checkForUpdates() }
                            } label: {
                                if updateService.isChecking {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Label("Buscar actualizaciones", systemImage: "arrow.clockwise")
                                }
                            }
                            .disabled(updateService.isChecking)

                            if let release = updateService.latestRelease {
                                Link("Ver \(release.tagName) en GitHub", destination: release.htmlURL)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                if let release = updateService.latestRelease {
                    GroupBox(release.name ?? release.tagName) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let publishedAt = release.publishedAt {
                                Text("Publicada el \(publishedAt.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let body = release.body, !body.isEmpty {
                                Text(body)
                                    .textSelection(.enabled)
                            } else {
                                Text("Esta versión no incluye notas de cambios.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }
                }

                GroupBox("Canal de actualizaciones") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Las futuras versiones y mejoras se publicarán en GitHub Releases. LockCode solo comprueba la versión y abre la página oficial; nunca instala código sin tu confirmación.")
                        Text("Cuando exista una versión posterior, macOS mostrará una notificación con «Sí, actualizar» y «No ahora». El aviso de una misma versión se limita a una vez cada 24 horas.")
                        Link("Ver todas las versiones", destination: releasesURL)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(28)
        }
        .navigationTitle("Actualizaciones")
    }
}
