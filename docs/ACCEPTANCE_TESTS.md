# Pruebas de aceptación manual

## Instalación y onboarding

1. Ejecutar sin entrada previa de Keychain.
2. Verificar que acepta entre 4 y 64 caracteres, incluidos espacios y símbolos, y rechaza saltos de línea o caracteres de control.
3. Verificar que la confirmación debe coincidir.
4. Cerrar y abrir; comprobar que vuelve a pedir autenticación de gestión.
5. Actualizar desde una versión anterior y comprobar que Keychain muestra `LockCode` y nunca presenta el nombre técnico provisional; si la migración silenciosa no está autorizada, crear un código nuevo dentro de LockCode.

## Protección

1. Proteger TextEdit y cerrarlo.
2. Abrir TextEdit; debe ocultarse/cerrarse y aparecer el panel.
3. Introducir un código incorrecto; TextEdit no debe abrirse.
4. Introducir el código correcto; TextEdit debe abrirse una vez.
5. Mantener TextEdit abierto, cambiar a Finder y volver; debe respetar el periodo de gracia.
6. Pulsar “Bloquear ahora”, cambiar a Finder y volver; debe pedir autenticación.
7. Cancelar; TextEdit debe permanecer oculto o cerrado.
8. Seleccionar «Al cerrar la aplicación», cerrar TextEdit y volver a abrirlo; debe pedir autenticación.
9. Seleccionar minutos personalizados y comprobar que la autorización expira en el tiempo indicado.
10. Con el panel de autenticación abierto, intentar activar otra vez TextEdit; debe volver a ocultarse y no debe aparecer un segundo panel.
11. Dejar una aplicación protegida abierta, reiniciar LockCode y verificar que se oculta inmediatamente. Al volver a activarla debe pedir código o Touch ID.
12. Dejar una aplicación abierta, marcarla como protegida y comprobar que se oculta sin esperar a otro reinicio.
13. Reiniciar la sesión con una aplicación protegida configurada para restaurarse; al arrancar LockCode debe ocultarla y solicitar su cierre normal.
14. Con LockCode activo, activar repetidamente una aplicación protegida y comprobar que el supervisor la mantiene oculta incluso si no llega un nuevo evento de `NSWorkspace`. Repetir con otra aplicación visible pero no situada en primer plano.
15. Usar una aplicación que rechace temporalmente `hide()` y verificar que una pantalla opaca cubre todos los monitores detrás del panel de autenticación, sin mostrar información de la aplicación.
16. Cancelar la autenticación; la pantalla opaca debe permanecer hasta que la aplicación protegida quede oculta o termine normalmente.
17. Pulsar «Añadir aplicación…», elegir un paquete `.app` fuera de las carpetas catalogadas y comprobar que aparece protegido.
18. Reiniciar LockCode y comprobar que la aplicación añadida manualmente conserva su estado; moverla o eliminarla no debe provocar fallos.

## Touch ID

1. En un Mac compatible, activar Touch ID.
2. Verificar que el diálogo biométrico aparece automáticamente sin pulsar el botón Touch ID.
3. Cancelar el diálogo del sistema y usar el código.
4. Desactivar Touch ID en macOS; LockCode debe degradar al código sin bloquear la UI.

## Ayuda y actualizaciones

1. Verificar que Ayuda y soporte aparece al final del sidebar izquierdo junto a Acerca de.
2. Abrir Ayuda y soporte y verificar instalación, uso, registro, actualizaciones, autoría, gratuidad y correo de contacto.
3. Comprobar que el botón de PayPal funciona sin mostrar en pantalla la cuenta de donación.
4. Abrir Actualizaciones y comprobar la respuesta cuando no existen releases.
5. Publicar una release de prueba y verificar que se muestra su versión, notas y enlace.
6. Reiniciar LockCode con una release posterior publicada y comprobar la notificación con «Sí, actualizar» y «No ahora».
7. Elegir «Sí, actualizar» y comprobar descarga, SHA-256, sustitución de la app, reinicio y mensaje de actualización completada.

## Registro

1. Fallar un código válido y comprobar que aparece un intento fallido con fecha y hora.
2. Desbloquear una aplicación y comprobar que aparece el desbloqueo con fecha y hora.
3. Verificar que el registro no muestra código, método biométrico ni nombre de aplicación.
4. Reiniciar LockCode y comprobar que el historial se conserva.
5. Borrar el registro y confirmar que queda vacío después de reiniciar.

## Gestión y salida

1. Cerrar y volver a abrir la ventana de LockCode; la gestión debe estar bloqueada.
2. Verificar que no se puede modificar la lista sin autenticación.
3. Pulsar Cmd-Q; debe solicitar autenticación.
4. Cancelar; LockCode debe seguir ejecutándose.

## Inicio de sesión

1. Instalar LockCode en `/Applications` y abrirlo por primera vez; “Iniciar LockCode con macOS” debe aparecer activado por defecto.
2. Revisar Ajustes del Sistema > General > Ítems de inicio. Si macOS indica `requiresApproval`, aprobar LockCode.
3. Cerrar sesión y volver a entrar.
4. Verificar que el icono aparece en la barra de menús sin abrir LockCode manualmente.
5. Dejar una aplicación protegida abierta antes de reiniciar LockCode y comprobar que el monitor restaura el bloqueo.
6. Reiniciar el Mac y verificar que LockCode aparece en la barra de menús y bloquea una aplicación protegida sin abrirlo manualmente.
7. Apagar o reiniciar el Mac y comprobar que LockCode no solicita su código ni Touch ID para permitir la operación.
