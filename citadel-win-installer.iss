; Windows Installer file for Citadel

[Setup]
AppName=Citadel
AppVersion=0.1.alpha
DefaultDirName={userappdata}\CitadelBuild
DefaultGroupName=Citadel
UninstallDisplayIcon={userappdata}\CitadelBuild\anura.exe
Compression=lzma2
SolidCompression=yes
OutputDir=c:\projects\
DisableDirPage=yes

[Files]
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\*.*"; DestDir: "{userappdata}\CitadelBuild"; Excludes: "*.pdb,.*,std*.*";
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\data\*.*"; DestDir: "{userappdata}\CitadelBuild\data"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\images\*.*"; DestDir: "{userappdata}\CitadelBuild\images"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\vcredist_x86_2012.exe"; DestDir: "{userappdata}\CitadelBuild"; Flags: deleteafterinstall

; This is everything which is not nescessarily whats wanted
; Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\anura-master\*.*"; DestDir: "{app}\modules\anura-master"; Excludes: ".*"; Flags: recursesubdirs

; These are more selective.
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\*.cfg"; DestDir: "{userappdata}\CitadelBuild\modules\Citadel"; Excludes: ".*,evo\*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\data\*.*"; DestDir: "{userappdata}\CitadelBuild\modules\Citadel\data"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\images\*.*"; DestDir: "{userappdata}\CitadelBuild\modules\Citadel\images"; Excludes: ".*"; Flags: recursesubdirs
;Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\locale\*.*"; DestDir: "{app}\modules\Citadel\locale"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\sounds\*.*"; DestDir: "{userappdata}\CitadelBuild\modules\Citadel\sounds"; Excludes: ".*"; Flags: recursesubdirs
;Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\music\*.*"; DestDir: "{app}\modules\Citadel\music"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\lib_2d\*.*"; DestDir: "{userappdata}\CitadelBuild\modules\lib_2d"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\icons\*.*"; DestDir: "{userappdata}\CitadelBuild\modules\icons"; Excludes: ".*"; Flags: recursesubdirs
Source: "C:\Projects\anura_master\vs2012\anura\Release\Win32\modules\Citadel\master-config.cfg"; DestDir: "{userappdata}\CitadelBuild"
; We should add manifest.cfg here.


[Icons]
Name: "{group}\Citadel"; Filename: "{userappdata}\CitadelBuild\anura.exe"
Name: "{group}\Uninstall Citadel"; Filename: "{uninstallexe}"

[Run]
Filename: "{userappdata}\CitadelBuild\vcredist_x86_2012.exe"; Parameters: "/q"

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "gla"; MessagesFile: "compiler:Languages\ScotsGaelic.isl"
Name: "ptBR"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "cz"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "jp"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "cat"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "dan"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "fin"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "cat"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "heb"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "nor"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "por"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "srp"; MessagesFile: "compiler:Languages\SerbianCyrillic.isl"
Name: "srplatin"; MessagesFile: "compiler:Languages\SerbianLatin.isl"
Name: "slv"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spa"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "ukr"; MessagesFile: "compiler:Languages\Ukrainian.isl"
