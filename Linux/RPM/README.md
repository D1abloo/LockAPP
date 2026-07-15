# LockCode RPM

Instalador independiente para Fedora 42 o posterior y CentOS Stream 9/10. CentOS requiere EPEL porque el indicador Ayatana se distribuye allí.

## Fedora

```bash
sudo dnf install rpm-build
./RPM/build-rpm.sh
sudo dnf install --nogpgcheck ./build/lockcode-linux_0.1.5_noarch.rpm
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
```

## CentOS Stream

```bash
sudo dnf config-manager --set-enabled crb
sudo dnf install epel-release rpm-build
./RPM/build-rpm.sh
sudo dnf install --nogpgcheck ./build/lockcode-linux_0.1.5_noarch.rpm
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
```

DNF instala las dependencias, activa el servicio de usuario e inicia LockCode. Las actualizaciones desde la aplicación descargan el asset `.rpm`, verifican SHA-256, solicitan permisos con PolicyKit y muestran progreso. Para desinstalar:

```bash
sudo dnf remove lockcode-linux
```

El RPM de prueba publicado no está firmado con GPG; por eso la instalación manual usa `--nogpgcheck`. LockCode sí exige que la descarga automática coincida con el SHA-256 publicado por GitHub. Para distribución estable debe firmarse el RPM con una clave de publicación.
