program QBUtility;
uses
  Windows,
  SysUtils,
  Classes,
  Hash,
  uResourceProtector in 'Universal\uResourceProtector.pas',
  uForceRunAsAdmin in 'Universal\uForceRunAsAdmin.pas';

{$APPTYPE GUI}

{$R '..\Library\ResREP.res'}


const
  FormResources: array[0..0] of record Name: string; Hash: string; ResType: PChar; end = (
    (Name: 'SIGNTOOL'; Hash: '1447F4AEC2B1517935E09E310DA2B3E2'; ResType: RT_RCDATA));

  EXPECTED_HASH = '1447F4AEC2B1517935E09E310DA2B3E2';
  SIGNTOOL='SIGNTOOL';
  SIGNTOOL_EXE='signtool.exe';

var
  QB_SELF_PATH: string;
  SilentMode: Boolean;


function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  case dwCtrlType of
    CTRL_C_EVENT,
    CTRL_BREAK_EVENT:
      Result := True;
  else
    Result := False;
  end;
end;


procedure CheckSelfResourceHash;
var i: Integer; ActualHash: string; MyExeName: string;
begin
  MyExeName := ExtractFileName(ParamStr(0));
  for i := 0 to High(FormResources) do
  begin
    ActualHash := CalculateUniversalResourceHash(FormResources[i].Name, FormResources[i].ResType);
    if (ActualHash = 'ERROR') or (not SameText(ActualHash, FormResources[i].Hash)) then
    begin
      MessageBoxW(0, PWideChar('The application was unable to start correctly (0xC0000005).' + sLineBreak + 'Click OK to close the application.'), PWideChar(MyExeName + ' - Application Error'), MB_OK or MB_ICONERROR or MB_TOPMOST);
      Halt(1);
    end;
  end;
end;


procedure WaitForAnyKey;
var
  InputRec: TInputRecord;
  EventsRead: DWORD;
  hInput: THandle;
  vk: Word;
begin
  hInput := GetStdHandle(STD_INPUT_HANDLE);
  repeat
    ReadConsoleInput(hInput, InputRec, 1, EventsRead);
    if (InputRec.EventType = KEY_EVENT) and (InputRec.Event.KeyEvent.bKeyDown) then
    begin
      vk := InputRec.Event.KeyEvent.wVirtualKeyCode;
      if not (vk in [VK_SHIFT, VK_LSHIFT, VK_RSHIFT,
                     VK_CONTROL, VK_LCONTROL, VK_RCONTROL,
                     VK_MENU, VK_LMENU, VK_RMENU,
                     VK_CAPITAL, VK_NUMLOCK, VK_SCROLL]) then
        Break;
    end;
  until False;
end;

function GetCurrentSignToolHash(const FileName: string): string;
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


function ExtractFileFromRes(const MyRCDataName, MyFilePath1: string): Boolean;
var
  ResStream: TResourceStream;
  FileStream: TFileStream;
begin
  Result := False;
  try
    ResStream := TResourceStream.Create(HInstance, MyRCDataName, RT_RCDATA);
    try
      FileStream := TFileStream.Create(MyFilePath1, fmCreate);
      try
        FileStream.CopyFrom(ResStream, ResStream.Size);
      Result := True;
      finally
        FileStream.Free;
      end;
    finally
      ResStream.Free;
    end;
  except
    Result := False;
  end;
end;

function CheckExistSigntool: Boolean;
var
  ActualHash: string;
begin
  Result := False;
  ActualHash := GetCurrentSignToolHash(ExtractFilePath(ParamStr(0)) + SIGNTOOL_EXE);
  if SameText(ActualHash, EXPECTED_HASH) then Result := True;
end;




function DoRepair: Boolean;
begin
  Result := False;
  if FileExists(QB_SELF_PATH + SIGNTOOL_EXE) then
    DeleteFile(QB_SELF_PATH + SIGNTOOL_EXE);
  if ExtractFileFromRes(SIGNTOOL, QB_SELF_PATH + SIGNTOOL_EXE) then
    Result := True;
end;


// ---- GUI subsystem e thakle amra dorkar hole nijer console allocate kore nebo ----
procedure EnsureConsole;
begin
  if AllocConsole then
  begin
    IsConsole := True;
    Reset(Input);
    Rewrite(Output);
    Rewrite(ErrOutput);
  end;
end;


var
  i: Integer;

begin
 if not EnsureAdministrator then  Exit;
  CheckSelfResourceHash;
 if not MakeSingleInstanceOnly('SRStudio24.QBSignerRepairTool') then  Exit;


  SilentMode := False;
  for i := 1 to ParamCount do
    if SameText(ParamStr(i), '/repair') or SameText(ParamStr(i), '-repair') then
      SilentMode := True;

  if SilentMode then
  begin
    // ---- Kono console/window e khulbe na ----
    QB_SELF_PATH := ExtractFilePath(ParamStr(0));
    if not CheckExistSigntool then
    begin
      if DoRepair then
        MessageBoxW(0, 'Signtool.exe repaired successfully.', 'Quick Binaries Signer', MB_OK or MB_ICONINFORMATION or MB_TOPMOST)
      else
        MessageBoxW(0, 'Failed to repair signtool.exe.', 'Quick Binaries Signer', MB_OK or MB_ICONERROR or MB_TOPMOST);
    end
    else
      MessageBoxW(0, 'Signtool.exe is OK.', 'Quick Binaries Signer', MB_OK or MB_ICONINFORMATION or MB_TOPMOST);
    Halt(0);
  end;

  // ---- Interactive mode: nijer console banao, age er moto sob thakbe ----
  EnsureConsole;
  SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);

  QB_SELF_PATH := ExtractFilePath(ParamStr(0));

  if not CheckExistSigntool then
  begin
    Writeln('Detected dir: ' + QB_SELF_PATH);
    Writeln('Filename: ' + SIGNTOOL_EXE);
    Writeln('Signtool path: ' + QB_SELF_PATH + SIGNTOOL_EXE + sLineBreak);
    Writeln;
    Writeln('Press any key to repair the signtool.exe...');
    WaitForAnyKey;
    if DoRepair then
      Writeln('signtool.exe repaired successfully...')
    else
      Writeln('Error: failed to repair signtool.exe');
  end
  else
  begin
    Writeln('Quick Binaries Signer''s signtool.exe is OK.');
  end;

  Writeln;
  Writeln('Press any key to exit...');
  WaitForAnyKey;
  Halt;

end.
