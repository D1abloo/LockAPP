# Tarea para el agente Codex

Abre este repositorio en un Mac con Xcode 15 o posterior y completa el MVP de LockCode.

## Resultado esperado

Una aplicación macOS 13+ compilable y firmable que permita elegir aplicaciones instaladas y proteger su lanzamiento/activación con PIN o Touch ID.

## Trabajo requerido

1. Ejecuta `xcodegen generate` y compila el esquema `LockCode`.
2. Corrige diferencias de firma de APIs provocadas por la versión exacta del SDK, especialmente `SMAppService.unregister()` y los métodos async de LocalAuthentication.
3. Ejecuta los tests y añade pruebas para:
   - validación de PIN;
   - concesión y expiración del periodo de gracia;
   - deduplicación de solicitudes pendientes;
   - exclusión del bundle de LockCode y procesos críticos.
4. Prueba manualmente los escenarios de `docs/ACCEPTANCE_TESTS.md`.
5. Mantén el bloqueo como *best effort*. No uses `forceTerminate()` ni APIs privadas.
6. Documenta en el PR cualquier limitación que no pueda corregirse sin Endpoint Security.

## Entregables

- Proyecto Xcode generado y compilable.
- Tests verdes.
- Capturas del onboarding, listado, ajustes y panel de desbloqueo.
- Notas de prueba en Apple Silicon y, cuando sea posible, Intel.
- Lista concreta de tareas para la futura System Extension.
