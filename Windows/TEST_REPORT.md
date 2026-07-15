# Validación Windows 0.4.7

Estado publicado vigente para Windows. Condiciones generales: [`USAGE_POLICY.md`](../USAGE_POLICY.md).

- 15 de julio de 2026: 15 comprobaciones correctas (incluyen catálogo AppX/MSIX, actualización oficial validada, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y una sola autenticación por aplicación multiproceso).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.7-Setup.exe`.
- SHA-256: `45fbf11eabd0638e97e4174f1958302dbe5fb25f2e2676e0cd320ab77c1bb346`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
