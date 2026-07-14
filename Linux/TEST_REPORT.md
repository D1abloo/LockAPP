# Validación Linux 0.1.1

- 15 de julio de 2026: 10 pruebas unitarias correctas (código y símbolos, credencial derivada, penalización, persistencia, gracia, bloqueo al cerrar, prevención de ciclos, registro limitado, catálogo de Terminal y migración de inicio).
- `compileall`: correcto.
- Paquete Debian inspeccionado: metadatos, permisos, dependencias, icono, entrada de escritorio y unidad systemd correctos; no contiene bytecode de la versión de Python del equipo de construcción.
- Instalador: `build/lockcode-linux_0.1.1_all.deb`.
- SHA-256: `4ff66b3ff0bd1d58ab9811d8c855e07ba23e9457b9098bdf772d1290874dba8a`.
- Instalación y reinicio comprobados por SSH en Ubuntu: servicio habilitado y activo, una sola instancia, entrada XDG antigua eliminada y credencial reconocida sin consultar el llavero durante el arranque.

Pendiente en Linux: validar fprintd e indicador de bandeja en hardware compatible y probar el bloqueo de aplicaciones gráficas bajo distintas sesiones X11/Wayland.
