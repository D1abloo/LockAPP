# Validación Windows 0.4.7

Estado publicado vigente para Windows. Condiciones generales: [`USAGE_POLICY.md`](../USAGE_POLICY.md).

- 15 de julio de 2026: 16 comprobaciones correctas (incluyen catálogo AppX/MSIX, actualización oficial validada, ejecución directa del instalador sin navegador, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y una sola autenticación por aplicación multiproceso).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.7-Setup.exe`.
- SHA-256: `cf0fe329e5af33374fb5b83554e92b1065841ac258e58cffeee7108738683e43`.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
