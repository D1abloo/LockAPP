# Validación Linux 0.1.2

- 15 de julio de 2026: 12 pruebas unitarias correctas (incluyen identidad de credencial por instalación, migración de credencial anterior, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencia obligatoria del indicador, icono, entrada de escritorio, unidad systemd y scripts `postinst`, `prerm` y `postrm` correctos.
- Instalador: `build/lockcode-linux_0.1.2_all.deb`.
- SHA-256: `34d72c2599e2d81040137ff75821ca2f11e8c44f7a6dadf0f42a453c5239f626`.
- Actualización 0.1.1 → 0.1.2 comprobada en Ubuntu: configuración conservada, servicio activo y una sola instancia.
- `apt purge` comprobado: servicio, configuración, registro, caché y archivos del paquete eliminados.
- Instalación nueva comprobada sin variables de `sudo`: servicio activo, una sola instancia, onboarding nuevo pendiente e indicador Ayatana `Active` con el icono `com.lockcode.Linux`.

Pendiente en Linux: validar fprintd en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
