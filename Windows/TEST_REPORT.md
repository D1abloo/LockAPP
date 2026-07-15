# Validación Windows 0.4.3

- 15 de julio de 2026: 13 comprobaciones correctas (incluyen actualización oficial validada, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y prevención de ciclos).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.3-Setup.exe`.
- SHA-256: `e62e9e7d19b0139c9f6476de9d8109c7d8dc2b2bdbc7f3629ca9acf0e06fbc8a`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
