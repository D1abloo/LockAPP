# Validación Windows 0.4.1

- 15 de julio de 2026: 13 comprobaciones correctas (incluyen actualización oficial validada, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y prevención de ciclos).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.1-Setup.exe`.
- SHA-256: `77ea92c84ce4e3234d1a7d705dd68a1fa49baa0c1e52e684ad505305a5336373`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
