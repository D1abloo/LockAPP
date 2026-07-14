$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
dotnet run --project "$root\LockCode.Windows.Tests\LockCode.Windows.Tests.csproj" -c Release
dotnet publish "$root\LockCode.Windows\LockCode.Windows.csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o "$root\publish"
$makensis = (Get-Command makensis.exe -ErrorAction SilentlyContinue).Source
if (-not $makensis) {
  $candidates = @("${env:ProgramFiles(x86)}\NSIS\makensis.exe", "$env:ProgramFiles\NSIS\makensis.exe")
  $makensis = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if ($makensis) {
  Push-Location "$root\Installer"
  try { & $makensis "LockCode.nsi" }
  finally { Pop-Location }
}
else { Write-Host "Publicación creada. Instala NSIS 3 para generar el instalador .exe." }
