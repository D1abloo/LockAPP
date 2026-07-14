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
- Verificador ejecutable de reglas de dominio: 28 comprobaciones correctas para código con símbolos, credencial PBKDF2 sin texto plano, penalizaciones, bloqueo al terminar, expiración por minutos, solicitud pendiente, deduplicación, inicio automático, registro persistente/borrable y validación de URL de actualización.
- GitHub Releases devuelve el 404 esperado mientras no existan releases; la interfaz muestra ese estado y no genera una notificación falsa.
- Bundle 0.3.0 (compilación 4) universal, con firma ad hoc y Hardened Runtime, desinstalado/reinstalado y ejecutándose desde `/Applications/LockCode.app`.
- `SMAppService.mainApp` registró LockCode como ítem de inicio; System Events confirma `name: LockCode` y `path: /Applications/LockCode.app`.
- Prueba gráfica del reinicio con WhatsApp protegida: antes de arrancar LockCode estaba en ejecución y visible; al iniciar LockCode permaneció en ejecución pero `NSRunningApplication.isHidden` pasó a `true`.
- Prueba gráfica de solicitud pendiente: dos intentos consecutivos de activar WhatsApp mantuvieron `isHidden == true` y no dejaron visible la aplicación mientras esperaba autenticación.
- Revisión estática de los escenarios de `ACCEPTANCE_TESTS.md`: todas las rutas están implementadas; solo se marcan arriba como manualmente verificadas las dos pruebas gráficas realizadas en esta sesión.
- Revisión de seguridad 0.3.0: no hay logs del código ni nombres de aplicaciones en el registro; el código sigue derivado con PBKDF2 y almacenado en Keychain; el historial está limitado a 200 eventos y las URL de release se restringen a HTTPS del repositorio oficial.

## Comprobaciones bloqueadas por el entorno

Los comandos `xcodebuild build` y `xcodebuild test` no pueden ejecutarse con solo Command Line Tools: `xcodebuild` requiere que el developer directory activo sea una instalación completa de Xcode. Por la misma razón no está disponible el módulo XCTest de macOS para ejecutar la suite fuera de Xcode.

Quedan pendientes en un Mac con Xcode completo y sesión gráfica:

- ejecutar toda la suite `LockCodeTests` con `xcodebuild test`;
- recorrer manualmente todos los flujos de onboarding, gestión, cancelaciones y salida;
- verificar Keychain con la app firmada y sin sandbox;
- verificar Touch ID en hardware compatible, incluido fallback al código;
- validar los estados de `SMAppService.mainApp` con una firma Apple válida;
- completar el recorrido de una aplicación recién lanzada con código correcto y Touch ID real;
- publicar una release posterior y verificar visualmente las acciones «Sí, actualizar» y «No ahora» de la notificación;
- capturar onboarding, listado, ajustes y panel de desbloqueo;
- ejecutar binarios en hardware Apple Silicon e Intel (ambas arquitecturas se type-comprobaron y enlazaron aquí, pero no se ejecutaron en ambos tipos de hardware).

## Criterio de seguridad

La revisión conserva el modelo *best effort*: no usa `forceTerminate()`, APIs privadas ni Endpoint Security en el target principal. La futura edición reforzada requiere una System Extension separada, entitlement aprobado por Apple, consentimiento del usuario, canal XPC autenticado y una política de recuperación.
