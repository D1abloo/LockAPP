Unicode True
Name "LockCode"
OutFile "output\LockCode-Windows-0.1.0-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\LockCode"
RequestExecutionLevel user
SetCompressor /SOLID lzma

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "LockCode" SecMain
  SetOutPath "$INSTDIR"
  File /r "..\publish\*"
  CreateDirectory "$SMPROGRAMS\LockCode"
  CreateShortcut "$SMPROGRAMS\LockCode\LockCode.lnk" "$INSTDIR\LockCode.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayName" "LockCode"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayVersion" "0.1.0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayIcon" "$INSTDIR\LockCode.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  Exec '"$INSTDIR\LockCode.exe"'
SectionEnd

Section "Uninstall"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "LockCode"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode"
  Delete "$SMPROGRAMS\LockCode\LockCode.lnk"
  RMDir "$SMPROGRAMS\LockCode"
  RMDir /r "$INSTDIR"
SectionEnd
