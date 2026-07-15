# Validación Windows 0.4.2

- 15 de julio de 2026: 13 comprobaciones correctas (incluyen actualización oficial validada, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y prevención de ciclos).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.2-Setup.exe`.
- SHA-256: `a79ac719f911c54c846a7ade9a3464df8f600cee7666a49ccd16cc12f1eb3575`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
