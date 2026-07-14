# Validación Linux 0.1.0

- 14 de julio de 2026: 7 pruebas unitarias correctas (código y símbolos, credencial derivada, penalización, persistencia, gracia, bloqueo al cerrar, prevención de ciclos y registro limitado).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencias, icono, entrada de escritorio y unidad systemd correctos; no contiene bytecode de la versión de Python del equipo de construcción.
- Instalador: `build/lockcode-linux_0.1.0_all.deb`.
- SHA-256: `848c5749a664402b084b9a7ac15e04ab791f01afec7e6a25f04cd720dab5b93c`.

Pendiente en Linux: instalar el `.deb`, comprobar Secret Service y fprintd reales, validar indicador en GNOME/KDE, reiniciar sesión y probar procesos gráficos protegidos bajo X11 y Wayland.
