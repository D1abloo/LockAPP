Unicode True
!include "MUI2.nsh"
!include "LogicLib.nsh"

!define APP_NAME "LockCode"
!define APP_VERSION "0.4.0"
!define APP_PUBLISHER "Isaac Silva Jiménez"
!define APP_URL "https://github.com/D1abloo/LockAPP"
!define MUI_ICON "..\LockCode.Windows\Assets\LockCode.ico"
!define MUI_UNICON "..\LockCode.Windows\Assets\LockCode.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "Assets\Welcome.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "Assets\Header.bmp"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Instalar LockCode para Windows"
!define MUI_WELCOMEPAGE_TEXT "LockCode protege la privacidad de las aplicaciones seleccionadas mediante un código o Windows Hello.$\r$\n$\r$\nEste asistente instalará la edición independiente para Windows."
!define MUI_LICENSEPAGE_CHECKBOX
!define MUI_FINISHPAGE_RUN "$INSTDIR\LockCode.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Iniciar LockCode ahora"
!define MUI_FINISHPAGE_LINK "Repositorio y actualizaciones"
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_URL}"

Name "${APP_NAME}"
OutFile "output\LockCode-Windows-${APP_VERSION}-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\LockCode"
InstallDirRegKey HKCU "Software\LockCode" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "LockCode — protección de privacidad"
Icon "..\LockCode.Windows\Assets\LockCode.ico"
WindowIcon On
VIProductVersion 0.4.0.0
VIAddVersionKey /LANG=1034 "ProductName" "LockCode para Windows"
VIAddVersionKey /LANG=1034 "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey /LANG=1034 "FileDescription" "Instalador de LockCode"
VIAddVersionKey /LANG=1034 "FileVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1034 "ProductVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1034 "LegalCopyright" "Copyright © 2026 ${APP_PUBLISHER}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Section "LockCode (obligatorio)" SecMain
  SectionIn RO
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayVersion"
  ${If} $0 != ""
  ${AndIf} $0 != "${APP_VERSION}"
    WriteRegStr HKCU "Software\LockCode" "UpdatedFrom" "$0"
  ${EndIf}
  SetOutPath "$INSTDIR"
  File /r "..\publish\*"
  CreateDirectory "$SMPROGRAMS\LockCode"
  CreateShortcut "$SMPROGRAMS\LockCode\LockCode.lnk" "$INSTDIR\LockCode.exe" "" "$INSTDIR\LockCode.exe" 0
  WriteRegStr HKCU "Software\LockCode" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayName" "LockCode"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "DisplayIcon" "$INSTDIR\LockCode.exe,0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode" "NoRepair" 1
SectionEnd

Section /o "Acceso directo en el escritorio" SecDesktop
  CreateShortcut "$DESKTOP\LockCode.lnk" "$INSTDIR\LockCode.exe" "" "$INSTDIR\LockCode.exe" 0
SectionEnd

LangString DESC_SecMain ${LANG_SPANISH} "Aplicación, icono, acceso del menú Inicio y desinstalador."
LangString DESC_SecDesktop ${LANG_SPANISH} "Añade un acceso directo con el icono de LockCode al escritorio."
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "LockCode"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LockCode"
  DeleteRegKey HKCU "Software\LockCode"
  Delete "$DESKTOP\LockCode.lnk"
  Delete "$SMPROGRAMS\LockCode\LockCode.lnk"
  RMDir "$SMPROGRAMS\LockCode"
  RMDir /r "$INSTDIR"
SectionEnd
