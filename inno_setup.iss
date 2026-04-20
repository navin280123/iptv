[Setup]
AppId={{D1A3B8B8-7E93-479D-948D-80B0ED86EE5E}
AppName=iptv
AppVersion=1.0.0
AppPublisher=Navin
AppPublisherURL=https://google.com/
AppSupportURL=https://google.com/
AppUpdatesURL=https://google.com/
DefaultDirName={autopf}\iptv
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=d:\Code\Flutter\iptv\build\windows\installer
OutputBaseFilename=iptv_installer
SetupIconFile=d:\Code\Flutter\iptv\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "d:\Code\Flutter\iptv\build\windows\x64\runner\Release\iptv.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "d:\Code\Flutter\iptv\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "d:\Code\Flutter\iptv\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\iptv"; Filename: "{app}\iptv.exe"
Name: "{autodesktop}\iptv"; Filename: "{app}\iptv.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\iptv.exe"; Description: "{cm:LaunchProgram,iptv}"; Flags: nowait postinstall skipifsilent
