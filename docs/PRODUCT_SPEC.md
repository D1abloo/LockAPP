# Especificación funcional — LockCode MVP

## Problema

Un usuario comparte o deja temporalmente su Mac desbloqueado y quiere impedir el acceso casual a aplicaciones privadas, sin crear otra cuenta del sistema.

## Público

- Usuarios domésticos.
- Profesionales que comparten el equipo ocasionalmente.
- Padres que quieren evitar accesos casuales, sin sustituir controles parentales del sistema.

## Historias principales

1. Como usuario, configuro un código alfanumérico local para administrar LockCode.
2. Como usuario, veo las aplicaciones instaladas y activo la protección por aplicación.
3. Como usuario, cuando alguien abre una aplicación protegida, LockCode solicita el código.
4. Como usuario con Touch ID, la autenticación biométrica comienza automáticamente sin pulsar otro botón.
5. Como usuario, elijo si la autorización termina al cerrar la aplicación o después de un número de minutos.
6. Como usuario, invalido todas las autorizaciones con “Bloquear ahora”.
7. Como usuario, hago que LockCode se inicie con mi sesión.
8. Como propietario, debo autenticarme antes de cambiar la configuración o salir normalmente.
9. Como usuario, consulto ayuda, soporte y futuras actualizaciones desde la propia aplicación.

## Fuera de alcance del MVP

- Protección contra administradores o malware.
- Modo infantil resistente a manipulación.
- Sincronización de configuración.
- Recuperación remota del código.
- App Store y sandbox garantizados.
- Bloqueo previo a la ejecución mediante Endpoint Security.

## Métricas de calidad

- Sin bucles de apertura/cierre tras autenticar.
- Sin pérdida de datos por cierre forzado.
- Menos de un segundo entre evento observado y presentación del panel en un Mac moderno.
- Cero almacenamiento del código fuera de Keychain.
- Todas las rutas de cancelación dejan la app privada oculta o cerrada.
