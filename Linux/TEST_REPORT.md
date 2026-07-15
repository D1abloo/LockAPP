# Validación Linux 0.4.2

- 15 de julio de 2026: 14 pruebas unitarias correctas (incluyen selector manual persistente, metadatos seguros de actualización, progreso de APT/DNF, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `installer/output/lockcode-linux_0.4.2_all.deb`.
- Instalador RPM: `RPM/output/lockcode-linux_0.4.2_noarch.rpm`.
- SHA-256 DEB: `091666536759e8082c3a50001836722f454a647c1a04c5f4fd624f9dfbf5e19f`.
- SHA-256 RPM: `43a85d8f59f1681d7b16f947e0cc774b5a8022d2b02d0b6661a48f242d7c076d`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
