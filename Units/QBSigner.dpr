
program QBSigner;

uses
  Vcl.Forms,
  Winapi.Windows,
  System.SysUtils,
  Vcl.Dialogs,
  Classes,
  Messages,
  System.Hash,
  Vcl.Themes,
  Vcl.Styles,
  uResourceProtector in 'Universal\uResourceProtector.pas',
  UnitQBSigner in 'Signer\UnitQBSigner.pas' {FormQBSigner};

{$R '..\Library\ResEXE.res'}


var
  MutexHandle: THandle;
const
  EXPECTED_HASH = '1447F4AEC2B1517935E09E310DA2B3E2';
  SIGNTOOL_NAME = 'signtool.exe';
  SignToolDefaultVersion = '10.0.22621.3233';


 FormResources: array[0..2] of record Name: string; Hash: string;    ResType: PChar; end = (

    (Name: 'SKIN_BUTTONS';  Hash: '6B470F91642A0C8DE54F241F480AA559'; ResType: 'VCLSTYLE'),
    (Name: 'SKIN_UI';       Hash: '8172D242A01B7C15777A820D6D1601F7'; ResType: 'VCLSTYLE'),
    (Name: 'TFORMQBSIGNER'; Hash: '1F5AC29718CBF4E431CAD80BBF273FA9'; ResType: RT_RCDATA)

  );



procedure CheckQBFormsIntegrity;
var i: Integer; ActualHash: string; MyExeName: string;
begin
   MyExeName := ExtractFileName(ParamStr(0));
  for i := 0 to High(FormResources) do
  begin
    ActualHash := CalculateUniversalResourceHash(FormResources[i].Name, FormResources[i].ResType);
    if (ActualHash = 'ERROR') or (not SameText(ActualHash, FormResources[i].Hash)) then
    begin
     MessageBoxW(Application.Handle, PWideChar('The application was unable to start correctly (0xC0000005).' + sLineBreak + 'Click OK to close the application.'),  PWideChar(MyExeName + ' - Application Error'), MB_OK or MB_ICONERROR or MB_TOPMOST);
     Halt(1);
    end;
  end;
end;

function GetHashofSigntoolExe(const FileName: string): string;
var
  FS: TFileStream;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := THashMD5.GetHashString(FS);
  finally
    FS.Free;
  end;
end;


function GetFileVersion(const FileName: string): string;
var
  InfoSize, Handle: DWORD;
  Info: Pointer;
  FileInfo: PVSFixedFileInfo;
  FileInfoSize: UINT;
begin
  Result := '';
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Handle);
  if InfoSize = 0 then
    Exit;

  GetMem(Info, InfoSize);
  try
    if GetFileVersionInfo(PChar(FileName), Handle, InfoSize, Info) then
    begin
      if VerQueryValue(Info, '\', Pointer(FileInfo), FileInfoSize) then
      begin
          Result := Format('%d.%d.%d.%d', [
          HiWord(FileInfo.dwFileVersionMS),
          LoWord(FileInfo.dwFileVersionMS),
          HiWord(FileInfo.dwFileVersionLS),
          LoWord(FileInfo.dwFileVersionLS)
        ]);
      end;
    end;
  finally
    FreeMem(Info);
  end;
end;






procedure CheckMyOriginalSignTool;
var
  ActualHash, MyInstallDir, DetectedSignToolVersion: string;
begin
 if not FileExists(SIGNTOOL_NAME) then
  begin
      Application.MessageBox('Required file "signtool.exe" was not found.'+sLineBreak+
      'Please repair the "signtool.exe" or obtain a new copy and place it in the program’s installation folder.',
      'Error - signtool.exe', mb_ok or MB_ICONSTOP);
   Exit;
  end;
  DetectedSignToolVersion := GetFileVersion(SIGNTOOL_NAME);
  ActualHash := GetHashofSigntoolExe(ExtractFilePath(ParamStr(0)) + SIGNTOOL_NAME);
  MyInstallDir:=ExtractFileDir(ParamStr(0));


  if not SameText(SignToolDefaultVersion, DetectedSignToolVersion) then
  begin
       Application.MessageBox(pchar('An incompatible Signtool version was found. Maybe the signing process is not working as well.'+sLineBreak+sLineBreak+
                'Please repair the "signtool.exe" or obtain a new copy and place it in the program’s installation folder.'+sLineBreak+sLineBreak+ 'Installation path: '+MyInstallDir+'.'), 'Warning', mb_ok or MB_ICONWARNING);
     Exit;
  end;
   if SameText(DetectedSignToolVersion, SignToolDefaultVersion) and not SameText(ActualHash, EXPECTED_HASH) then
    begin
       Application.MessageBox('Integrity verification failed. Please make sure "signtool.exe" is not corrupted, otherwise the signing process may fail.', 'Warning', mb_ok or MB_ICONWARNING );
    end;
end;

  procedure CheckSingleInstanceForQBSigner;
  begin
      MutexHandle := CreateMutex(nil, True, 'srstudiobd.QuickBinariesSigner');
  if (MutexHandle = 0) or (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    application.MessageBox('Application is already running.', 'Quick Binaries Signer', MB_ICONINFORMATION or MB_OK);
    halt(3);
  end;
  end;







begin
  CheckQBFormsIntegrity;
  CheckMyOriginalSignTool;
  CheckSingleInstanceForQBSigner ;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Luna');
  //   TStyleManager.TrySetStyle('Luna');
  Application.CreateForm(TFormQBSigner, FormQBSigner);
  Application.Run;

end.
