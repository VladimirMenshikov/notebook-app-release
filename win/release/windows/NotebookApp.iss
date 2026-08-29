; ============================================================
; Notebook App — Windows Installer (Inno Setup)
; ============================================================

#define MyAppName "Notebook App"
#define MyAppVersion "1.0.6"
#define MyAppPublisher "Vladimir Menshikov"
#define MyAppURL "https://github.com/VladimirMenshikov/notebook-app-release"
#define MyAppExeName "notebook_app.exe"

[Setup]
; --- Основные параметры ---
AppId={{A8B3C7D1-4E5F-6A7B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; --- Выходной файл ---
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=.\
OutputBaseFilename=NotebookApp-{#MyAppVersion}-windows-x64-setup

; --- Параметры установщика ---
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: russian; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные ярлыки:"; Flags: unchecked
Name: "startmenuicon"; Description: "Создать ярлык в меню «Пуск»"; GroupDescription: "Дополнительные ярлыки:"; Flags: unchecked

[Files]
; --- Исходные файлы из папки приложения ---
; DLL и исполняемый файл — в корень
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\notebook_app.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\*_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
; Ресурсы — в папку data
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\app.so"; DestDir: "{app}\data"; Flags: ignoreversion
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\icudtl.dat"; DestDir: "{app}\data"; Flags: ignoreversion
Source: "..\..\NotebookApp-{#MyAppVersion}-windows-x64\flutter_assets\*"; DestDir: "{app}\data\flutter_assets"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{#MyAppName} (Удалить)"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{autopf}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenuicon
