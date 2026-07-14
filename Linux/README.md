# LockCode para Linux

Proyecto independiente para Debian 12, Ubuntu 22.04 o distribuciones compatibles. No usa archivos ni configuración de macOS o Windows.

## Funciones

- Código de 4–64 caracteres con símbolos, derivado mediante PBKDF2-HMAC-SHA256; solo la credencial derivada se guarda en Secret Service/libsecret.
- Huella automática mediante fprintd cuando existe un lector configurado.
- Catálogo basado en entradas `.desktop`.
- Monitor `/proc`: pausa inmediatamente el proceso con `SIGSTOP`; al autorizar usa `SIGCONT`, y al cancelar solicita cierre normal con `SIGTERM`. Nunca usa `SIGKILL`.
- Periodo de gracia, bloqueo inmediato, penalización progresiva, registro anónimo y actualizaciones confirmadas.
- Inicio de sesión mediante systemd de usuario y autostart XDG; indicador de bandeja cuando Ayatana AppIndicator está disponible.

## Crear e instalar el paquete Debian

```bash
sudo apt install python3 python3-gi gir1.2-gtk-3.0 libsecret-tools fprintd \
  gir1.2-ayatanaappindicator3-0.1 dpkg-dev
chmod +x installer/build-deb.sh
./installer/build-deb.sh
sudo apt install ./build/lockcode-linux_0.1.0_all.deb
```

Pruebas sin instalar:

```bash
python3 -m unittest discover -s tests -v
python3 -m compileall -q lockcode
```

Tras instalar, ejecuta `lockcode`. Para la huella, registra primero el dedo con `fprintd-enroll`. La aplicación se mantiene en segundo plano; el apagado no requiere autenticación.

## Limitaciones

Es una protección *best effort*. Linux no ofrece una API universal para impedir la ejecución de otra aplicación en X11 y Wayland. Un módulo LSM o una política del sistema sería necesario para control previo a ejecución y requeriría administración específica de cada distribución.
