# Validación Linux 0.4.1

- 15 de julio de 2026: 14 pruebas unitarias correctas (incluyen selector manual persistente, metadatos seguros de actualización, progreso de APT/DNF, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `installer/output/lockcode-linux_0.4.1_all.deb`.
- Instalador RPM: `RPM/output/lockcode-linux_0.4.1_noarch.rpm`.
- SHA-256 DEB: `3b84bb46dbba48583588772634045b470969688130c933f8d7e911d5e6d83a51`.
- SHA-256 RPM: `b6bdd855584a4cc8a0aea20a14141832398445ba0016711a5d3587ad62fdd853`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
