# Validación Windows 0.4.7

Estado publicado vigente para Windows. Condiciones generales: [`USAGE_POLICY.md`](../USAGE_POLICY.md).

- 15 de julio de 2026: 17 comprobaciones correctas (incluyen catálogo AppX/MSIX, normalización de navegadores a su lanzador principal, actualización oficial validada, ejecución directa del instalador sin navegador, aplicación manual persistente, código y símbolos, credencial derivada, penalización, gracia, bloqueo al cerrar y una sola autenticación por aplicación multiproceso).
- Compilación `net8.0-windows10.0.19041.0`: correcta, 0 errores y 0 advertencias.
- Publicación `win-x64` autocontenida y de archivo único: correcta.
- Instalador NSIS: `Installer/output/LockCode-Windows-0.4.7-Setup.exe`.
- SHA-256: `a677b7d0c9db91477715a9a34cc0e277b182723bf5324ed1825618fc58eb5f68`.

- Prueba real en Windows: Edge protegido se migró de dos rutas duplicadas a un único lanzador; sus ocho procesos permanecieron iguales antes y después de una sola autorización, sin abrir ventanas adicionales.

Pendiente en un equipo Windows: ejecutar el instalador, comprobar Credential Manager y Windows Hello reales, reiniciar sesión y probar aplicaciones gráficas protegidas. El instalador no está firmado aún; SmartScreen puede mostrar una advertencia.
