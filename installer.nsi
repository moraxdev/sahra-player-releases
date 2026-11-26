; Installer for an app that ships as one program file (Sahra Player, PMO Toolkit).
; Per-user install: no admin prompt, no system folders touched.
;   makensis -DAPP="Sahra Player" -DEXE=sahra-player.exe -DKEY=SahraPlayer -DVERSION=1.17.2 \
;            -DSRC=<the program file> -DICON=<icon.ico> -DOUT=<setup.exe> wrap.nsi
; /S installs silently (the Hub uses this). /UPDATE also starts the app afterwards.
Unicode true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

!define UNKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KEY}"

Name "${APP}"
OutFile "${OUT}"
InstallDir "$LOCALAPPDATA\Programs\${APP}"
InstallDirRegKey HKCU "Software\${APP}" "InstallDir"
BrandingText "© Amr Karam · Amr.karam@gmail.com"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${APP}"
VIAddVersionKey "FileDescription" "${APP} Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "© Amr Karam"
VIAddVersionKey "CompanyName" "Amr Karam"

!define MUI_ICON "${ICON}"
!define MUI_UNICON "${ICON}"
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Open ${APP}"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Var Update

Function .onInit
  ${GetParameters} $0
  ClearErrors
  ${GetOptions} $0 "/UPDATE" $1
  ${IfNot} ${Errors}
    StrCpy $Update "1"
  ${EndIf}
FunctionEnd

Section "Install"
  SetOutPath "$INSTDIR"
  ; Wait until the old program file is free (the app closes itself before an update).
  StrCpy $2 0
  wait:
    ClearErrors
    IfFileExists "$INSTDIR\${EXE}" 0 free
    Delete "$INSTDIR\${EXE}"
    IfErrors 0 free
    IntOp $2 $2 + 1
    IntCmp $2 40 busy
    Sleep 500
    Goto wait
  busy:
    IfSilent 0 +2
      Abort
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "${APP} is still open. Close it, then press Retry." IDRETRY wait
    Abort
  free:

  File "/oname=${EXE}" "${SRC}"
  File "/oname=icon.ico" "${ICON}"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateShortcut "$SMPROGRAMS\${APP}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\icon.ico"
  ; A desktop shortcut only on the first install, so one the user deleted stays deleted.
  ReadRegStr $3 HKCU "${UNKEY}" "DisplayVersion"
  ${If} $3 == ""
    CreateShortcut "$DESKTOP\${APP}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\icon.ico"
  ${EndIf}

  WriteRegStr HKCU "Software\${APP}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${UNKEY}" "DisplayName" "${APP}"
  WriteRegStr HKCU "${UNKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNKEY}" "Publisher" "Amr Karam"
  WriteRegStr HKCU "${UNKEY}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "${UNKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNKEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "${UNKEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNKEY}" "NoRepair" 1

  ${If} $Update == "1"
    Exec '"$INSTDIR\${EXE}"'
  ${EndIf}
SectionEnd

Section "Uninstall"
  ; Settings the app keeps beside itself (a "data" folder) are left in place.
  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\icon.ico"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${APP}.lnk"
  Delete "$DESKTOP\${APP}.lnk"
  DeleteRegKey HKCU "${UNKEY}"
  DeleteRegKey HKCU "Software\${APP}"
SectionEnd
