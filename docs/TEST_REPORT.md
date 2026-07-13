# Informe de validación — 14 de julio de 2026

## Entorno disponible

- macOS con Command Line Tools y SDK macOS 26.5.
- Apple Swift 6.3.3.
- XcodeGen 2.45.3.
- No hay una instalación completa de Xcode; `xcode-select` apunta a `/Library/Developer/CommandLineTools`.

## Comprobaciones completadas

- `xcodegen generate`: correcto; genera `LockCode.xcodeproj` y el esquema compartido `LockCode` con `LockCodeTests`.
- Type-check de todas las fuentes con Swift 6, concurrencia estricta y warnings como errores: correcto para `x86_64` y `arm64`, con deployment target macOS 13.
- Enlace directo con `swiftc` del ejecutable completo: correcto en `x86_64` y `arm64`.
- Verificador ejecutable de reglas de dominio: 17 comprobaciones correctas para código alfanumérico, credencial PBKDF2 sin texto plano, penalizaciones, bloqueo al terminar, expiración por minutos, deduplicación, versiones y persistencia.
- PayPal Donation devuelve HTTP 200 para la cuenta configurada y GitHub Releases devuelve el 404 esperado mientras no existan releases.
- Bundle 0.2.0 universal, con firma ad hoc y Hardened Runtime, instalado y ejecutándose desde `/Applications/LockCode.app`.
- Revisión estática de los escenarios de `ACCEPTANCE_TESTS.md`: todas las rutas están implementadas; no se han marcado como pruebas manuales superadas.

## Comprobaciones bloqueadas por el entorno

Los comandos `xcodebuild build` y `xcodebuild test` no pueden ejecutarse con solo Command Line Tools: `xcodebuild` requiere que el developer directory activo sea una instalación completa de Xcode. Por la misma razón no está disponible el módulo XCTest de macOS para ejecutar la suite fuera de Xcode.

Quedan pendientes en un Mac con Xcode completo y sesión gráfica:

- ejecutar toda la suite `LockCodeTests` con `xcodebuild test`;
- recorrer manualmente todos los flujos de onboarding, gestión, cancelaciones y salida;
- verificar Keychain con la app firmada y sin sandbox;
- verificar Touch ID en hardware compatible, incluido fallback al código;
- validar los estados de `SMAppService.mainApp` con una firma Apple válida;
- probar aplicaciones ya abiertas y recién lanzadas;
- capturar onboarding, listado, ajustes y panel de desbloqueo;
- ejecutar binarios en hardware Apple Silicon e Intel (ambas arquitecturas se type-comprobaron y enlazaron aquí, pero no se ejecutaron en ambos tipos de hardware).

## Criterio de seguridad

La revisión conserva el modelo *best effort*: no usa `forceTerminate()`, APIs privadas ni Endpoint Security en el target principal. La futura edición reforzada requiere una System Extension separada, entitlement aprobado por Apple, consentimiento del usuario, canal XPC autenticado y una política de recuperación.
