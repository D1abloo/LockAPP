# LockCode para macOS

LockCode es un MVP nativo para macOS que protege la apertura o activación de aplicaciones seleccionadas mediante un código alfanumérico y, opcionalmente, Touch ID.

| Edición | Versión publicada |
| --- | --- |
| macOS | **0.4.6** |
| Windows | **0.4.6** |
| Debian/Ubuntu | **0.4.6** |
| Fedora/CentOS RPM | **0.4.6** |

LockCode es gratuito, no requiere donación y se distribuye conforme a la [Política de uso](USAGE_POLICY.md).

> **Modelo de seguridad:** esta versión es una protección de privacidad de tipo *best effort*. Usa eventos de `NSWorkspace` para ocultar/cerrar una app protegida después de que macOS la haya iniciado o activado. Un usuario con conocimientos técnicos puede cerrar LockCode, desactivar su elemento de inicio o matar el proceso. Un bloqueo preventivo y resistente requiere una System Extension basada en Endpoint Security y el entitlement aprobado por Apple.

## Funciones incluidas

- Onboarding con código de 4 a 64 caracteres; admite letras, números, espacios y símbolos imprimibles.
- Credencial del código derivada con PBKDF2-HMAC-SHA256, sal aleatoria y 210.000 rondas, almacenada en Keychain. El código no se conserva.
- Desbloqueo opcional con Touch ID, iniciado automáticamente cuando está habilitado y disponible.
- Catálogo de aplicaciones instaladas y selector manual de paquetes `.app` situados fuera de las carpetas habituales.
- Selección individual de aplicaciones protegidas.
- Detección de lanzamiento y activación mediante `NSWorkspace`.
- Restauración del bloqueo al reiniciar LockCode: las aplicaciones protegidas que ya estén abiertas se ocultan en cuanto vuelve a arrancar el monitor.
- Cierre normal de aplicaciones protegidas restauradas al iniciar sesión y supervisor continuo de todas las aplicaciones protegidas en ejecución como respaldo ante eventos perdidos de `NSWorkspace`.
- Ocultado repetido mientras exista una autenticación pendiente, para que una segunda activación no deje visible la aplicación.
- Pantalla opaca de privacidad en todos los monitores mientras se solicita el código o Touch ID, evitando que una aplicación que rechace `hide()` exponga su contenido detrás del panel.
- En modo inmediato, revocación al cerrar la última ventana visible aunque macOS mantenga el proceso activo; al volver a abrirla solicita código o Touch ID. Los intervalos por minutos permanecen válidos hasta expirar.
- Bloqueo inmediato de todas las sesiones concedidas.
- Inicio automático con macOS mediante `SMAppService`, solicitado por defecto en la primera ejecución.
- Renovación automática del registro de inicio tras instalar una nueva compilación y salida sin autenticación durante apagado, reinicio o cierre de sesión.
- Aplicación de barra de menús y ventana de gestión.
- Acceso a la configuración protegido por el código.
- Salida normal de LockCode protegida por autenticación.
- Esperas progresivas tras varios códigos incorrectos.
- Registro local de desbloqueos e intentos fallidos, sin nombres de aplicaciones ni datos de autenticación, con borrado manual y límite de 200 eventos.
- Comprobación automática de GitHub Releases, notificación con «Sí, actualizar» y descarga e instalación verificadas tras confirmar.
- Ayuda y soporte accesibles al final del sidebar, correo de contacto y donación voluntaria sin mostrar la cuenta asociada a PayPal.

## Requisitos

- macOS 13 o posterior.
- Xcode 15 o posterior (Xcode completo, no solo Command Line Tools).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.45 o posterior para generar el proyecto desde `project.yml`.

## Generar y ejecutar

```bash
brew install xcodegen
cd /ruta/a/LockCode
xcodegen generate
open LockCode.xcodeproj
```

En Xcode, selecciona el esquema **LockCode**, configura un equipo de firma y ejecuta con **Run**. Para generar y abrir una compilación Debug desde terminal:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
make run
```

## Compilar y probar

Los comandos mínimos, equivalentes a los pedidos para el MVP, son:

```bash
xcodegen generate

xcodebuild \
  -project LockCode.xcodeproj \
  -scheme LockCode \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

xcodebuild \
  -project LockCode.xcodeproj \
  -scheme LockCode \
  -destination 'platform=macOS' \
  test
```

`make build` y `make test` guardan los productos en `.build/DerivedData`. Las comprobaciones de concurrencia completas están activadas mediante `SWIFT_STRICT_CONCURRENCY=complete`; el código también se valida en modo Swift 6, aunque el proyecto conserva Swift 5.9 para seguir siendo compatible con Xcode 15.

## Instalación y prueba funcional

1. Genera `macOS/Installer/output/LockCode-macOS-0.4.6.zip` con `./macOS/Installer/build.sh`, descomprímelo, copia `LockCode.app` a `/Applications` y ejecútala desde allí.
2. Conserva el Hardened Runtime y firma la app; Keychain y `SMAppService.mainApp` deben validarse con una copia firmada.
3. LockCode solicita registrar el inicio automático en la primera ejecución. Si macOS muestra que requiere aprobación, abre **Ajustes de LockCode > Inicio de sesión > Abrir Ítems de inicio** y permite LockCode en **Ajustes del Sistema > General > Ítems de inicio**.
4. Reinicia la sesión o el Mac. LockCode debe aparecer en la barra de menús sin que tengas que abrirlo manualmente. El ajuste queda guardado y puede desactivarse desde LockCode.
5. Ejecuta los escenarios de [pruebas de aceptación](docs/ACCEPTANCE_TESTS.md), especialmente con una aplicación ya abierta y otra recién lanzada.

`SMAppService` necesita que la aplicación permanezca en `/Applications`. Una compilación de distribución debe estar firmada con Developer ID y notarizada; una firma ad hoc sirve para pruebas locales, pero macOS puede rechazar o pedir aprobación adicional para el inicio automático.

La identidad de firma debe permanecer estable entre versiones. Si cada actualización se firma de forma ad hoc, Keychain la identifica mediante un hash diferente y puede volver a mostrar el cuadro de acceso aunque anteriormente se eligiera «Permitir siempre». En este Mac se ha creado la identidad local `LockCode Local Signing`; para distribuir la aplicación debe sustituirse por un certificado Developer ID Application de Apple.

## Distribución fuera de Mac App Store

1. Configura `DEVELOPMENT_TEAM` y una identidad Developer ID estable en Xcode o en tu configuración local.
2. Genera el proyecto y el archivo Release:

   ```bash
   make archive
   open .build/LockCode.xcarchive
   ```

3. En Organizer selecciona **Distribute App > Developer ID**, firma con tu certificado de distribución y envía la app a notarización.
4. Exporta y prueba la app notarizada desde `/Applications` en una cuenta limpia antes de distribuirla.

No se incluye el entitlement de Endpoint Security ni una System Extension en este target.

No cambies la identidad de firma entre actualizaciones: la autorización del elemento de Keychain está ligada al requisito designado de la aplicación firmada.

## Flujo del MVP

1. El usuario configura un código alfanumérico.
2. Selecciona aplicaciones en la pantalla **Aplicaciones**.
3. LockCode observa lanzamientos y activaciones.
4. Cuando detecta una ventana protegida, la oculta y mantiene una pantalla de privacidad mientras autentica. Cancelar solicita el cierre normal; autorizar reactiva la misma aplicación.
5. Muestra un panel de autenticación por encima de los escritorios.
6. Tras autenticarse, reactiva la aplicación. En modo inmediato revoca el acceso al desaparecer su última ventana visible; con minutos configurados lo conserva hasta que expire el intervalo.
7. LockCode añade al registro la hora del desbloqueo o del intento fallido, sin identificar la aplicación.

## Estructura

- `LockCode/App`: composición y estado principal.
- `LockCode/Models`: modelos de dominio.
- `LockCode/Services`: Keychain, autenticación, catálogo, protección e inicio de sesión.
- `LockCode/Views`: interfaz SwiftUI y panel de desbloqueo.
- `LockCodeTests`: pruebas unitarias de reglas puras.
- `macOS/Installer`: proceso y salida del instalador ZIP de macOS.
- `docs`: especificación funcional, aceptación, seguridad e informes de prueba.
- `USAGE_POLICY.md`: condiciones de uso, privacidad, distribución y soporte.

## Limitaciones conocidas

- Existe una pequeña ventana entre el lanzamiento de una app y la recepción del evento de `NSWorkspace`.
- En un reinicio, macOS decide el orden de restauración de aplicaciones e ítems de inicio. LockCode puede actuar en cuanto su proceso arranca, pero no antes; una garantía previa a cualquier ventana requiere Endpoint Security.
- Algunas aplicaciones auxiliares o de fondo no generan la notificación de lanzamiento estándar.
- El modo inmediato usa el estado público de las ventanas de macOS. Minimizar, ocultar o mover la última ventana fuera del espacio visible puede revocar el acceso antes de terminar el proceso.
- El cierre normal de una app puede ser rechazado por ella misma.
- No evita `kill`, Safe Mode, cambios administrativos ni la desactivación manual del login item.
- Para evitar pérdida de datos, una aplicación que ya estaba abierta se oculta, pero no se fuerza su cierre al activarla.
- Si una aplicación tarda en aceptar el ocultado o cierre normal, la pantalla de privacidad permanece por encima hasta autenticar o hasta que el proceso quede oculto/cerrado.
- Al reiniciarse, LockCode oculta las aplicaciones protegidas ya abiertas, pero `NSWorkspace` no puede impedir que el proceso llegue a iniciarse. Un bloqueo previo a la ejecución no es posible en este MVP.
- Las penalizaciones del código viven en memoria y se reinician si se mata o reinicia LockCode; hacerlas persistentes requiere proteger también ese estado contra manipulación.
- El registro de acceso se guarda localmente en las preferencias de la aplicación. Es informativo, no está firmado y un usuario con acceso a la cuenta puede modificarlo o eliminarlo.
- Las aplicaciones eliminadas desaparecen del catálogo, pero su identificador puede permanecer en la configuración sin provocar bloqueos ni fallos. Si reaparecen con el mismo bundle identifier, recuperan la selección.

Consulta `docs/SECURITY_MODEL.md` antes de prometer un nivel de protección comercial.

## Ediciones independientes

- [`Windows/`](Windows/README.md): aplicación WPF, pruebas, publicación autocontenida e instalador en `Windows/Installer/output`.
- [`Linux/`](Linux/README.md): aplicación GTK, pruebas y paquetes en `Linux/installer/output` y `Linux/RPM/output`.

Cada edición mantiene su configuración, almacén seguro, inicio automático y sistema biométrico. No se mezclan binarios ni instaladores con la edición macOS.

Las ediciones pueden avanzar con números distintos. Cada actualizador ignora una publicación que no contenga el instalador oficial de su plataforma, de modo que una corrección exclusiva de macOS no se ofrece en Windows o Linux.

## Política de uso y privacidad

- El uso de los binarios oficiales es gratuito para fines personales o profesionales legítimos; donar es opcional y no cambia funciones ni soporte.
- No hay telemetría. La configuración y el registro permanecen en el equipo; comprobar actualizaciones contacta con GitHub.
- La protección es *best effort* y no sustituye el bloqueo de sesión, cifrado, copias de seguridad ni controles de seguridad del sistema.
- No envíes códigos, contraseñas o información privada al solicitar soporte.
- Consulta las condiciones completas en [USAGE_POLICY.md](USAGE_POLICY.md).

## Ayuda, actualizaciones y donaciones

- La aplicación incluye una guía de uso y soporte redactada en español.
- Las actualizaciones se consultan automáticamente desde `https://github.com/D1abloo/LockAPP/releases`. Solo se aceptan descargas HTTPS del repositorio oficial con SHA-256 publicado; nunca se instalan sin confirmación.
- El soporte está disponible en `isaaccoria46@gmail.com`. El botón de donación no utiliza ni muestra ese correo.
- LockCode es gratuito y no requiere donación. Quien quiera apoyar voluntariamente el proyecto puede usar el enlace de PayPal incluido en la sección Ayuda y soporte.
- Copyright © 2026 Isaac Silva Jiménez.
