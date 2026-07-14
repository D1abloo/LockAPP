# Validación Windows 0.1.0

- 14 de julio de 2026: 11 comprobaciones correctas (código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y prevención de ciclos).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.1.0-Setup.exe`.
- SHA-256: `d74bbdea99ea339a13c759d4394e451d3bf2ca7d7ab58dfd88aaafb541e05e97`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
