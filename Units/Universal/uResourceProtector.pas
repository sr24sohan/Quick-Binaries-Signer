{Resource Protector from Reverse Engineering
--------------------------------------------
//Copy Has on Form Load Event
uses  uResourceProtector, Clipbrd,
Clipboard.AsText:= CalculateUniversalResourceHash(1, RT_VERSION);
Clipboard.AsText:=CalculateUniversalResourceHash('TForm1', RT_RCDATA);




Project.dpr
---------------
uses
 Windows, SysUtils,


const
FormResources: array[0..1] of record Name: string; Hash: string; ResType: PChar; end = (
    (Name: '1'; Hash: 'F502109A12D9EA2D0270F80656E0FBB5'; ResType: RT_VERSION)
  , (Name: 'TForm1';     Hash: '7F4A20E59DFE5414DC5D4AD47324DEAF'; ResType: RT_RCDATA)
);


procedure CheckFormsHashIntegrity;
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


begin
 CheckFormsIntegrity;   //Just call it before form creating
end;











































































 }
unit uResourceProtector;
interface uses  SysUtils, Classes, Windows, IdHashMessageDigest;
function CalculateUniversalResourceHash(const ResourceName: string; ResourceType: PChar): string; overload;
function CalculateUniversalResourceHash(ResourceID: Integer; ResourceType: PChar): string; overload;
implementation
function InternalHashResourceData(Data: Pointer; Size: Integer): string;
var Hash: TIdHashMessageDigest5; Stream: TMemoryStream;
begin
  Result := '';
  if (Data = nil) or (Size <= 0) then  Exit;
  Stream := TMemoryStream.Create;
  try
    Stream.WriteBuffer(Data^, Size);
    Stream.Position := 0;
    Hash := TIdHashMessageDigest5.Create;
    try
      Result := Hash.HashStreamAsHex(Stream);
    finally
      Hash.Free;
    end;
  finally
    Stream.Free;
  end;
end;
function InternalCalculateHash(ResourceIdentifier: PChar; ResourceType: PChar): string;
var ResInfo: HRSRC; ResData: HGLOBAL;ResPtr: Pointer;  ResSize: DWORD;
begin
  Result := '';
  ResInfo := FindResource(GetModuleHandle(nil), ResourceIdentifier, ResourceType);
  if ResInfo = 0 then   Exit;
  ResData := LoadResource(GetModuleHandle(nil), ResInfo);
  if ResData = 0 then  Exit;
  ResPtr := LockResource(ResData);
  ResSize := SizeofResource(GetModuleHandle(nil), ResInfo);
  if (ResPtr = nil) or (ResSize = 0) then Exit;
  Result := InternalHashResourceData(ResPtr, ResSize);
end;
function CalculateUniversalResourceHash(const ResourceName: string; ResourceType: PChar): string; overload;
var NumericID: Integer;
begin
  if TryStrToInt(ResourceName, NumericID) then
  begin
    Result := CalculateUniversalResourceHash(NumericID, ResourceType);  Exit;
  end;
  Result := InternalCalculateHash(PChar(ResourceName), ResourceType);
end;
function CalculateUniversalResourceHash(ResourceID: Integer; ResourceType: PChar): string; overload;
begin
  Result := InternalCalculateHash(MakeIntResource(ResourceID), ResourceType);
end;
end.
