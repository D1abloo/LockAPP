# Validación Linux 0.1.5

- 15 de julio de 2026: 13 pruebas unitarias correctas (incluyen metadatos seguros de actualización, progreso de APT, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `build/lockcode-linux_0.1.5_all.deb`.
- Instalador RPM: `build/lockcode-linux_0.1.5_noarch.rpm`.
- SHA-256 DEB: `7ff75617cbb452c3f3536d0c661512f03f268dfd76a9b69c144fc3aa2d43f2f1`.
- SHA-256 RPM: `b7bf5dd2f30f39b13eda225fe73df90878a77f0a72f72ebd0641117650faea4b`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
