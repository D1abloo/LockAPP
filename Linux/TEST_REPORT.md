# Validación Linux 0.4.7

Estado publicado vigente para Debian/Ubuntu y RPM. Condiciones generales: [`USAGE_POLICY.md`](../USAGE_POLICY.md).

- 15 de julio de 2026: 14 pruebas unitarias correctas (incluyen selector manual persistente, metadatos seguros de actualización, progreso de APT/DNF, identidad de credencial por instalación, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador Debian: `installer/output/lockcode-linux_0.4.7_all.deb`.
- Instalador RPM: `RPM/output/lockcode-linux_0.4.7_noarch.rpm`.
- SHA-256 DEB: `b9032c539d442436509f429502851b824ba6aaa8b2d2e5330d1282c5ded7d0d9`.
- SHA-256 RPM: `6357190f4ae8e1e06c7e3fd65e6c0edc0dae7f9b4ff598f86c98f2bad08ccf4b`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.
- Actualizador: consulta asíncrona, descarga oficial verificada por SHA-256, autorización mediante PolicyKit, barra con progreso de APT/DNF y reinicio diferido del servicio.
- RPM construido e inspeccionado con `rpmbuild`/`rpm`: paquete `noarch`, dependencias Fedora/EPEL, scripts de sesión y rutas correctos. No se dispuso de una máquina Fedora/CentOS para una instalación gráfica real.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
