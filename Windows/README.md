# LockCode para Windows

Proyecto independiente para Windows 10 2004 o posterior. No usa archivos ni configuración de la edición macOS.

## Funciones

- Código de 4–64 caracteres con símbolos, derivado con PBKDF2-HMAC-SHA256 y guardado en Windows Credential Manager.
- Windows Hello automático cuando está disponible.
- Aplicaciones instaladas obtenidas del registro de desinstalación.
- Monitor de procesos, ocultado y cierre normal; nunca usa `Process.Kill()`.
- Periodo de gracia, bloqueo inmediato, registro local anónimo, actualizaciones y área de notificación.
- Inicio temprano de sesión mediante `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.

## Compilar, probar e instalar

En Windows con .NET 8 SDK y NSIS 3:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build.ps1
```

El instalador se crea en `Installer\output`. Para desarrollo:

```powershell
dotnet run --project .\LockCode.Windows\LockCode.Windows.csproj
dotnet run --project .\LockCode.Windows.Tests\LockCode.Windows.Tests.csproj
```

## Limitación

Es un bloqueo de privacidad *best effort*. El orden de inicio lo decide Windows; un servicio/driver firmado sería necesario para impedir la ejecución antes de la sesión. La aplicación no bloquea apagado ni reinicio.
