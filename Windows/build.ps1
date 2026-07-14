$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
dotnet run --project "$root\LockCode.Windows.Tests\LockCode.Windows.Tests.csproj" -c Release
dotnet publish "$root\LockCode.Windows\LockCode.Windows.csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o "$root\publish"
$makensis = Get-Command makensis.exe -ErrorAction SilentlyContinue
if ($makensis) { & $makensis "$root\Installer\LockCode.nsi" }
else { Write-Host "Publicación creada. Instala NSIS para generar el instalador .exe." }
