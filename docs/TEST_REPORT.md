# Informe de validación — 15 de julio de 2026

## Entorno disponible

- macOS con Command Line Tools y SDK macOS 26.5.
- Apple Swift 6.3.3.
- XcodeGen 2.45.3.
- No hay una instalación completa de Xcode; `xcode-select` apunta a `/Library/Developer/CommandLineTools`.

## Comprobaciones completadas

- `xcodegen generate`: correcto; genera `LockCode.xcodeproj` y el esquema compartido `LockCode` con `LockCodeTests`.
- Fuentes 0.4.3 comprobadas con Swift 6.3.3, concurrencia completa y warnings como errores: type-check correcto; la suite XCTest no puede ejecutarse sin Xcode completo.
- Selector manual `.app`: valida paquete, bundle identifier y exclusión de LockCode; persiste la ruta y activa la protección. Sus pruebas XCTest se compilan dentro del proyecto generado.
- Bundle universal 0.4.3 para Intel y Apple Silicon enlazado, firmado con `LockCode Local Signing`, verificado con `codesign` y empaquetado en `macOS/Installer/output/LockCode-macOS-0.4.3.zip` (SHA-256 `2843907eded28ab94839daf77a23b599c57ab24fb4a8e1cef092e5042f511a10`).
- El elemento de Keychain usa el nombre visible `LockCode`. La credencial derivada histórica solo se migra si Keychain permite leerla sin interfaz; si no, se solicita crear otro código dentro de LockCode y nunca se muestra el diálogo técnico anterior.
- Actualizador macOS: asset HTTPS oficial, digest SHA-256, firma de código, sustitución segura, relanzamiento y confirmación posterior implementados; queda pendiente recorrer el reemplazo real con una versión futura instalada en `/Applications`.
- Type-check de todas las fuentes con Swift 6, concurrencia estricta y warnings como errores: correcto para `x86_64` y `arm64`, con deployment target macOS 13.
- Enlace directo con `swiftc` del ejecutable completo: correcto en `x86_64` y `arm64`.
- Verificador ejecutable de reglas de dominio: 28 comprobaciones correctas para código con símbolos, credencial PBKDF2 sin texto plano, penalizaciones, bloqueo al terminar, expiración por minutos, solicitud pendiente, deduplicación, inicio automático, registro persistente/borrable y validación de URL de actualización.
- El actualizador solo anuncia una publicación que contenga un paquete macOS y muestra versión instalada y disponible.
- Bundle 0.3.2 (compilación 6) universal, firmado localmente, instalado y ejecutándose desde `/Applications/LockCode.app`; incorpora ocultado/cierre normal de aplicaciones restauradas y supervisión continua de todas las aplicaciones protegidas.
- La versión 0.3.2 se enlazó con Swift 6.3.3, concurrencia estricta y advertencias tratadas como errores para `x86_64-apple-macosx13.0` y `arm64-apple-macosx13.0`.
- Se sustituyó la firma ad hoc por la identidad estable `LockCode Local Signing`; mantener esa identidad evita repetir la autorización «Permitir siempre» de Keychain.
- `SMAppService.mainApp` registró LockCode como ítem de inicio; System Events confirma `name: LockCode` y `path: /Applications/LockCode.app`.
- El registro se renovó tras actualizar la compilación (`Generation: 8`, estado habilitado). Una apertura real de la aplicación protegida configurada confirmó que el supervisor la ocultó y solicitó su terminación normal.
- El delegado permite terminar inmediatamente durante apagado, reinicio o cierre de sesión, pero conserva la autenticación para una salida manual.
- Prueba gráfica del reinicio con WhatsApp protegida: antes de arrancar LockCode estaba en ejecución y visible; al iniciar LockCode permaneció en ejecución pero `NSRunningApplication.isHidden` pasó a `true`.
- Prueba gráfica de solicitud pendiente: dos intentos consecutivos de activar WhatsApp mantuvieron `isHidden == true` y no dejaron visible la aplicación mientras esperaba autenticación.
- Diagnóstico de reinicio 0.3.1: se detectó y eliminó una espera de inicialización que consultaba Keychain y servicios auxiliares antes de iniciar el monitor. La protección ahora arranca primero; Keychain, `SMAppService` y las notificaciones se inicializan después.
- Durante la carga inicial se impide también la salida normal de LockCode, evitando eludir la autenticación mientras Keychain todavía no ha respondido.
- Prueba con WhatsApp restaurada y Touch ID desactivado temporalmente: sin LockCode estaba en ejecución, visible y activa; un segundo después de iniciar la versión corregida ya no estaba en ejecución.
- Prueba de apertura sin autorización: a los 0,5 segundos WhatsApp seguía inicializando, pero `isHidden == true`; a los 5 segundos había terminado normalmente.
- Validación de pantalla opaca: durante la autenticación se observó una ventana LockCode de nivel 7 y 2048×1280 cubriendo el monitor, con el panel de autenticación en nivel 8 por encima.
- Revisión estática de los escenarios de `ACCEPTANCE_TESTS.md`: todas las rutas están implementadas; las comprobaciones manuales realizadas se enumeran arriba.
- Revisión de seguridad 0.3.1: no hay logs del código ni nombres de aplicaciones en el registro; el código sigue derivado con PBKDF2 y almacenado en Keychain; el historial está limitado a 200 eventos y las URL de release se restringen a HTTPS del repositorio oficial.

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
