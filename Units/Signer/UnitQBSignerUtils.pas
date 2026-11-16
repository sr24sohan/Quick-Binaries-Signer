unit UnitQBSignerUtils;

{
  This unit holds general-purpose helper functions that are NOT tied to
  TFormQBSigner. Keeping them here means UnitQBSigner.pas only contains
  form/UI logic, which makes the project much easier to read and maintain.

  Contents:
    - GetFileVersion                      : reads file version info (e.g. signtool.exe version)
    - WriteRegistryIntegerForSettings      : writes a DWORD value to the registry
    - WriteRegistryStringsForSettings      : writes a string value to the registry
    - ReadRegistryStringsForSettings       : reads a string value from the registry
    - ReadRegistryIntegerForSettings       : reads a DWORD value from the registry
    - OpenURL                              : opens a URL in the default browser
}

interface

uses
  Winapi.Windows, System.SysUtils, ShellAPI, Registry;

function GetFileVersion(const FileName: string): string; stdcall;

procedure WriteRegistryIntegerForSettings(const RootKey: HKEY;
  const WriteRegKeyPath, WriteRegValueName: string; WriteRegValueData: DWORD);

procedure WriteRegistryStringsForSettings(const RootKey: HKEY;
  const WriteRegKeyPath, WriteRegValueName, WriteRegValueData: string);

function ReadRegistryStringsForSettings(const RootKey: HKEY;
  const ReadRegKeyPath, ReadRegValueName: string;
  const DefaultValue: string = ''): string;

function ReadRegistryIntegerForSettings(const RootKey: HKEY;
  const ReadRegKeyPath, ReadRegValueName: string): DWORD;

procedure OpenURL(const URL: string);

implementation

function GetFileVersion(const FileName: string): string; stdcall;
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

procedure WriteRegistryIntegerForSettings(const RootKey: HKEY;
  const WriteRegKeyPath, WriteRegValueName: string; WriteRegValueData: DWORD);
var
  WriteRegBooleanQP: TRegistry;
begin
  WriteRegBooleanQP := TRegistry.Create;
  try
    WriteRegBooleanQP.RootKey := RootKey;
    if WriteRegBooleanQP.OpenKey(WriteRegKeyPath, True) then
    begin
      WriteRegBooleanQP.WriteInteger(WriteRegValueName, WriteRegValueData);
      WriteRegBooleanQP.CloseKey;
    end;
  finally
    WriteRegBooleanQP.Free;
  end;
end;

procedure WriteRegistryStringsForSettings(const RootKey: HKEY;
  const WriteRegKeyPath, WriteRegValueName, WriteRegValueData: string);
var
  WriteRegStr: TRegistry;
begin
  WriteRegStr := TRegistry.Create(KEY_WRITE);
  try
    WriteRegStr.RootKey := RootKey;
    if WriteRegStr.OpenKey(WriteRegKeyPath, True) then
      try
        WriteRegStr.WriteString(WriteRegValueName, WriteRegValueData);
      finally
        WriteRegStr.CloseKey;
      end;
  finally
    WriteRegStr.Free;
  end;
end;

function ReadRegistryStringsForSettings(const RootKey: HKEY;
  const ReadRegKeyPath, ReadRegValueName: string;
  const DefaultValue: string = ''): string;
var
  ReadRegStr: TRegistry;
begin
  Result := DefaultValue;
  ReadRegStr := TRegistry.Create(KEY_READ);
  try
    ReadRegStr.RootKey := RootKey;
    if ReadRegStr.OpenKeyReadOnly(ReadRegKeyPath) then
      try
        if ReadRegStr.ValueExists(ReadRegValueName) then
          Result := ReadRegStr.ReadString(ReadRegValueName);
      finally
        ReadRegStr.CloseKey;
      end;
  finally
    ReadRegStr.Free;
  end;
end;

function ReadRegistryIntegerForSettings(const RootKey: HKEY;
  const ReadRegKeyPath, ReadRegValueName: string): DWORD;
var
  ReadRegistryBooleanQP: TRegistry;
begin
  Result := 0;
  ReadRegistryBooleanQP := TRegistry.Create;
  try
    ReadRegistryBooleanQP.RootKey := RootKey;
    if ReadRegistryBooleanQP.OpenKeyReadOnly(ReadRegKeyPath) then
    begin
      if ReadRegistryBooleanQP.ValueExists(ReadRegValueName) then
        Result := ReadRegistryBooleanQP.ReadInteger(ReadRegValueName);
      ReadRegistryBooleanQP.CloseKey;
    end;
  finally
    ReadRegistryBooleanQP.Free;
  end;
end;

procedure OpenURL(const URL: string);
begin
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
end;

end.
