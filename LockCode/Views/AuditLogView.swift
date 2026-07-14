import SwiftUI

struct AuditLogView: View {
    @ObservedObject var auditLog: AuditLogStore
    @State private var isConfirmingClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                BrandLogoView(size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registro de acceso")
                        .font(.largeTitle.bold())
                    Text("Desbloqueos e intentos fallidos registrados en este Mac.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Borrar registro", role: .destructive) {
                    isConfirmingClear = true
                }
                .disabled(auditLog.events.isEmpty)
            }
            .padding(28)

            Divider()

            if auditLog.events.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                    Text("Sin actividad")
                        .font(.title2.bold())
                    Text("Los próximos desbloqueos e intentos fallidos aparecerán aquí.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(auditLog.events) { event in
                    HStack(spacing: 14) {
                        Image(systemName: event.kind.systemImage)
                            .font(.title2)
                            .foregroundStyle(event.kind == .unlocked ? .green : .red)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.kind.title)
                                .fontWeight(.medium)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Text("El registro no contiene códigos, datos de Touch ID ni nombres de aplicaciones.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
        }
        .navigationTitle("Registro")
        .confirmationDialog(
            "¿Borrar todo el registro?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Borrar registro", role: .destructive) { auditLog.clear() }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
