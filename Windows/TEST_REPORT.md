# Validación Windows 0.4.5

- 15 de julio de 2026: 15 comprobaciones correctas (incluyen catálogo AppX/MSIX, actualización oficial validada, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y prevención de ciclos).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.5-Setup.exe`.
- SHA-256: `230945f706ad533e046537431d3b6ab62d8ffb4edf52f61bc0611eb96ef52f6a`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
