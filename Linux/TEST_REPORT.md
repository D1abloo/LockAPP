# Validación Linux 0.4.5

Estado publicado vigente para Debian/Ubuntu y RPM. La posterior versión macOS 0.4.6 no modifica Linux. Condiciones generales: [`USAGE_POLICY.md`](../USAGE_POLICY.md).

- 15 de julio de 2026: 14 pruebas unitarias correctas (incluyen selector manual persistente, metadatos seguros de actualización, progreso de APT/DNF, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `installer/output/lockcode-linux_0.4.5_all.deb`.
- Instalador RPM: `RPM/output/lockcode-linux_0.4.5_noarch.rpm`.
- SHA-256 DEB: `b4fa13e4c13a1d45ed06bd5c986b9c4aece2e8a452e696e0a1380f75fdbbffc9`.
- SHA-256 RPM: `cf99aebc8455ea9232023a379751c9a6d8f881217b9446a99f235da38f83a5a9`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
