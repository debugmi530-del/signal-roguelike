; Inno Setup script for SIGNAL.
; Builds a Windows installer from the Godot-exported build in game/builds/windows.
; Invoked by .github/workflows/build.yml via ISCC.exe.

#define MyAppName "SIGNAL"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Signal Team"
#define MyAppExeName "SIGNAL.exe"

[Setup]
AppId={{B7B9B8A2-6E9E-4B6C-9B27-2E6D6E1B1A11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=SIGNAL-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\builds\windows\SIGNAL.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\builds\windows\*"; Excludes: "SIGNAL.exe"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
