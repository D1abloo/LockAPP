# Pruebas de aceptación manual

## Instalación y onboarding

1. Ejecutar sin entrada previa de Keychain.
2. Verificar que acepta entre 4 y 16 letras o números y rechaza símbolos.
3. Verificar que la confirmación debe coincidir.
4. Cerrar y abrir; comprobar que vuelve a pedir autenticación de gestión.

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

## Touch ID

1. En un Mac compatible, activar Touch ID.
2. Verificar que el diálogo biométrico aparece automáticamente sin pulsar el botón Touch ID.
3. Cancelar el diálogo del sistema y usar el código.
4. Desactivar Touch ID en macOS; LockCode debe degradar al código sin bloquear la UI.

## Ayuda y actualizaciones

1. Abrir Ayuda y soporte y verificar los textos de uso, privacidad, autoría y gratuidad.
2. Abrir el enlace de PayPal y comprobar que apunta a la cuenta indicada.
3. Abrir Actualizaciones y comprobar la respuesta cuando no existen releases.
4. Publicar una release de prueba y verificar que se muestra su versión, notas y enlace.

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
