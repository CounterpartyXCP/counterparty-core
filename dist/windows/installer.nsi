; installer.nsi
;
; NSIS install script for Counterpartyd 

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

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Counterpartyd (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "counterpartyd.exe"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Counterpartyd "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "DisplayName" "Counterpartyd"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Counterpartyd" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
  ; Install a service - ServiceType own process - StartType automatic - NoDependencies - Logon as System Account
  SimpleSC::InstallService "Counterpartyd" "CounterParty Daemon" "16" "2" "$INSTDIR\counterpartyd.exe" "" "" ""
  Pop $0 ; returns an errorcode (<>0) otherwise success (0)

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
