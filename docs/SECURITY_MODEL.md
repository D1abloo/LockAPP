# Modelo de seguridad

## Activos

- Confidencialidad casual del contenido de aplicaciones seleccionadas.
- Código alfanumérico de administración.
- Configuración de aplicaciones protegidas.

## Adversario cubierto

Una persona con acceso físico temporal a una sesión de macOS ya iniciada, sin privilegios administrativos y sin intención/capacidad de manipular procesos desde Terminal.

## Adversario no cubierto

- Administradores del Mac.
- Usuarios capaces de usar `kill`, Activity Monitor, Safe Mode o modificar login items.
- Malware que se ejecute bajo la misma cuenta.
- Ataques fuera de la sesión de usuario.

## Controles

- El código se transforma mediante PBKDF2-HMAC-SHA256 con una sal aleatoria y 210.000 rondas. Solo la sal, los parámetros y la clave derivada se guardan como contraseña genérica de Keychain; la comparación es en tiempo constante.
- El acceso al elemento de Keychain depende del requisito designado de la firma. Las actualizaciones deben usar siempre la misma identidad estable; una firma ad hoc distinta puede provocar otra solicitud de acceso de macOS.
- Touch ID usa LocalAuthentication; LockCode no recibe datos biométricos.
- La configuración se oculta hasta autenticar al propietario.
- Los intentos fallidos activan esperas progresivas en memoria.
- Las concesiones de acceso viven solo en memoria.
- Las concesiones se borran al solicitarlo y ante eventos de suspensión/cambio de sesión observables.
- Al arrancar el monitor se ocultan las aplicaciones protegidas que ya estén ejecutándose; una aplicación se vuelve a ocultar ante activaciones repetidas mientras su autenticación está pendiente.
- Un supervisor comprueba cada 50 ms todas las aplicaciones protegidas en ejecución y vuelve a ocultar cualquiera que no tenga una concesión válida. En el arranque se solicita además el cierre normal de las aplicaciones protegidas restauradas.
- Durante la autenticación se colocan ventanas opacas por encima de las aplicaciones en todos los monitores. Al cancelar, permanecen hasta confirmar que el proceso protegido está oculto o terminado.
- Las respuestas tardías de una autenticación cancelada se descartan mediante un identificador único de presentación.
- El registro local conserva únicamente tipo de evento, fecha y un UUID aleatorio; no contiene el código, el resultado detallado de Touch ID, bundle identifiers ni nombres de aplicaciones.
- Las actualizaciones solo aceptan assets HTTPS del repositorio oficial, exigen el SHA-256 publicado por GitHub y validan la firma del paquete macOS antes de sustituir la aplicación.
- El MVP no fuerza la terminación de apps ya abiertas para evitar pérdida de datos.

## Riesgos aceptados

1. `NSWorkspace` notifica después del lanzamiento, por lo que puede existir un breve destello de contenido.
2. Las apps de fondo o con determinados atributos pueden no generar la notificación estándar.
3. Una app puede rechazar una solicitud de terminación normal.
4. LockCode puede ser terminado externamente.
5. `SMAppService` requiere aprobación del usuario en determinados estados.
6. El registro local es informativo y borrable; no es un registro forense resistente a manipulación.

## Camino a una edición reforzada

Crear una System Extension separada basada en Endpoint Security que evalúe eventos de autorización de ejecución. Esto requiere:

- entitlement `com.apple.developer.endpoint-security.client` aprobado por Apple;
- consentimiento explícito del usuario;
- firma, notarización y actualización de la extensión;
- canal XPC autenticado entre la app y la extensión;
- política de recuperación para evitar bloquear componentes esenciales.
