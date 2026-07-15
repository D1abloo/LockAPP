# Validación Linux 0.4.3

- 15 de julio de 2026: 14 pruebas unitarias correctas (incluyen selector manual persistente, metadatos seguros de actualización, progreso de APT/DNF, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `installer/output/lockcode-linux_0.4.3_all.deb`.
- Instalador RPM: `RPM/output/lockcode-linux_0.4.3_noarch.rpm`.
- SHA-256 DEB: `c9eb5624c59ef9e96c49c591d4af542e4c34587bf454c33963696174d2a269c0`.
- SHA-256 RPM: `51c421c8deae31f919271489dafe4cd67103a7217b444f57d8d63a62eb944dde`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
