; Antigravity Review Helper — Inno Setup Script
; Version: 0.3.0-test
; Author: Paul Atan <greghous91@gmail.com>
;
; To build:
;   Install Inno Setup 6: https://jrsoftware.org/isinfo.php
;   Then run: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" AntigravityReviewHelper.iss
;
; Per-user install — NO admin rights required.

[Setup]
AppName=Antigravity Review Helper
AppVersion=0.3.0-test
AppPublisher=Paul Atan
AppPublisherURL=mailto:greghous91@gmail.com
AppSupportURL=mailto:greghous91@gmail.com
AppUpdatesURL=mailto:greghous91@gmail.com
DefaultDirName={localappdata}\Programs\Antigravity Review Helper
DefaultGroupName=Antigravity Review Helper
OutputDir=..\release
OutputBaseFilename=AntigravityReviewHelper-v0.3.0-test-Setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
UninstallDisplayName=Antigravity Review Helper
DisableWelcomePage=no
DisableDirPage=no
DisableProgramGroupPage=no
ShowLanguageDialog=no
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Main EXE
Source: "..\release\AntigravityReviewHelper-v0.3.0-test\AntigravityReviewHelper.exe"; DestDir: "{app}"; Flags: ignoreversion

; Button assets
Source: "..\release\AntigravityReviewHelper-v0.3.0-test\assets\buttons\*"; DestDir: "{app}\assets\buttons"; Flags: ignoreversion recursesubdirs createallsubdirs

; Alert assets
Source: "..\release\AntigravityReviewHelper-v0.3.0-test\assets\alerts\*"; DestDir: "{app}\assets\alerts"; Flags: ignoreversion recursesubdirs createallsubdirs

; Docs
Source: "..\release\AntigravityReviewHelper-v0.3.0-test\README_TEST_RUN.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\release\AntigravityReviewHelper-v0.3.0-test\RELEASE_NOTES.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcut
Name: "{group}\Antigravity Review Helper"; Filename: "{app}\AntigravityReviewHelper.exe"
Name: "{group}\Uninstall Antigravity Review Helper"; Filename: "{uninstallexe}"

; Desktop shortcut (optional task)
Name: "{autodesktop}\Antigravity Review Helper"; Filename: "{app}\AntigravityReviewHelper.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
; Option to launch after install
Filename: "{app}\AntigravityReviewHelper.exe"; Description: "Launch Antigravity Review Helper"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM AntigravityReviewHelper.exe"; Flags: runhidden; RunOnceId: "KillApp"

[Code]
// Show a reminder about Dry Run mode at end of installer
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('Antigravity Review Helper v0.3.0-test installed.' + #13#10 + #13#10 +
           'IMPORTANT:' + #13#10 +
           '- Dry Run is ON by default. No real clicks will be performed.' + #13#10 +
           '- Do NOT enable Live mode until Dry Run passes all manual tests.' + #13#10 +
           '- Assets are installed next to the EXE.' + #13#10 + #13#10 +
           'Author: Paul Atan (greghous91@gmail.com)',
           mbInformation, MB_OK);
  end;
end;
