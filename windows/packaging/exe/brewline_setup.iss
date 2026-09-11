; Brewline Windows installer (Inno Setup 6).
;
; Built by build.sh after `flutter build windows --release` finishes, using the
; ENTIRE bundle (build/windows/x64/runner/Release/) — not a hand-picked subset.
; `sqflite_common_ffi` loads the bundled sqlite3.dll over dart:ffi at runtime,
; and a script that drops it silently reintroduces the desktop launch crash
; (error code 126 / sqlite3_initialize). See improve.md.
;
; The version is injected at compile time:
;   ISCC.exe /DAppVersion=<version> brewline_setup.iss
; and defaults to 0.0.0 when omitted so the script still compiles standalone.

#define MyAppName "Brewline"
#define MyAppPublisher "Brewline"
#define MyAppPublisherURL "https://github.com/Abdogouhmad/brewline"
#define MyAppExeName "brewline.exe"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

[Setup]
; AppId uniquely identifies this application. Do not reuse it for other apps.
AppId={{284e0ce8-39e3-46e6-99ca-27fca9626794}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppPublisherURL}
AppSupportURL={#MyAppPublisherURL}
; Per-user install (no admin/UAC). The OTA updater keeps its own versioned
; directories under Documents, so nothing ever writes into the app directory.
DefaultDirName={localappdata}\Programs\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Flutter desktop builds are x64; keep the installer off 32-bit hosts.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\..\build\windows\x64\installer
OutputBaseFilename=brewline-setup-{#MyAppVersion}-x64
SetupIconFile=..\..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

; Ship the whole Release bundle (exe, DLLs, data/, sqlite3.dll, plugin libs).
[Files]
Source: "..\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent