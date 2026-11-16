unit uForceRunAsAdmin;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, Vcl.Forms, System.SysUtils;

function EnsureAdministrator: Boolean;
function MakeSingleInstanceOnly(const MutexName: string): Boolean;

implementation

var
  GMutexHandle: THandle = 0;


function IsRunningAsAdmin: Boolean;
var
  Token: THandle;
  Elevation: TOKEN_ELEVATION;
  ReturnLength: DWORD;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then
    Exit;
  try
    ReturnLength := 0;
    if GetTokenInformation(Token, TokenElevation, @Elevation,
         SizeOf(Elevation), ReturnLength) then
      Result := Elevation.TokenIsElevated <> 0;
  finally
    CloseHandle(Token);
  end;
end;

function RestartAsAdministrator: Boolean;
var
  CmdLine: string;
  ExecInfo: TShellExecuteInfo;
  I: Integer;
begin
  CmdLine := '';
  for I := 1 to ParamCount do
    CmdLine := CmdLine + ' "' + ParamStr(I) + '"';

  FillChar(ExecInfo, SizeOf(ExecInfo), 0);
  ExecInfo.cbSize := SizeOf(ExecInfo);
  ExecInfo.fMask := SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
  ExecInfo.lpVerb := 'runas';
  ExecInfo.lpFile := PChar(Application.ExeName);
  if CmdLine <> '' then
    ExecInfo.lpParameters := PChar(Trim(CmdLine));
  ExecInfo.nShow := SW_SHOWNORMAL;

  Result := ShellExecuteEx(@ExecInfo);

  if Result and (ExecInfo.hProcess <> 0) then
    CloseHandle(ExecInfo.hProcess);

  if not Result then
  begin
    // ERROR_CANCELLED = user UAC prompt-এ "No" দিয়েছে।
    // চাইলে এখানে GetLastError চেক করে আলাদা মেসেজ দেখাতে পারেন।
  end;
end;

function EnsureAdministrator: Boolean;
begin
  if IsRunningAsAdmin then
    Exit(True);

  RestartAsAdministrator;
  Result := False;
end;


function MakeSingleInstanceOnly(const MutexName: string): Boolean;
begin
  GMutexHandle := CreateMutex(nil, True, PChar(MutexName));

  if GMutexHandle = 0 then
  begin
    Result := True;
    Exit;
  end;

  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(GMutexHandle);
    GMutexHandle := 0;
    Result := False;
  end
  else
    Result := True;
end;

initialization

finalization
  if GMutexHandle <> 0 then
  begin
    ReleaseMutex(GMutexHandle);
    CloseHandle(GMutexHandle);
  end;

end.
