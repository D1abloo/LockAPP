# LockCode para Linux

Proyecto independiente para Debian 12, Ubuntu 22.04 o distribuciones compatibles. No usa archivos ni configuración de macOS o Windows.

## Funciones

- Código de 4–64 caracteres con símbolos, derivado mediante PBKDF2-HMAC-SHA256; solo la credencial derivada se guarda en Secret Service/libsecret.
- Huella automática mediante fprintd cuando existe un lector configurado.
- Catálogo basado en entradas `.desktop` y selector manual de cualquier ejecutable válido.
- Monitor `/proc`: pausa inmediatamente el proceso con `SIGSTOP`; al autorizar usa `SIGCONT`, y al cancelar solicita cierre normal con `SIGTERM`. Nunca usa `SIGKILL`.
- Periodo de gracia, bloqueo inmediato, penalización progresiva, registro anónimo y actualizaciones confirmadas.
- Inicio automático mediante un único servicio systemd de usuario ligado a la sesión gráfica; indicador de bandeja con el icono de LockCode.
- Interfaz GTK con botones de acción, iconos y estados visuales de foco, pulsación y selección.

## Crear e instalar el paquete Debian

```bash
sudo apt install python3 python3-gi gir1.2-gtk-3.0 libsecret-tools fprintd \
  gir1.2-ayatanaappindicator3-0.1 dpkg-dev
chmod +x installer/build-deb.sh
./installer/build-deb.sh
sudo apt install ./installer/output/lockcode-linux_0.4.5_all.deb
```

Para Fedora y CentOS Stream usa el instalador RPM independiente y sus instrucciones en [`RPM/README.md`](RPM/README.md). Los paquetes `.deb` y `.rpm` no se mezclan.

Pruebas sin instalar:

```bash
python3 -m unittest discover -s tests -v
python3 -m compileall -q lockcode
```

El instalador activa e inicia LockCode automáticamente para el usuario de la sesión gráfica. La primera instalación solicita un código nuevo. Cerrar la ventana solo la oculta: LockCode continúa en la bandeja y protegiendo aplicaciones. Para la huella, registra primero el dedo con `fprintd-enroll`. El apagado no requiere autenticación.

Si usas inicio de sesión automático, GNOME Keyring puede permanecer bloqueado. LockCode no consulta el llavero durante el arranque si la credencial ya está configurada; solo será necesario desbloquearlo cuando GNOME lo requiera para validar el código. La interfaz mantiene una espera limitada y no queda congelada.

## Actualizar desde LockCode

Abre **Actualizaciones > Buscar actualización**. Si aparece una versión nueva, pulsa **Sí**. LockCode descarga el `.deb` oficial, comprueba su SHA-256, solicita permisos administrativos mediante `pkexec` y muestra el progreso de descarga e instalación. Al finalizar reinicia el servicio automáticamente.

También puedes actualizar manualmente con:

```bash
sudo apt install ./installer/output/lockcode-linux_0.4.5_all.deb
```

Una actualización conserva el código, las aplicaciones protegidas y el registro. El instalador reinicia el servicio y el icono vuelve a la bandeja automáticamente.

## Desinstalación y limpieza completa

La desinstalación detiene LockCode, quita su inicio automático, elimina configuración, registro y caché, e intenta retirar la credencial del llavero si está desbloqueado. Una instalación posterior usa siempre una identidad nueva y solicita otro código.

```bash
sudo apt purge lockcode-linux
systemctl --user daemon-reload
```

Si necesitas limpiar restos de una instalación antigua manualmente:

```bash
systemctl --user disable --now lockcode.service 2>/dev/null || true
secret-tool clear application lockcode-linux type primary-code 2>/dev/null || true
rm -rf ~/.config/lockcode ~/.local/state/lockcode ~/.cache/lockcode
rm -f ~/.config/autostart/lockcode.desktop
```

Rutas que pertenecen al paquete y que `apt purge` elimina: `/usr/lib/lockcode`, `/usr/bin/lockcode`, `/usr/lib/systemd/user/lockcode.service`, `/usr/share/applications/com.lockcode.Linux.desktop` y `/usr/share/icons/hicolor/scalable/apps/com.lockcode.Linux.svg`.

## Limitaciones

Es una protección *best effort*. Linux no ofrece una API universal para impedir la ejecución de otra aplicación en X11 y Wayland. Un módulo LSM o una política del sistema sería necesario para control previo a ejecución y requeriría administración específica de cada distribución.

Soporte: `isaaccoria46@gmail.com`.

Copyright © 2026 Isaac Silva Jiménez.
