# AGENTS.md — instrucciones para Codex

## Objetivo

Evolucionar LockCode como una aplicación macOS nativa, segura y mantenible. El repositorio contiene un MVP funcional por diseño; la primera responsabilidad es abrirlo en macOS, generar el proyecto con XcodeGen, corregir cualquier diferencia de SDK y dejar todos los tests verdes.

## Invariantes

1. El PIN nunca se guarda en `UserDefaults`, archivos o logs. Debe permanecer en Keychain.
2. No registrar PIN, estado biométrico detallado ni nombres de apps protegidas en telemetría.
3. No usar `forceTerminate()` por defecto. La privacidad no debe provocar pérdida de datos.
4. No describir el MVP como bloqueo infalible. Mantener visible la advertencia *best effort*.
5. No añadir Endpoint Security al target principal sin crear una fase/proyecto separado y documentar el entitlement requerido.
6. Toda mutación de estado observable y toda interacción AppKit deben ejecutarse en `MainActor`.
7. Mantener macOS 13 como mínimo salvo decisión explícita.
8. Mantener la interfaz principal en español y preparar las cadenas para futura localización.

## Primeras acciones

```bash
brew install xcodegen
xcodegen generate
xcodebuild \
  -project LockCode.xcodeproj \
  -scheme LockCode \
  -configuration Debug \
  -destination 'platform=macOS' \
  build test
```

Después:

- Resolver warnings de concurrencia sin desactivar comprobaciones globales.
- Probar Intel y Apple Silicon cuando haya runners disponibles.
- Verificar Keychain con app firmada y sin sandbox.
- Verificar `SMAppService.mainApp` en una copia instalada dentro de `/Applications`.
- Probar aplicaciones ya abiertas y aplicaciones recién lanzadas.

## Definición de terminado para el MVP

- Onboarding y cambio de PIN funcionan.
- Reiniciar la app conserva configuración y lista protegida.
- Un PIN incorrecto nunca abre/reactiva la app protegida.
- Touch ID solo se ofrece cuando está disponible y habilitado.
- La autenticación correcta reabre/reactiva la app una sola vez, sin bucle.
- “Bloquear ahora” invalida todos los periodos de gracia.
- Al dormir/cambiar sesión se invalidan los periodos de gracia.
- El login item refleja los estados `enabled`, `notRegistered` y `requiresApproval`.
- La configuración y la salida normal requieren autenticación.
- Los tests pasan y no hay crashes en las rutas de cancelación.

## Prioridad posterior al MVP

1. Robustecer el coordinador de eventos y añadir pruebas con dobles.
2. Añadir rate limiting persistente después de intentos fallidos.
3. Añadir recuperación segura del PIN usando autenticación del propietario del dispositivo.
4. Añadir localización inglés/español.
5. Investigar una edición Pro con Endpoint Security como System Extension separada.
