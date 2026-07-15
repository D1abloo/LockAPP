# LockCode para Windows 0.4.5

Proyecto independiente para Windows 10 2004 o posterior. No usa archivos ni configuración de la edición macOS.

Versión publicada: **0.4.5**. Uso gratuito sujeto a la [Política de uso general](../USAGE_POLICY.md) y a las condiciones mostradas por el instalador.

## Funciones

- Código de 4–64 caracteres con símbolos, derivado con PBKDF2-HMAC-SHA256 y guardado en Windows Credential Manager.
- Windows Hello automático cuando está disponible.
- Aplicaciones clásicas, rutas `App Paths`, paquetes AppX/MSIX integrados de Windows y selector manual de ejecutables `.exe`.
- Monitor de procesos que oculta la ventana antes de autenticar y solo la restaura o reabre tras aprobar; nunca usa `Process.Kill()`.
- Periodo de gracia, bloqueo inmediato, registro local anónimo, actualizaciones y área de notificación.
- Inicio temprano de sesión mediante `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.

## Compilar, probar e instalar

### Requisitos de desarrollo

- Windows 10 2004 o Windows 11 de 64 bits.
- .NET 8 SDK.
- NSIS 3 para crear el instalador.
- PowerShell 5.1 o posterior.

Desde PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build.ps1
```

El instalador moderno se crea en `Installer\output\LockCode-Windows-0.4.5-Setup.exe`. Incluye:

- icono rojo de LockCode en el instalador, ejecutable, ventanas, bandeja, menú Inicio, escritorio y desinstalación;
- presentación y descripción del producto;
- condiciones de uso que deben aceptarse expresamente para continuar;
- selección de carpeta y acceso directo opcional en el escritorio;
- ejecución opcional de LockCode al terminar.

Para desarrollo:

```powershell
dotnet run --project .\LockCode.Windows\LockCode.Windows.csproj
dotnet run --project .\LockCode.Windows.Tests\LockCode.Windows.Tests.csproj
```

## Instalación y primer inicio

1. Ejecuta `LockCode-Windows-0.4.5-Setup.exe`.
2. Lee las condiciones. Si no las aceptas, cancela: no se instalará la aplicación.
3. Conserva la carpeta propuesta o elige otra y termina el asistente.
4. Crea un código de 4–64 caracteres. Admite letras, números, espacios y símbolos.
5. LockCode permanece en el área de notificación. Marca las aplicaciones que quieras proteger.
6. Mantén activado **Iniciar LockCode con Windows**. La entrada se registra para el usuario actual en `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
7. Cierra sesión o reinicia Windows y confirma que aparece el icono de LockCode en la bandeja.

Windows Hello se inicia automáticamente cuando está habilitado y disponible. Si no está configurado o se cancela, se muestra el campo de código.

La sección **Actualizaciones** muestra la edición, versión instalada y versión disponible. Al aceptar, descarga el instalador oficial, verifica su SHA-256, cierra LockCode, actualiza silenciosamente y vuelve a iniciarlo. Las ediciones pueden tener versiones distintas; Windows ignora releases que no incluyan su instalador.

## Comprobaciones recomendadas

```powershell
# Proceso activo
Get-Process LockCode -ErrorAction SilentlyContinue

# Inicio automático del usuario
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name LockCode

# Ruta instalada y versión
Get-ItemProperty 'HKCU:\Software\LockCode'
(Get-Item "$env:LOCALAPPDATA\Programs\LockCode\LockCode.exe").VersionInfo

# Pruebas
dotnet run --project .\LockCode.Windows.Tests\LockCode.Windows.Tests.csproj -c Release
```

Prueba una aplicación sin documentos abiertos: protégela, ciérrala y ábrela. Debe ocultarse y solicitar Windows Hello o el código. Después verifica bloqueo inmediato, periodo de gracia, salida autenticada y reinicio de sesión. Apagar o reiniciar Windows no debe solicitar autenticación de LockCode.

Comprueba también una aplicación integrada, como Calculadora, Bloc de notas, Paint, Terminal o PowerShell. Si figura en el catálogo y se marca, debe permanecer oculta mientras se muestra la autenticación; no debe cerrarse antes de solicitarla.

## Si LockCode no inicia

1. Ejecuta manualmente `%LOCALAPPDATA%\Programs\LockCode\LockCode.exe`.
2. Revisa **Seguridad de Windows > Control de aplicaciones y navegador**. Mientras el instalador no esté firmado, SmartScreen puede requerir **Más información > Ejecutar de todas formas**.
3. Comprueba el proceso y la entrada `Run` con los comandos anteriores.
4. Revisa **Visor de eventos > Registros de Windows > Aplicación** y **Microsoft > Windows > .NET Runtime**.
5. Guarda un diagnóstico sin datos sensibles:

   ```powershell
   Get-WinEvent -LogName Application -MaxEvents 100 |
     Where-Object ProviderName -in '.NET Runtime','Application Error' |
     Format-List TimeCreated,ProviderName,Id,LevelDisplayName,Message |
     Out-File "$env:USERPROFILE\Desktop\LockCode-diagnostico.txt"
   ```

No incluyas el código de LockCode ni contraseñas en diagnósticos.

## Acceso remoto para soporte

Si se autoriza una comprobación remota, Windows debe estar encendido, en la misma red y con OpenSSH Server habilitado. En PowerShell como administrador:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
ipconfig
```

Al terminar el soporte puede detenerse con `Stop-Service sshd` y deshabilitarse con `Set-Service sshd -StartupType Disabled`.

## Distribución y firma

El instalador actual es funcional pero no está firmado. Para distribución pública, firma `LockCode.exe` y el instalador con un certificado Authenticode de confianza y marca de tiempo; después publica el `.exe` y su SHA-256 en GitHub Releases.

## Desinstalación

Usa **Configuración > Aplicaciones > Aplicaciones instaladas > LockCode > Desinstalar**. El desinstalador elimina el programa, accesos directos y arranque automático. La configuración local y la credencial pueden conservarse deliberadamente para evitar una pérdida accidental; pueden borrarse manualmente desde `%LOCALAPPDATA%\LockCode` y Administrador de credenciales.

## Limitación

Es un bloqueo de privacidad *best effort*. El orden de inicio lo decide Windows; un servicio/driver firmado sería necesario para impedir la ejecución antes de la sesión. La aplicación no bloquea apagado ni reinicio.

No hay telemetría. La configuración, credencial derivada y registro permanecen en el equipo; comprobar actualizaciones contacta con GitHub. Consulta gratuidad, privacidad, distribución, garantías y soporte en la [Política de uso](../USAGE_POLICY.md).

Soporte: `isaaccoria46@gmail.com`. No envíes códigos, contraseñas ni información privada.

Copyright © 2026 Isaac Silva Jiménez.
