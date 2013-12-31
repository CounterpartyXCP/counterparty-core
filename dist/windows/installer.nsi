; installer.nsi
;
; NSIS install script for Counterpartyd 
!include StrRep.nsh ;for ReplaceInFile
!include ReplaceInFile.nsh ;for ReplaceInFile
!include nsDialogs.nsh ;for install dialogs
!include LogicLib.nsh ;for install dialogs

;--------------------------------

; The name of the installer
Name "Counterpartyd Installer"

; The file to write
OutFile "counterpartyd_install.exe"

; The default installation directory
InstallDir $PROGRAMFILES\Counterpartyd

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Counterpartyd" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

LicenseData "..\..\License.md"

;--------------------------------

; Variables
Var Dialog
Var lblLabel
Var lblHostname
Var lblPort
Var lblUsername
Var lblPassword
Var txtHostname
Var txtPort
Var txtUsername
Var pwdPassword

; Pages
Page license
Page components
Page directory
Page custom nsGetConfigSettings nsSaveConfigSettings
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------
Function nsGetConfigSettings
;see http://www.symantec.com/connect/articles/update-sql-your-nsis-installer
nsDialogs::Create /NOUNLOAD 1018
Pop $Dialog

${If} $Dialog == error
 Abort
${EndIf}

${NSD_CreateLabel} 0 0 100% 24u "Please enter in your bitcoind connection information:"
 Pop $lblLabel

${NSD_CreateLabel} 0 24u 36u 12u "Hostname"
 Pop $lblHostname

 ${NSD_CreateLabel} 0 36u 36u 12u "Port"
 Pop $lblPort

 ${NSD_CreateLabel} 0 48u 36u 12u "Username"
 Pop $lblUsername

 ${NSD_CreateLabel} 0 60u 36u 12u "Password"
 Pop $lblPassword

 ${NSD_CreateText} 36u 24u 100% 12u "localhost"
 Pop $txtHostname

 ${NSD_CreateText} 36u 36u 100% 12u "18832"
 Pop $txtPort

 ${NSD_CreateText} 36u 48u 100% 12u "rpc"
 Pop $txtUsername

 ${NSD_CreatePassword} 36u 60u 100% 12u ""
 Pop $pwdPassword

nsDialogs::Show
FunctionEnd

Function nsSaveConfigSettings
 ;get entered data
 ${NSD_GetText} $txtHostname $0
 ${NSD_GetText} $txtPort $1
 ${NSD_GetText} $txtUsername $2
 ${NSD_GetText} $pwdPassword $3
FunctionEnd

;--------------------------------
; The stuff to install
Section "Counterpartyd (required)"

  SectionIn RO
  InitPluginsDir

  SetShellVarContext all
  !define INSTDIR_DATA "$APPDATA\Counterparty\counterpartyd" ; call "SetShellVarContext all" before!
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "..\..\bin\build\*"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Counterpartyd "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "DisplayName" "Counterpartyd"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
  ;copy in the config file
  CreateDirectory $INSTDIR_DATA
  CopyFiles $INSTDIR\counterpartyd.conf.default $INSTDIR_DATA\counterpartyd.conf
  
  ;modify the config file based on what was entered earlier by the user
  !insertmacro _ReplaceInFile "$INSTDIR_DATA\counterpartyd.conf" "rpc-connect=localhost" "rpc-connect=$txtHostname"
  !insertmacro _ReplaceInFile "$INSTDIR_DATA\counterpartyd.conf" "rpc-port=18832" "rpc-port=$txtPort"
  !insertmacro _ReplaceInFile "$INSTDIR_DATA\counterpartyd.conf" "rpc-user=rpc" "rpc-user=$txtUsername"
  !insertmacro _ReplaceInFile "$INSTDIR_DATA\counterpartyd.conf" "rpc-password=rpcpw1234" "rpc-password=$pwdPassword"
  
  ; Install a service - ServiceType own process - StartType automatic - NoDependencies - Logon as System Account
  SimpleSC::InstallService "Counterpartyd" "Counterparty Daemon" "16" "2" "$INSTDIR\counterpartyd.exe" "" "" ""
  Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  ;IntCmp $0 0 SqlDone  

  ; Start a service. Be sure to pass the service name, not the display name.
  SimpleSC::StartService "Counterpartyd" "" 30
  Pop $0 ; returns an errorcode (<>0) otherwise success (0)
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Counterpartyd"
  CreateShortCut "$SMPROGRAMS\Counterpartyd\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Counterpartyd\Counterpartyd.lnk" "$INSTDIR\counterpartyd.exe" "" "$INSTDIR\counterpartyd.exe" 0
  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  ; Stop a service and waits for file release. Be sure to pass the service name, not the display name.
  SimpleSC::StopService "Counterpartyd" 1 30
  Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  
  ; Remove a service
  SimpleSC::RemoveService "Counterpartyd"
  Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd"
  DeleteRegKey HKLM SOFTWARE\Counterpartyd

  ; Remove files and uninstaller
  Delete $INSTDIR\counterpartyd.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Counterpartyd\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\Counterpartyd"
  RMDir "$INSTDIR"

SectionEnd
