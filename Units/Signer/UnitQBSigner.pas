unit UnitQBSigner;

interface

uses
   Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
    Vcl.Menus,  System.Generics.Collections, System.NetEncoding,  Graphics,  System.IOUtils,  UITypes,


  Vcl.StdCtrls, ShellAPI, System.Threading, Registry, Vcl.ComCtrls, Winapi.CommCtrl,  // Clipbrd, uResourceProtector,
  Vcl.BaseImageCollection, Vcl.ImageCollection, System.ImageList, Vcl.ImgList, Winapi.ActiveX,
  Vcl.VirtualImageList;

type
  TFormQBSigner = class(TForm)
    GroupBox1: TGroupBox;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    Help1: TMenuItem;
    TimestampGrpBox: TGroupBox;
    ProductNameGrpBox: TGroupBox;
    Label1: TLabel;
    BtnLoadPFX: TButton;
    Label2: TLabel;
    BtnHidePassword: TButton;
    EditTimestampUrl: TComboBox;
    CheckBoxUseTimestampService: TCheckBox;
    ListGrpBox: TGroupBox;
    ButtonsGroupBox: TGroupBox;
    BtnAddFiles: TButton;
    DontRemoveOldSignature1: TMenuItem;
    ChoosePFX1: TMenuItem;
    AddFiles1: TMenuItem;
    BtnSign: TButton;
    BtnClearAllFiles: TButton;
    ListView1: TListView;
    PopUpMenuQBS1: TPopupMenu;
    RemoveSelected1: TMenuItem;
    SigningOptions1: TMenuItem;
    ShowTimestamp1: TMenuItem;
    ProgressBar1: TProgressBar;
    Exit1: TMenuItem;
    Website1: TMenuItem;
    About1: TMenuItem;
    N1: TMenuItem;
    N3: TMenuItem;
    N2: TMenuItem;
    SHAL1: TMenuItem;
    SHAM2: TMenuItem;
    ShowinExplorer1: TMenuItem;
    N5: TMenuItem;
    Close1: TMenuItem;
    N6: TMenuItem;
    EditProductName: TComboBox;
    EditPFXPassword: TEdit;
    EditPfxFile: TComboBox;
    VirtualImageList1: TVirtualImageList;
    ImageCollection1: TImageCollection;
    RepairSigntool1: TMenuItem;
    N7: TMenuItem;
    procedure CheckBoxUseTimestampServiceClick(Sender: TObject);
    procedure BtnHidePasswordClick(Sender: TObject);
    procedure BtnAddFilesClick(Sender: TObject);
    procedure ShowModernRFCTimestampsUrlCollections;
    procedure ShowLegacyTimestampsUrlCollections;
    procedure FixListViewColumnWidth;
    procedure LoadPFXFileDialoge;
    procedure LoadBasicUISettings;
    procedure LoadUIAllStrings;
    procedure AddFilesToSign;
    procedure DisabledEverythingWhileSigning;
    procedure EnableEverythingAfterSign;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PopUpMenuQBS1Popup(Sender: TObject);
    procedure RemoveSelected1Click(Sender: TObject);
    procedure BtnClearAllFilesClick(Sender: TObject);
    procedure BtnSignClick(Sender: TObject);
    procedure BtnLoadPFXClick(Sender: TObject);
    procedure ShowTimestamp1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure EditProductNameExit(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AddFiles1Click(Sender: TObject);
    procedure ChoosePFX1Click(Sender: TObject);
  //  procedure ClearFileLists1Click(Sender: TObject);
    procedure Website1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SgningHashDetection(Sender: TObject);
    procedure DontRemoveOldSignature1Click(Sender: TObject);
    procedure ShowinExplorer1Click(Sender: TObject);
    procedure ShowinFileExplorer;
    procedure EditPfxFileSelect(Sender: TObject);
    procedure ListView1CustomDrawSubItem(Sender: TCustomListView;
      Item: TListItem; SubItem: Integer; State: TCustomDrawState;
      var DefaultDraw: Boolean);
    procedure RepairSigntool1Click(Sender: TObject);
    procedure ListView1CustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure EditTimestampUrlChange(Sender: TObject);
    procedure EditPfxFileExit(Sender: TObject);
  
  private
    FSysImageList: THandle;
    FSignToolBroken: Boolean;
    FFirstError: string;
    FFailedCount: Integer;
      FSigningCancelRequested: Integer;
    FImportProgressLabel: TLabel;
    FImportLastTick: Cardinal;

    procedure CreateImportProgressLabel;
    procedure CenterImportProgressLabel;
    procedure ShowImportProgress(const AText: string);
    procedure HideImportProgress;
    procedure ImportDroppedPaths(const Paths: TArray<string>);
    function IsSignableExtension(const Ext: string): Boolean;

     procedure ScanFolderCollectForImport(const FolderPath: string; Depth: Integer;
    ExistingNames: TDictionary<string, Byte>;
    CollectedEntries: TList<TPair<string, Integer>>);
  procedure ReportImportProgress(const Current, Total: Integer; const Prefix: string);


    procedure AskRepairSigntool;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;

   function RunCommandGetExitCode(const CmdLine: string; out Output: string)
      : Cardinal;
    procedure SignFilesInBackground(const PfxFile, Password, TimeStampURL,
      Description, SignToolPath, DigestAlgo: string;
      const UseTimestampService, DontRemoveOldSignature: Boolean;
      const FilesToSign: TArray<string>);


 //   procedure AddFileToListIfSignable(const FullPath: string);   // <-- notun
//    procedure ScanFolderForSignableFiles(const FolderPath: string; Depth: Integer = 0);

    procedure SetupFileIconList;
    function  GetShellIconIndex(const FileName: string): Integer;
    procedure SetListViewImageList(UseStatusIcons: Boolean);

    procedure LoadRecentPFXIntoCombo;
    procedure LoadCaptionsIntoCombo;
    procedure TryAutoFillPasswordForPFX;
    procedure ConfigureListViewScrollBars;
    procedure SelectAndScrollToItem(Index: Integer);
    procedure SelectTimestampUrlOrDefault(const PreferredUrl: string);
    procedure ReportImportScanProgress(const CollectedCount: Integer);

  public
    { Public declarations }
  end;

var
  FormQBSigner: TFormQBSigner;

implementation

{$R *.dfm}


type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

  TRecentPFXEntry = record
    Path: string;
    EncPass: string;
    LastUsed: string;
  end;


  function CryptProtectData(pDataIn: PDataBlob; szDataDescr: LPCWSTR;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer; pPromptStruct: Pointer;
  dwFlags: DWORD; var pDataOut: TDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer; pPromptStruct: Pointer;
  dwFlags: DWORD; var pDataOut: TDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';


{


}


const
  MyAppName = 'Quick Binaries Signer';
  MyAppVersion = '3.0';
  MyAppPublisher = 'SR Studio 24 - BD';
  MyAppReleaseDate = 'September 26, 2026';
  MyAppUrl = 'https://srstudio24.blogspot.com/';

  SignToolRepairUtilityExeName = 'QBUtility.exe'  ;


  Caption_Queued = 'Queued';     //Done
  Caption_Ready = 'Ready';         //Done
  Caption_Signing = 'Signing';

  Caption_Signed = 'Signed';    //DOne
  Caption_Failed = 'Failed';    //Done
  Caption_Missing = 'Missing';  // Done
  Caption_Aborted = 'Aborted';


  SigningCaption = 'Signing...';
  SignCaption = 'Sign';
  HidePasswordCaption = 'Hide';
  ShowPasswordCaption = 'Show';

  MyRegistryPath = 'Software\SR Studio\Quick Binaries Signer';
  IsTimestampHidden = 'IsTimestampHidden';
  SigningHashDiggest = 'SigningHash';
  ISStayign = 'IsKeepSign';
  LatPFXFolder = 'IsLastPFX';
  LastAddedFilesList = 'IsLastAdded';
  IsHidePassword = 'IsHidePassword';
  UseTimeStampService = 'IsTimestampUse';
  MyHeight = 'Height';
  MyWidth = 'Width';
LastModernTimestampUrl = 'LastModernTimestampUrl';
  LastLegacyTimestampUrl = 'LastLegacyTimestampUrl';

  RecentPFXRegPath = MyRegistryPath + '\Recent';
  CaptionsRegPath  = MyRegistryPath + '\Captions';
  MaxRecentPFXEntries = 15;
  MaxCaptionEntries   = 15;

  AboutMessagesforBinariesSigner = 'Developer: Shohanur Rahman' + slinebreak +
    'Website: https://srstudio24.blogspot.com/' + slinebreak +
    'Whatsapp: +880 1408712154' + slinebreak + slinebreak +
    'Thanks for choosing Quick Binaries Signer.' + slinebreak +
    'For more information, please visit https://srstudio24.blogspot.com/';

  // Messages
  AddFilesDialogeTitle = 'Choose files to sign.';
  AddPFXDialogTitle = 'Choose Certificate file for Signing Binaries.';

  ModernRFCUrls: array [0 .. 9] of string = ('http://ts.ssl.com',
    'http://time.certum.pl', 'http://tsa.swisssign.net',
    'http://timestamp.certum.pl', 'http://timestamp.digicert.com',
    'http://timestamp.comodoca.com', 'http://timestamp.comodoca.com/rfc3161',
    'http://timestamp.entrust.net/TSS/RFC3161sha2TS',
    'http://timestamp.globalsign.com/tsa/r6advanced1',
    'http://rfc3161timestamp.globalsign.com/advanced');

  LegacyUrls: array [0 .. 5] of string = ('http://time.certum.pl',
    'http://timestamp.certum.pl', 'http://timestamp.comodoca.com',
    'http://timestamp.digicert.com',
    'http://timestamp.comodoca.com/authenticode',
    'http://timestamp.globalsign.com/?signature=sha2');

var
  IsSigningInProgress: Boolean = False;
  MyLastTimestampUrlAtRuntime: string;
  OldListViewWndProc: Pointer = nil;
  InScrollBarFix: Boolean = False;
    IsImportingFiles: Boolean = False;

const
  MenuSeparator = '-';

  ICON_IMPORTED   = 0;    //All time icon - imported file
  ICON_READY      = 1;    // while signing
  ICON_SIGNED     = 2;    // if signed
  ICON_FAILED     = 3;    // if failed
  ICON_MISSING    = 4;    // if missing
  ICON_ABORTED    = 5;    // if force stopped

  StatusColWidth = 80;
  HDS_NOSIZE = $0800;

  function GetSignToolPath: string;
var
  LocalPath: string;
begin
  LocalPath := ExtractFilePath(Application.ExeName) + 'signtool.exe';
  if FileExists(LocalPath) then
    Result := LocalPath
  else
    Result := 'signtool.exe';
end;



function GetCurrentTimestampUrlRegKey: string;
begin
  if FormQBSigner.SHAL1.Checked and not FormQBSigner.DontRemoveOldSignature1.Checked then
    Result := LastLegacyTimestampUrl
  else
    Result := LastModernTimestampUrl;
end;

function SignToolExists(const SignToolPath: string): Boolean;
var
  Buffer: array[0..MAX_PATH] of Char;
  FilePart: PChar;
begin
  if ExtractFilePath(SignToolPath) <> '' then
  begin
    Result := FileExists(SignToolPath);
    Exit;
  end;
  FilePart := nil;
  Result := SearchPath(nil, PChar(SignToolPath), nil, MAX_PATH, Buffer, FilePart) <> 0;
end;


function EncryptStringDPAPI(const PlainText: string): string;
var
  InBytes, OutBytes: TBytes;
  DataIn: TDataBlob;
  DataOut: TDataBlob;
begin
  Result := '';
  InBytes := TEncoding.UTF8.GetBytes(PlainText);
  if Length(InBytes) = 0 then
    Exit;

  DataIn.cbData := Length(InBytes);
  DataIn.pbData := @InBytes[0];
  FillChar(DataOut, SizeOf(DataOut), 0);

  if CryptProtectData(@DataIn, 'QBSignerPass', nil, nil, nil, 0, DataOut) then
  begin
    try
      SetLength(OutBytes, DataOut.cbData);
      if DataOut.cbData > 0 then
        Move(DataOut.pbData^, OutBytes[0], DataOut.cbData);
      Result := TNetEncoding.Base64.EncodeBytesToString(OutBytes);
    finally
      if Assigned(DataOut.pbData) then
        LocalFree(HLOCAL(DataOut.pbData));
    end;
  end;
end;

function DecryptStringDPAPI(const CipherTextBase64: string): string;
var
  InBytes, OutBytes: TBytes;
  DataIn: TDataBlob;
  DataOut: TDataBlob;
begin
  Result := '';
  if Trim(CipherTextBase64) = '' then
    Exit;

  try
    InBytes := TNetEncoding.Base64.DecodeStringToBytes(CipherTextBase64);
  except
    Exit;
  end;
  if Length(InBytes) = 0 then
    Exit;

  DataIn.cbData := Length(InBytes);
  DataIn.pbData := @InBytes[0];
  FillChar(DataOut, SizeOf(DataOut), 0);

  if CryptUnprotectData(@DataIn, nil, nil, nil, nil, 0, DataOut) then
  begin
    try
      SetLength(OutBytes, DataOut.cbData);
      if DataOut.cbData > 0 then
        Move(DataOut.pbData^, OutBytes[0], DataOut.cbData);
      Result := TEncoding.UTF8.GetString(OutBytes);
    finally
      if Assigned(DataOut.pbData) then
        LocalFree(HLOCAL(DataOut.pbData));
    end;
  end;
end;

 function CompareRegistryIndexNames(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := StrToIntDef(List[Index1], 0) - StrToIntDef(List[Index2], 0);
end;

function LoadRecentPFXEntries: TArray<TRecentPFXEntry>;
var
  Reg: TRegistry;
  Names: TStringList;
  i: Integer;
  RawValue: string;
  Parts: TArray<string>;
  List: TList<TRecentPFXEntry>;
  Entry: TRecentPFXEntry;
begin
  List := TList<TRecentPFXEntry>.Create;
  Reg := TRegistry.Create(KEY_READ);
  Names := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(RecentPFXRegPath) then
    begin
      Reg.GetValueNames(Names);
      Names.CustomSort(CompareRegistryIndexNames);
      for i := 0 to Names.Count - 1 do
      begin
        RawValue := Reg.ReadString(Names[i]);
        Parts := RawValue.Split(['|']);
        if Length(Parts) >= 3 then
        begin
          Entry.Path     := Parts[0];
          Entry.EncPass  := Parts[1];
          Entry.LastUsed := Parts[2];
          List.Add(Entry);
        end;
      end;
      Reg.CloseKey;
    end;
    Result := List.ToArray;
  finally
    List.Free;
    Names.Free;
    Reg.Free;
  end;
end;

procedure SaveRecentPFXEntries(const Entries: TArray<TRecentPFXEntry>);
var
  Reg: TRegistry;
  Names: TStringList;
  i, CountToWrite: Integer;
begin
  Reg := TRegistry.Create(KEY_WRITE or KEY_READ);
  Names := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(RecentPFXRegPath, True) then
    begin
      // পুরনো সব value মুছে ফেলো, তারপর নতুন করে ordered index দিয়ে লিখবো
      Reg.GetValueNames(Names);
      for i := 0 to Names.Count - 1 do
        Reg.DeleteValue(Names[i]);

      CountToWrite := Length(Entries);
      if CountToWrite > MaxRecentPFXEntries then
        CountToWrite := MaxRecentPFXEntries;

      for i := 0 to CountToWrite - 1 do
        Reg.WriteString(IntToStr(i + 1),
          Entries[i].Path + '|' + Entries[i].EncPass + '|' + Entries[i].LastUsed);

      Reg.CloseKey;
    end;
  finally
    Names.Free;
    Reg.Free;
  end;
end;


function EscapeCmdArg(const S: string): string;
var
  i, BackSlashes: Integer;
  C: Char;
begin
  Result := '"';
  BackSlashes := 0;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    if C = '\' then
      Inc(BackSlashes)
    else if C = '"' then
    begin
      Result := Result + StringOfChar('\', BackSlashes * 2 + 1) + '"';
      BackSlashes := 0;
    end
    else
    begin
      Result := Result + StringOfChar('\', BackSlashes) + C;
      BackSlashes := 0;
    end;
  end;
  Result := Result + StringOfChar('\', BackSlashes * 2) + '"';
end;



function CleanSignToolOutput(const RawOutput: string): string;
const
  SignAttemptPrefix = 'SignTool Error: An error occurred while attempting to sign:';
var
  Lines, ResultLines: TStringList;
  i: Integer;
  LineText: string;
begin
  Lines := TStringList.Create;
  ResultLines := TStringList.Create;
  try
    Lines.Text := RawOutput;

    i := 0;
    while i < Lines.Count do
    begin
      LineText := Trim(Lines[i]);

      if (LineText = '') or
         SameText(LineText, 'Done Adding Additional Store') or
         (Pos('Number of errors:', LineText) = 1) or
         (Pos('Number of warnings:', LineText) = 1) then
      begin
        Inc(i);
        Continue;
      end;
      if Pos(SignAttemptPrefix, LineText) = 1 then
      begin
        Inc(i);           // ei line bad
        if i < Lines.Count then
          Inc(i);         // porer line-o (file path) bad
        Continue;
      end;

      ResultLines.Add(Lines[i]);
      Inc(i);
    end;

    Result := Trim(ResultLines.Text);
  finally
    ResultLines.Free;
    Lines.Free;
  end;
end;




procedure UpsertRecentPFX(const PfxPath, PlainPassword: string);
var
  OldEntries: TArray<TRecentPFXEntry>;
  NewList: TList<TRecentPFXEntry>;
  NewEntry: TRecentPFXEntry;
  i: Integer;
begin
  OldEntries := LoadRecentPFXEntries;
  NewList := TList<TRecentPFXEntry>.Create;
  try
    NewEntry.Path     := PfxPath;
    NewEntry.EncPass  := EncryptStringDPAPI(PlainPassword);
    NewEntry.LastUsed := FormatDateTime('yyyymmddhhnnss', Now);
    NewList.Add(NewEntry);   // সবচেয়ে recent টা সবার উপরে

    // পুরনো লিস্ট থেকে একই Path বাদ দিয়ে বাকিগুলো যোগ করো (duplicate এড়াতে)
    for i := 0 to High(OldEntries) do
      if not SameText(OldEntries[i].Path, PfxPath) then
        NewList.Add(OldEntries[i]);

    SaveRecentPFXEntries(NewList.ToArray);
  finally
    NewList.Free;
  end;
end;


function LoadCaptionEntries: TArray<string>;
var
  Reg: TRegistry;
  Names: TStringList;
  i: Integer;
  List: TList<string>;
begin
  List := TList<string>.Create;
  Reg := TRegistry.Create(KEY_READ);
  Names := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(CaptionsRegPath) then
    begin
      Reg.GetValueNames(Names);
      Names.CustomSort(CompareRegistryIndexNames);
      for i := 0 to Names.Count - 1 do
        List.Add(Reg.ReadString(Names[i]));
      Reg.CloseKey;
    end;
    Result := List.ToArray;
  finally
    List.Free;
    Names.Free;
    Reg.Free;
  end;
end;

procedure SaveCaptionEntries(const Entries: TArray<string>);
var
  Reg: TRegistry;
  Names: TStringList;
  i, CountToWrite: Integer;
begin
  Reg := TRegistry.Create(KEY_WRITE or KEY_READ);
  Names := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(CaptionsRegPath, True) then
    begin
      Reg.GetValueNames(Names);
      for i := 0 to Names.Count - 1 do
        Reg.DeleteValue(Names[i]);

      CountToWrite := Length(Entries);
      if CountToWrite > MaxCaptionEntries then
        CountToWrite := MaxCaptionEntries;

      for i := 0 to CountToWrite - 1 do
        Reg.WriteString(IntToStr(i + 1), Entries[i]);

      Reg.CloseKey;
    end;
  finally
    Names.Free;
    Reg.Free;
  end;
end;

procedure UpsertCaption(const NewCaption: string);
var
  OldEntries: TArray<string>;
  NewList: TList<string>;
  i: Integer;
begin
  if Trim(NewCaption) = '' then
    Exit; // খালি caption history-তে রাখার দরকার নেই

  OldEntries := LoadCaptionEntries;
  NewList := TList<string>.Create;
  try
    NewList.Add(NewCaption);
    for i := 0 to High(OldEntries) do
      if not SameText(OldEntries[i], NewCaption) then
        NewList.Add(OldEntries[i]);

    SaveCaptionEntries(NewList.ToArray);
  finally
    NewList.Free;
  end;
end;




function ListViewSubclassWndProc(Wnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall;
var
  StyleInfo: PStyleStruct;
begin
  case Msg of
     WM_STYLECHANGING:
      begin
        if NativeInt(wParam) = GWL_STYLE then
        begin
          StyleInfo := PStyleStruct(lParam);
          StyleInfo.styleNew := (StyleInfo.styleNew or WS_VSCROLL) and not WS_HSCROLL;
        end;
        Result := CallWindowProc(OldListViewWndProc, Wnd, Msg, wParam, lParam);
        Exit;
      end;

    WM_SIZE, WM_WINDOWPOSCHANGED:
      begin
        Result := CallWindowProc(OldListViewWndProc, Wnd, Msg, wParam, lParam);

        // Recursion thekano - jodi already fix cholteche, abar dhukbo na
        if not InScrollBarFix then
        begin
          InScrollBarFix := True;
          try
            ShowScrollBar(Wnd, SB_HORZ, False); // shudhu eituku, SetWindowPos na
          finally
            InScrollBarFix := False;
          end;
        end;
        Exit;
      end;

    WM_NCDESTROY:
      begin
        Result := CallWindowProc(OldListViewWndProc, Wnd, Msg, wParam, lParam);
        SetWindowLongPtr(Wnd, GWL_WNDPROC, NativeInt(OldListViewWndProc));
        OldListViewWndProc := nil;
        Exit;
      end;
  end;

  Result := CallWindowProc(OldListViewWndProc, Wnd, Msg, wParam, lParam);
end;



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

procedure RemoveRecentPFX(const PfxPath: string);
var
  OldEntries: TArray<TRecentPFXEntry>;
  NewList: TList<TRecentPFXEntry>;
  i: Integer;
begin
  OldEntries := LoadRecentPFXEntries;
  NewList := TList<TRecentPFXEntry>.Create;
  try
    for i := 0 to High(OldEntries) do
      if not SameText(OldEntries[i].Path, PfxPath) then
        NewList.Add(OldEntries[i]);

    SaveRecentPFXEntries(NewList.ToArray);
  finally
    NewList.Free;
  end;
end;







///////////////////////////////MAIN FORM///////////////////////////////
procedure TFormQBSigner.About1Click(Sender: TObject);

var
  SignToolVersion: string;
begin
        SignToolVersion:=GetFileVersion(GetSignToolPath);


    if SignToolVersion<>'' then
    Application.MessageBox(PChar(MyAppName + slinebreak + 'Version: ' +
    MyAppVersion + slinebreak +
    'Signtool Version: '+SignToolVersion+sLineBreak+
    'Publisher: ' + MyAppPublisher + slinebreak +
    'Release date: ' + MyAppReleaseDate + slinebreak + slinebreak +

    AboutMessagesforBinariesSigner), PChar(MyAppName),
    MB_OK or MB_ICONINFORMATION)
    // if signtool version not found
    else
    Application.MessageBox(PChar(MyAppName + slinebreak + 'Version: ' +
    MyAppVersion + slinebreak +
    'Publisher: ' + MyAppPublisher + slinebreak +
    'Release date: ' + MyAppReleaseDate + slinebreak + slinebreak +
    AboutMessagesforBinariesSigner), PChar(MyAppName),
    MB_OK or MB_ICONINFORMATION)
end;




  procedure TFormQBSigner.LoadRecentPFXIntoCombo;
var
  Entries: TArray<TRecentPFXEntry>;
  i: Integer;
  SavedText: string;
begin
  SavedText := EditPfxFile.Text;
  EditPfxFile.Items.Clear;
  Entries := LoadRecentPFXEntries;
  for i := 0 to High(Entries) do
    EditPfxFile.Items.Add(Entries[i].Path);
  EditPfxFile.Text := SavedText; // clear করার পর user-এর current text হারিয়ে না যায়
end;

procedure TFormQBSigner.LoadCaptionsIntoCombo;
var
  Entries: TArray<string>;
  i: Integer;
  SavedText: string;
begin
  SavedText := EditProductName.Text;
  EditProductName.Items.Clear;
  Entries := LoadCaptionEntries;
  for i := 0 to High(Entries) do
    EditProductName.Items.Add(Entries[i]);
  EditProductName.Text := SavedText;
end;

procedure TFormQBSigner.TryAutoFillPasswordForPFX;
var
  Entries: TArray<TRecentPFXEntry>;
  i: Integer;
  CurrentPath: string;
begin
  CurrentPath := Trim(EditPfxFile.Text);
  if CurrentPath = '' then
    Exit;

  Entries := LoadRecentPFXEntries;
  for i := 0 to High(Entries) do
  begin
    if SameText(Entries[i].Path, CurrentPath) then
    begin
      if EditPFXPassword.PasswordChar = #0 then
      begin
        EditPFXPassword.PasswordChar := '*';
        BtnHidePassword.Caption := ShowPasswordCaption;
     //   WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, IsHidePassword, 1)
      end;

      EditPFXPassword.Text := DecryptStringDPAPI(Entries[i].EncPass);
      Exit;
    end;
  end;
end;














procedure TFormQBSigner.AddFilesToSign;
var
  i, j: Integer;
  Item: TListItem;
//  FileAlreadyExists: Boolean;
  Existing: TDictionary<string, Byte>;
  Key: string;
  LastPathForFilesList, NewFile: string;
  OpenDlg: TFileOpenDialog;
  FileTypeItem: TFileTypeItem;
begin
    SetListViewImageList(False);
  LastPathForFilesList := ReadRegistryStringsForSettings(HKEY_CURRENT_USER,
    MyRegistryPath, LastAddedFilesList);

  OpenDlg := TFileOpenDialog.Create(nil);
  try
    OpenDlg.Options := OpenDlg.Options + [fdoAllowMultiSelect, fdoFileMustExist,
      fdoForceFileSystem];
    OpenDlg.Title := AddFilesDialogeTitle;

   OpenDlg.FileTypes.Clear;

        // All Signable Files (merged)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'All Signable Files (*.exe; *.dll; *.msi; *.msp; *.ocx; *.sys; *.cpl; *.drv; *.cat; *.vbs; *.xpi; *.msix; *.msixbundle; *.appx; *.appxbundle; *.ax; *.efi; *.scr; *.pyd)';
        FileTypeItem.FileMask := '*.exe;*.dll;*.msi;*.msp;*.ocx;*.sys;*.cpl;*.drv;*.cat;*.vbs;*.xpi;*.msix;*.msixbundle;*.appx;*.appxbundle;*.ax;*.efi;*.scr;*.pyd';

        // Executables (.exe, .scr)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Executable Files (*.exe)';
        FileTypeItem.FileMask := '*.exe';

               // Installers (.msi, .msp)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Installer Packages (*.msi; *.msp)';
        FileTypeItem.FileMask := '*.msi;*.msp';



        // Libraries and Controls (.dll, .ocx, .ax)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Libraries and Controls (*.dll; *.ocx; *.ax)';
        FileTypeItem.FileMask := '*.dll;*.ocx;*.ax';


        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Screensaver File (*.scr)';
        FileTypeItem.FileMask := '*.scr';



        // App Packages (.msix, .msixbundle)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'MSIX Packages (*.msix; *.msixbundle)';
        FileTypeItem.FileMask := '*.msix;*.msixbundle';

        // App Packages (.appx, .appxbundle)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'APPX Packages (*.appx; *.appxbundle)';
        FileTypeItem.FileMask := '*.appx;*.appxbundle';

        // System Drivers (.sys, .cpl, .drv, .efi)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'System Files and Drivers (*.sys; *.cpl; *.drv; *.efi)';
        FileTypeItem.FileMask := '*.sys;*.cpl;*.drv;*.efi';


        // Catalog files
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Catalog Files (*.cat)';
        FileTypeItem.FileMask := '*.cat';

        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Python Extension (*.pyd)';
        FileTypeItem.FileMask := '*.pyd';
        // Script & Web Files (.vbs, .xpi)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'Scripts and Web Extensions (*.vbs; *.xpi)';
        FileTypeItem.FileMask := '*.vbs;*.xpi';

         // Script & Web Files (.vbs, .xpi)
        FileTypeItem := OpenDlg.FileTypes.Add;
        FileTypeItem.DisplayName := 'All Files (*.*)';
        FileTypeItem.FileMask := '*.*';


    // Set default folder if saved
    if LastPathForFilesList <> '' then
      OpenDlg.DefaultFolder := LastPathForFilesList;

        if OpenDlg.Execute then
    begin
      Existing := TDictionary<string, Byte>.Create;
      try
        for j := 0 to ListView1.Items.Count - 1 do
          Existing.AddOrSetValue(LowerCase(ListView1.Items[j].Caption), 0);

        ListView1.Items.BeginUpdate;
        try
          for i := 0 to OpenDlg.Files.Count - 1 do
          begin
            NewFile := OpenDlg.Files[i];
            Key := LowerCase(NewFile);
            if not Existing.ContainsKey(Key) then
            begin
              Existing.Add(Key, 0);
              Item := ListView1.Items.Add;
              Item.Caption := NewFile;
              Item.ImageIndex := GetShellIconIndex(NewFile);
              Item.SubItems.Add(Caption_Queued);
            end;
          end;
        finally
          ListView1.Items.EndUpdate;
        end;
      finally
        Existing.Free;
      end;

      if OpenDlg.Files.Count > 0 then
        WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
          LastAddedFilesList, ExtractFileDir(OpenDlg.Files[0]));
    end;
  finally
    OpenDlg.Free;
  end;
  FixListViewColumnWidth;
end;



procedure TFormQBSigner.BtnAddFilesClick(Sender: TObject);
begin

  AddFilesToSign;

end;

procedure TFormQBSigner.BtnHidePasswordClick(Sender: TObject);
begin
  if EditPFXPassword.PasswordChar = #0 then
  begin
    EditPFXPassword.PasswordChar := '*';
    BtnHidePassword.Caption := ShowPasswordCaption;
    WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath,
      IsHidePassword, 1)
  end
  else if EditPFXPassword.PasswordChar = '*' then
  begin
    EditPFXPassword.PasswordChar := #0;
    BtnHidePassword.Caption := HidePasswordCaption;
    WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath,
      IsHidePassword, 0)
  end;

end;




procedure TFormQBSigner.BtnLoadPFXClick(Sender: TObject);
begin
  LoadPFXFileDialoge;
end;

procedure TFormQBSigner.BtnSignClick(Sender: TObject);
var
  PfxFile, Password, TimeStampURL, Description, SignToolPath, DigestAlgo: string;
  UseTimestampService, DontRemoveOldSignature: Boolean;
  FilesToSign: TArray<string>;
  i: Integer;
begin
  PfxFile := Trim(EditPfxFile.Text);
  Password := EditPFXPassword.Text;
  TimeStampURL := Trim(EditTimestampUrl.Text);
  Description := Trim(EditProductName.Text);
  SignToolPath := GetSignToolPath;

    if not FileExists(PfxFile) then
  begin
    RemoveRecentPFX(PfxFile);
    LoadRecentPFXIntoCombo;
    Application.MessageBox('The selected PFX file does not exist and was removed from the recent list.',
      PChar(MyAppName), MB_OK or MB_ICONWARNING);
    Exit;
  end;

      {
  if Password = '' then
  begin
    Application.MessageBox('Password required for the selected PFX file.',
      PChar(MyAppName), MB_OK or MB_ICONSTOP);
    Exit;
  end;        }

  if not SignToolExists(SignToolPath) then
  begin
    Application.MessageBox('Required file "signtool.exe" was not found.' + sLineBreak +
      'Please repair the "signtool.exe" or obtain a new copy and place it in the program''s installation folder.',
      'Error - signtool.exe', MB_OK or MB_ICONSTOP);
    Exit;
  end;

  if CheckBoxUseTimestampService.Checked and
    not TimeStampURL.StartsWith('http') then
  begin
    Application.MessageBox('Invalid timestamp server URL.', 'Warning',
      MB_OK or MB_ICONWARNING);
    Exit;
  end;

  if ListView1.Items.Count = 0 then
  begin
    Application.MessageBox('File list is empty. Nothing to sign.',
      'Warning', MB_OK or MB_ICONWARNING);
    Exit;
  end;

   // Notun signing shuru korar age shob row "Ready"-te set
  for i := 0 to ListView1.Items.Count - 1 do
  begin
    if ListView1.Items[i].SubItems.Count > 0 then
      ListView1.Items[i].SubItems[0] := Caption_Ready;
  end;
  ListView1.Invalidate;

  // Background thread VCL control touch korbe na, tai UI state ekhane capture
  if SHAL1.Checked then
    DigestAlgo := 'sha1'
  else
    DigestAlgo := 'sha256';
  UseTimestampService := CheckBoxUseTimestampService.Checked;
  DontRemoveOldSignature := DontRemoveOldSignature1.Checked;

  SetLength(FilesToSign, ListView1.Items.Count);
  for i := 0 to ListView1.Items.Count - 1 do
    FilesToSign[i] := ListView1.Items[i].Caption;

  FSignToolBroken := False;
  FFirstError := '';
  FFailedCount := 0;

  InterlockedExchange(FSigningCancelRequested, 0);

  IsSigningInProgress := True;
  DisabledEverythingWhileSigning;

  TTask.Run(
    procedure
    var
      ErrMsg: string;
    begin
      ErrMsg := '';
      try
        SignFilesInBackground(PfxFile, Password, TimeStampURL, Description,
          SignToolPath, DigestAlgo, UseTimestampService, DontRemoveOldSignature,
          FilesToSign);
      except
        on E: Exception do
          ErrMsg := E.Message;
      end;



       TThread.Synchronize(nil,
        procedure
        var
          Msg: string;
        begin
          EnableEverythingAfterSign;
          IsSigningInProgress := False;

          if FSignToolBroken then
            AskRepairSigntool
          else if ErrMsg <> '' then
            Application.MessageBox(
              PChar('Unexpected error while signing:' + sLineBreak + ErrMsg),
              PChar(MyAppName), MB_OK or MB_ICONERROR)
             else if FFailedCount > 0 then
              begin
                Msg := '';
                if FFirstError <> '' then
                begin
                  if Length(FFirstError) > 800 then
                    FFirstError := Copy(FFirstError, 1, 800) + '...';
                  Msg := sLineBreak + sLineBreak + FFirstError;
                end;
                Msg := Format('%d file(s) failed to sign.', [FFailedCount]) + Msg;
                Application.MessageBox(PChar(Msg), PChar(MyAppName),
                  MB_OK or MB_ICONWARNING);
              end;
        end);
    end);
end;


procedure TFormQBSigner.BtnClearAllFilesClick(Sender: TObject);
begin
 SetListViewImageList(False);
  ListView1.Clear;
  FixListViewColumnWidth;
end;

procedure TFormQBSigner.CenterImportProgressLabel;
begin
  if not Assigned(FImportProgressLabel) then Exit;
  FImportProgressLabel.SetBounds(0, (ListView1.ClientHeight - 40) div 2,
    ListView1.ClientWidth, 40);
end;

procedure TFormQBSigner.CheckBoxUseTimestampServiceClick(Sender: TObject);
var
  LastUrl: string;
begin
  if EditTimestampUrl.Text <> '' then
  begin
    MyLastTimestampUrlAtRuntime := EditTimestampUrl.Text;
    WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
      GetCurrentTimestampUrlRegKey, EditTimestampUrl.Text);
  end;

  if CheckBoxUseTimestampService.Checked then
  begin
    if DontRemoveOldSignature1.Checked then
      ShowModernRFCTimestampsUrlCollections
    else if SHAL1.Checked then
      ShowLegacyTimestampsUrlCollections
    else
      ShowModernRFCTimestampsUrlCollections;

    LastUrl := ReadRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath, GetCurrentTimestampUrlRegKey);   // <-- list switch howar POR shothik key porhte hobe
    SelectTimestampUrlOrDefault(LastUrl);
    EditTimestampUrl.Enabled := True;
  end
  else
  begin
    EditTimestampUrl.Enabled := False;
    EditTimestampUrl.ItemIndex := -1;

  end;
end;



procedure TFormQBSigner.ConfigureListViewScrollBars;
var
  HeaderHandle: HWND;
  HeaderStyle: NativeInt;
  CurStyle: NativeInt;
begin
  if not ListView1.HandleAllocated then Exit;
  if not Assigned(OldListViewWndProc) then
  begin
    OldListViewWndProc := Pointer(GetWindowLongPtr(ListView1.Handle, GWL_WNDPROC));
    SetWindowLongPtr(ListView1.Handle, GWL_WNDPROC,
      NativeInt(@ListViewSubclassWndProc));
  end;

  CurStyle := GetWindowLongPtr(ListView1.Handle, GWL_STYLE);
  CurStyle := (CurStyle or WS_VSCROLL) and not WS_HSCROLL;
  SetWindowLongPtr(ListView1.Handle, GWL_STYLE, CurStyle);

  ShowScrollBar(ListView1.Handle, SB_VERT, True);
  ShowScrollBar(ListView1.Handle, SB_HORZ, False);

  HeaderHandle := SendMessage(ListView1.Handle, LVM_GETHEADER, 0, 0);
  if HeaderHandle <> 0 then
  begin
    HeaderStyle := GetWindowLongPtr(HeaderHandle, GWL_STYLE);
    if (HeaderStyle and HDS_NOSIZE) = 0 then
      SetWindowLongPtr(HeaderHandle, GWL_STYLE, HeaderStyle or HDS_NOSIZE);
  end;
end;

procedure TFormQBSigner.CreateImportProgressLabel;
begin
  FImportProgressLabel := TLabel.Create(Self);
  FImportProgressLabel.Parent := ListView1;   // ListView-er child, tai upore bhashbe
  FImportProgressLabel.AutoSize := False;
  FImportProgressLabel.Alignment := taCenter;
  FImportProgressLabel.Layout := tlCenter;
  FImportProgressLabel.Font.Size := 12;
  FImportProgressLabel.Font.Style := [fsBold];
  FImportProgressLabel.Color := clWindow;
  FImportProgressLabel.Visible := False;
end;

procedure TFormQBSigner.DisabledEverythingWhileSigning;
begin

  ChoosePFX1.Enabled := False;
  AddFiles1.Enabled := False;
 // ClearFileLists1.Enabled := False;
  DontRemoveOldSignature1.Enabled := False;
  ShowTimestamp1.Enabled := False;
  SHAL1.Enabled:=False;
  SHAM2.Enabled:=False;

  EditPfxFile.Enabled := False;
  EditPFXPassword.Enabled := False;
  BtnLoadPFX.Enabled := False;
  BtnHidePassword.Enabled := False;
  EditProductName.Enabled := False;
  CheckBoxUseTimestampService.Enabled := False;

  EditTimestampUrl.Enabled := False;
  



  RemoveSelected1.Enabled := False;
  BtnAddFiles.Enabled := False;
  BtnClearAllFiles.Enabled := False;
  BtnSign.Enabled := False;
  BtnSign.Caption := SigningCaption;

  ProgressBar1.Style := pbstMarquee;
  ProgressBar1.MarqueeInterval := 50;
  ProgressBar1.Visible := True;
end;










procedure TFormQBSigner.DontRemoveOldSignature1Click(Sender: TObject);
begin
  DontRemoveOldSignature1.Checked := not DontRemoveOldSignature1.Checked;
  if CheckBoxUseTimestampService.Checked then
  begin
    if DontRemoveOldSignature1.Checked then
      ShowModernRFCTimestampsUrlCollections
    else if SHAL1.Checked then
      ShowLegacyTimestampsUrlCollections
    else
      ShowModernRFCTimestampsUrlCollections;

    SelectTimestampUrlOrDefault(ReadRegistryStringsForSettings(HKEY_CURRENT_USER,
      MyRegistryPath, GetCurrentTimestampUrlRegKey));   // <-- 0 er bodole
  end;
end;



procedure TFormQBSigner.EditPfxFileExit(Sender: TObject);
begin
TryAutoFillPasswordForPFX;
end;

procedure TFormQBSigner.EditPfxFileSelect(Sender: TObject);
begin
 TryAutoFillPasswordForPFX;
end;

procedure TFormQBSigner.EditProductNameExit(Sender: TObject);
begin
  if Trim(EditProductName.Text) = '' then
    EditProductName.Clear;
end;



procedure TFormQBSigner.EditTimestampUrlChange(Sender: TObject);
begin
 if CheckBoxUseTimestampService.Checked and (EditTimestampUrl.Text <> '') then
  begin
    MyLastTimestampUrlAtRuntime := EditTimestampUrl.Text;
    WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
      GetCurrentTimestampUrlRegKey, EditTimestampUrl.Text);
  end;
end;

procedure TFormQBSigner.EnableEverythingAfterSign;
begin

  ChoosePFX1.Enabled := True;
  AddFiles1.Enabled := True;
//  ClearFileLists1.Enabled := True;
  DontRemoveOldSignature1.Enabled := True;
  ShowTimestamp1.Enabled := True;
  SHAL1.Enabled:=True;
  SHAM2.Enabled:=True;

  EditPfxFile.Enabled := True;
  EditPFXPassword.Enabled := True;
  BtnLoadPFX.Enabled := True;
  BtnHidePassword.Enabled := True;
  EditProductName.Enabled := True;
  CheckBoxUseTimestampService.Enabled := True;
  EditTimestampUrl.Enabled := CheckBoxUseTimestampService.Checked;
  RemoveSelected1.Enabled := True;
  BtnAddFiles.Enabled := True;
  BtnClearAllFiles.Enabled := True;
  BtnSign.Enabled := True;
  BtnSign.Caption := SignCaption;
  ProgressBar1.Visible := False;
  ProgressBar1.Style := pbstNormal;
  ListView1.Align:=alClient;
end;

procedure TFormQBSigner.Exit1Click(Sender: TObject);
begin
 Close;
end;

procedure TFormQBSigner.FixListViewColumnWidth;
begin//age off/on koro, tahole ClientWidth thik hishab hobe

  if ListView1.Columns.Count > 1 then
  begin
    ListView1.Columns[1].Width := StatusColWidth;                 // fixed
    ListView1.Columns[0].Width := ListView1.ClientWidth - StatusColWidth; // stretch
  end
  else if ListView1.Columns.Count > 0 then
    ListView1.Columns[0].Width := ListView1.ClientWidth;

  ConfigureListViewScrollBars;
end;
procedure TFormQBSigner.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  if IsSigningInProgress or IsImportingFiles then
  begin
    if IsSigningInProgress then
      Application.MessageBox('Signing in progress. Please wait until it finishes before closing.',
        PChar(MyAppName), MB_OK or MB_ICONWARNING)
    else
      Application.MessageBox('Importing files. Please wait until it finishes before closing.',
        PChar(MyAppName), MB_OK or MB_ICONWARNING);
    Action := caNone;
    Exit;
  end;

 //Use Timestamp
   if CheckBoxUseTimestampService.Checked then
   WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, UseTimeStampService, 1) else
   WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, UseTimeStampService, 0);

//Timestamp  Hidden
if TimestampGrpBox.Visible = False then
 WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath,IsTimestampHidden, 1) else
 WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath,IsTimestampHidden, 0);



 //Signing Hash
 if SHAM2.Checked then
  WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, SigningHashDiggest, 1)
  else
  WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, SigningHashDiggest, 0);

 //Do not Remove Old Signature
  if DontRemoveOldSignature1.Checked then
  WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, ISStayign, 1) else
  WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, ISStayign, 0);

//Form Size
  if WindowState = TWindowState.wsMaximized then
  else
  begin
    WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath, MyHeight,
      IntToStr(Height));
    WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath, MyWidth,
      IntToStr(Width));
  end;


end;

procedure TFormQBSigner.FormCreate(Sender: TObject);
begin

//  Clipboard.AsText:=CalculateUniversalResourceHash('TFORMQBSIGNER', RT_RCDATA);

 SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);

  IsSigningInProgress:=False;
  FSigningCancelRequested := 0;
  KeyPreview:=True;
  DragAcceptFiles(Handle, True);
  ListView1.ShowHint := True;
  ConfigureListViewScrollBars;
  FixListViewColumnWidth;
  CreateImportProgressLabel;
  SetupFileIconList;
  LoadUIAllStrings;
  LoadBasicUISettings;

  LoadRecentPFXIntoCombo;
  LoadCaptionsIntoCombo;

end;




procedure TFormQBSigner.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
begin

  // Escape must always work, even when an Edit or ComboBox has focus.
  if Key = VK_ESCAPE then
  begin
    if IsSigningInProgress then
    begin
      // Request a graceful stop.
      // The currently running signtool.exe will NOT be terminated.
      InterlockedExchange(FSigningCancelRequested, 1);

      // Let the user know that the current file will finish first.
      TThread.Queue(nil,
        procedure
        begin
          if IsSigningInProgress then
          begin
            BtnSign.Caption := 'Stopping...';
            BtnSign.Enabled := False;
          end;
        end);

      Key := 0;
      Exit;
    end;

    // Normal Escape behavior when not signing.
    ListView1.ClearSelection;
    Key := 0;
    Exit;
  end;

  // If any edit has focus, skip other shortcuts.
  if (ActiveControl is TCustomEdit) or
     (ActiveControl is TCustomComboBox) then
    Exit;

  // Ctrl + A -> Select All
  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    for i := 0 to ListView1.Items.Count - 1 do
      ListView1.Items[i].Selected := True;

    Key := 0;
    Exit;
  end;

  // Ctrl + D or Delete -> Delete selected
  if (((Key = Ord('D')) and (ssCtrl in Shift)) or
      (Key = VK_DELETE)) then
  begin
   if IsSigningInProgress or IsImportingFiles then
    begin
      Key := 0;
      Exit;
    end;

    for i := ListView1.Items.Count - 1 downto 0 do
    begin
      if ListView1.Items[i].Selected then
        ListView1.Items.Delete(i);
    end;

    Key := 0;
    Exit;
  end;
end;




procedure TFormQBSigner.FormResize(Sender: TObject);
begin
   FixListViewColumnWidth;
    ShowScrollBar(ListView1.Handle, SB_HORZ, False);
     CenterImportProgressLabel;
end;



procedure TFormQBSigner.ListView1CustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  StatusText: string;
begin
  StatusText := '';
  if Item.SubItems.Count > 0 then
    StatusText := Item.SubItems[0];

  if SameText(StatusText, Caption_Failed) then
  begin
    Sender.Canvas.Font.Color := clRed;
    Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut, fsItalic];
  end
  else if SameText(StatusText, Caption_Missing) then
  begin
    Sender.Canvas.Font.Color := clGray;
    Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut] + [fsItalic];
  end
  else if SameText(StatusText, Caption_Aborted) then
  begin
    Sender.Canvas.Font.Color := clWindowText;
    Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut] + [fsItalic];
  end
  else
  begin
    Sender.Canvas.Font.Color := clWindowText;
    Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut, fsItalic];
  end;

  DefaultDraw := True;
end;



procedure TFormQBSigner.ListView1CustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
const
  IconPadding = 4;
var
  StatusText: string;
  IconIdx: Integer;
  R: TRect;
  IconLeft, IconTop, TextLeft, IconSize: Integer;

  // স্ট্যাটাস অনুযায়ী ফন্ট সেট করে (ফাইলের নাম ও স্ট্যাটাস দুই কলামেই একই নিয়ম)
  procedure ApplyRowFont(const AStatus: string);
  begin
    if SameText(AStatus, Caption_Failed) then
    begin
      Sender.Canvas.Font.Color := clRed;
      Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut, fsItalic];
    end
    else if SameText(AStatus, Caption_Missing) then
    begin
      Sender.Canvas.Font.Color := clGray;
      Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut] + [fsItalic];
    end
    else if SameText(AStatus, Caption_Aborted) then
    begin
      Sender.Canvas.Font.Color := clWindowText;
      Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut] + [fsItalic];
    end
    else
    begin
      Sender.Canvas.Font.Color := clWindowText;
      Sender.Canvas.Font.Style := Sender.Canvas.Font.Style - [fsStrikeOut, fsItalic];
    end;
  end;

begin
  DefaultDraw := True;

  if Item.SubItems.Count = 0 then
    Exit;
  StatusText := Item.SubItems[0];

  // কলাম 0 = ফাইলের নাম: শুধু ফন্ট সেট, ড্র ডিফল্টই থাকবে
  if SubItem = 0 then
  begin
    ApplyRowFont(StatusText);
    Exit;
  end;

  // কলাম 1 = Status: আইকনসহ নিজে আঁকা হবে
  if SubItem <> 1 then
    Exit;

  if SameText(StatusText, Caption_Signed) then
    IconIdx := ICON_SIGNED
  else if SameText(StatusText, Caption_Failed) then
    IconIdx := ICON_FAILED
  else if SameText(StatusText, Caption_Signing) then
    IconIdx := ICON_READY         // শুধু সাইন হওয়ার সময় (index 1)
  else if SameText(StatusText, Caption_Queued) then
    IconIdx := ICON_IMPORTED      // import করা ফাইল (index 0)
  else if SameText(StatusText, Caption_Ready) then
    IconIdx := ICON_IMPORTED      // Sign চাপার পরও index 0
  else if SameText(StatusText, Caption_Aborted) then
    IconIdx := ICON_ABORTED
  else if SameText(StatusText, Caption_Missing) then
    IconIdx := ICON_MISSING
  else
    Exit;

  DefaultDraw := False;
  ApplyRowFont(StatusText);

  R.Left := LVIR_BOUNDS;
  R.Top := SubItem;
  SendMessage(ListView1.Handle, LVM_GETSUBITEMRECT, Item.Index, LPARAM(@R));

  // Icon draw
  IconSize := VirtualImageList1.Width;
  IconLeft := R.Left + IconPadding;
  IconTop  := R.Top + ((R.Bottom - R.Top - IconSize) div 2);
  if IconTop < R.Top then
    IconTop := R.Top;

  VirtualImageList1.Draw(ListView1.Canvas, IconLeft, IconTop, IconIdx);

  TextLeft := IconLeft + IconSize + IconPadding;

  ListView1.Canvas.Brush.Style := bsClear;
  ListView1.Canvas.TextOut(TextLeft,
    R.Top + ((R.Bottom - R.Top - ListView1.Canvas.TextHeight(StatusText)) div 2),
    StatusText);
  ListView1.Canvas.Brush.Style := bsSolid;
end;



procedure TFormQBSigner.LoadBasicUISettings;
  Var GotedHeight, GotedWidth: Integer;
  begin
  Constraints.MinWidth := 360;
  Constraints.MinHeight := 500;

  GotedHeight := StrToIntDef(ReadRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath, MyHeight), 0);
  GotedWidth  := StrToIntDef(ReadRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath, MyWidth), 0);
  if (GotedHeight >= 500) and (GotedWidth >= 360) then
  begin
    Height := GotedHeight;
    Width := GotedWidth;
  end;

  // Timestamp GroupBox Check
  if ReadRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, IsTimestampHidden) = 1 then
   begin
       CheckBoxUseTimestampService.Checked :=False;
       TimestampGrpBox.Visible := False;
       ShowTimestamp1.Checked := True;
  end else
     begin
     TimestampGrpBox.Visible := True;
     ShowTimestamp1.Checked := False;
     end;

  // Password hide or not check
  if ReadRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, IsHidePassword) = 1 then
  begin
    EditPFXPassword.PasswordChar := '*';
    BtnHidePassword.Caption := ShowPasswordCaption;
  end
  else
  begin
    EditPFXPassword.PasswordChar := #0;
    BtnHidePassword.Caption := HidePasswordCaption;
  end;

  // Signing Hash Digest
  if ReadRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, SigningHashDiggest) = 1 then
  begin
    SHAM2.Checked := True;
    SHAL1.Checked := False;
  end
  else
  begin
    SHAL1.Checked := True;
    SHAM2.Checked := False;
  end;

  // Do not Remove Old Signature
  if ReadRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, ISStayign) = 1 then
    DontRemoveOldSignature1.Checked := True
  else
    DontRemoveOldSignature1.Checked := False;

  if DontRemoveOldSignature1.Checked then
    ShowModernRFCTimestampsUrlCollections
  else if SHAL1.Checked then
    ShowLegacyTimestampsUrlCollections
  else
    ShowModernRFCTimestampsUrlCollections;


  if ReadRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath, UseTimeStampService) = 1 then
  begin
    CheckBoxUseTimestampService.Checked := True;
    SelectTimestampUrlOrDefault(ReadRegistryStringsForSettings(HKEY_CURRENT_USER,
      MyRegistryPath, GetCurrentTimestampUrlRegKey));
    EditTimestampUrl.Enabled := True;
  end
  else
  begin
    CheckBoxUseTimestampService.Checked := False;
    EditTimestampUrl.ItemIndex := -1;
    EditTimestampUrl.Enabled := False;
  end;

end;



procedure TFormQBSigner.LoadPFXFileDialoge;
  var OpenPFXDlg1: TFileOpenDialog; FileTypeItem: TFileTypeItem;
  LastPathForPFX: string; begin LastPathForPFX := ReadRegistryStringsForSettings
    (HKEY_CURRENT_USER, MyRegistryPath, LatPFXFolder);

  OpenPFXDlg1 := TFileOpenDialog.Create(nil); try
  // Set dialog options
    OpenPFXDlg1.Options := OpenPFXDlg1.Options + [fdoForceFileSystem,
    fdoPathMustExist, fdoFileMustExist]; OpenPFXDlg1.Title := AddPFXDialogTitle;
  OpenPFXDlg1.OkButtonLabel := '&Choose';
  // Add file filter properly
  FileTypeItem := OpenPFXDlg1.FileTypes.Add;
  FileTypeItem.DisplayName := 'Personal Information Exchange (*.pfx, *.p12)';
  FileTypeItem.FileMask := '*.pfx;*.p12';

  // Set default folder if available
  if LastPathForPFX <> '' then OpenPFXDlg1.DefaultFolder := LastPathForPFX;

  // Show dialog and handle result
    if OpenPFXDlg1.Execute then begin EditPfxFile.Text := OpenPFXDlg1.FileName;
  WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
    LatPFXFolder, ExtractFileDir(OpenPFXDlg1.FileName));
  TryAutoFillPasswordForPFX; end;

  finally OpenPFXDlg1.Free; end; end;



procedure TFormQBSigner.LoadUIAllStrings; begin

  // UI
  Caption := MyAppName;
  BtnSign.Caption := SignCaption;
  BtnAddFiles.Caption := 'Add Files';
  BtnClearAllFiles.Caption := 'Remove All';
  BtnLoadPFX.Caption := 'Browse...';
  BtnHidePassword.Caption := HidePasswordCaption;
  CheckBoxUseTimestampService.Caption := 'Use Timestamp Service (Optional)';
  ProductNameGrpBox.Caption := 'Product Name (Optional)';
  Label1.Caption := 'Personal Information Exchange File:';
  Label2.Caption := 'Password:'; GroupBox1.Caption := 'Signing Certificate:';
  ListGrpBox.Caption := 'Binaries to Sign:';
  TimestampGrpBox.Caption := 'Timestamp:';

  // Menus
  RemoveSelected1.Caption := 'Remove Selected'; File1.Caption := 'File';
  ChoosePFX1.Caption := 'Choose &Certificate'; N1.Caption := MenuSeparator;
  AddFiles1.Caption := '&Add Files';
  N3.Caption := MenuSeparator;
  Exit1.Caption := '&Exit';

  SigningOptions1.Caption := 'Signing Options';
  ShowTimestamp1.Caption := '&Hide Timestamp Service';
  N2.Caption := MenuSeparator;
  DontRemoveOldSignature1.Caption := 'Do not Remove Old &Signature';


  File2.Caption := 'Signing Hash';
  SHAL1.Caption:='SHA1';
  SHAM2.Caption:='SHA256';


 // Legacytimestampserver1.Caption := '&Legacy timestamp server';

  Help1.Caption := 'Help';
  About1.Caption := '&About';
  Website1.Caption := '&Website'; end;

    procedure TFormQBSigner.ChoosePFX1Click(Sender: TObject);
  begin LoadPFXFileDialoge; end;

    procedure TFormQBSigner.AddFiles1Click(Sender: TObject);
  begin AddFilesToSign; end;

    procedure TFormQBSigner.PopUpMenuQBS1Popup(Sender: TObject);
  begin if ListView1.SelCount = 0 then Abort; end;

procedure TFormQBSigner.RemoveSelected1Click(Sender: TObject);
  var i: Integer; begin
  for i := ListView1.Items.Count - 1
    downto 0 do
      begin
      if ListView1.Items[i].Selected then
      ListView1.Items.Delete(i);
      end;
     FixListViewColumnWidth;
 end;



procedure TFormQBSigner.RepairSigntool1Click(Sender: TObject);
var
  ExePath: string;

begin
  ExePath := ExtractFilePath(Application.ExeName) + SignToolRepairUtilityExeName;

  if not FileExists(ExePath) then
  begin
  Application.MessageBox('QB Repair tool not found or missing.', 'Quick Binaries Signer', MB_OK or MB_ICONERROR);
   Exit;
  end;

  ShellExecute(0, 'open', PChar(ExePath), '/repair', PChar(ExtractFilePath(ExePath)), SW_HIDE);
end;

procedure TFormQBSigner.ReportImportProgress(const Current, Total: Integer;
  const Prefix: string);
begin
  // shurute + shesh item + protiti 20 file por, ba 60ms por update
  if (Current = 1) or (Current = Total) or (Current mod 20 = 0) or
     (GetTickCount - FImportLastTick > 60) then
  begin
    FImportLastTick := GetTickCount;
    TThread.Queue(nil,
      procedure
      begin
        ShowImportProgress(Format('%s %d/%d', [Prefix, Current, Total]));
      end);
  end;
end;

procedure TFormQBSigner.ScanFolderCollectForImport(const FolderPath: string;
  Depth: Integer; ExistingNames: TDictionary<string, Byte>;
  CollectedEntries: TList<TPair<string, Integer>>);
const
  MaxScanDepth = 32;
var
  SearchRec: TSearchRec;
  FullPath, Ext, KeyLower: string;
  IsReparse: Boolean;
  IconIdx: Integer;
begin
  if Depth > MaxScanDepth then Exit;
  if FindFirst(IncludeTrailingPathDelimiter(FolderPath) + '*.*',
       faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
      FullPath := IncludeTrailingPathDelimiter(FolderPath) + SearchRec.Name;
      IsReparse := (SearchRec.FindData.dwFileAttributes and
        FILE_ATTRIBUTE_REPARSE_POINT) <> 0;

      if (SearchRec.Attr and faDirectory) <> 0 then
      begin
        if not IsReparse then
          ScanFolderCollectForImport(FullPath, Depth + 1, ExistingNames, CollectedEntries);
      end
      else
      begin
        Ext := LowerCase(ExtractFileExt(FullPath));
        KeyLower := LowerCase(FullPath);
        if IsSignableExtension(Ext) and not ExistingNames.ContainsKey(KeyLower) then
        begin
           ExistingNames.Add(KeyLower, 0);
            IconIdx := GetShellIconIndex(FullPath);
            CollectedEntries.Add(TPair<string, Integer>.Create(FullPath, IconIdx));
            ReportImportScanProgress(CollectedEntries.Count);
        end;
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

procedure TFormQBSigner.ReportImportScanProgress(const CollectedCount: Integer);
begin
  if GetTickCount - FImportLastTick > 80 then   // throttle
  begin
    FImportLastTick := GetTickCount;
    TThread.Queue(nil,
      procedure
      begin
        ShowImportProgress(Format('Scanning... %d file(s) found', [CollectedCount]));
      end);
  end;
end;


function TFormQBSigner.RunCommandGetExitCode(const CmdLine: string;
  out Output: string): Cardinal;
var
  Security: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Buffer: array [0 .. 255] of Byte;
  BytesRead: DWORD;
  OutStream: TBytesStream;
  Cmd: string;
  Enc: TEncoding;
begin
  Result := DWORD(-1);
  Output := '';

  Cmd := CmdLine;
  UniqueString(Cmd);

  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  Security.lpSecurityDescriptor := nil;

  if not CreatePipe(ReadPipe, WritePipe, @Security, 0) then
    Exit;

  try
    ZeroMemory(@StartInfo, SizeOf(StartInfo));
    StartInfo.cb := SizeOf(StartInfo);
    StartInfo.hStdOutput := WritePipe;
    StartInfo.hStdError := WritePipe;
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.wShowWindow := SW_HIDE;

    if not CreateProcess(nil, PChar(Cmd), nil, nil, True, CREATE_NO_WINDOW, nil, nil, StartInfo, ProcInfo) then
    begin
      Output := 'Could not start signtool: ' + SysErrorMessage(GetLastError);
      Exit;
    end;

    CloseHandle(WritePipe);
    WritePipe := 0;

    OutStream := TBytesStream.Create;
    try
      while True do
      begin
        if not ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) then
          Break;
        if BytesRead = 0 then
          Break;
        OutStream.Write(Buffer, BytesRead);
      end;

      WaitForSingleObject(ProcInfo.hProcess, INFINITE);
      GetExitCodeProcess(ProcInfo.hProcess, Result);

      Enc := TEncoding.GetEncoding(GetOEMCP);
      try
        Output := Enc.GetString(OutStream.Bytes, 0, OutStream.Size);
      finally
        Enc.Free;
      end;
    finally
      OutStream.Free;
    end;

    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  finally
    if WritePipe <> 0 then
      CloseHandle(WritePipe);
    CloseHandle(ReadPipe);

    if Length(Cmd) > 0 then
      FillChar(Cmd[1], Length(Cmd) * SizeOf(Char), 0);
    Cmd := '';
  end;
end;

procedure TFormQBSigner.SetupFileIconList;
var
  SHFileInfo: TSHFileInfo;
begin
  FillChar(SHFileInfo, SizeOf(SHFileInfo), 0);
  FSysImageList := SHGetFileInfo('', 0, SHFileInfo, SizeOf(SHFileInfo),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON);

  if FSysImageList <> 0 then
    SendMessage(ListView1.Handle, LVM_SETIMAGELIST, LVSIL_SMALL, FSysImageList);
end;
   {
procedure TFormQBSigner.AddFileToListIfSignable(const FullPath: string);
var
  Ext: string;
  j: Integer;
  AlreadyExists: Boolean;
  ListItem: TListItem;
begin
  Ext := LowerCase(ExtractFileExt(FullPath));

  if (Ext = '.exe') or (Ext = '.dll') or (Ext = '.msi') or (Ext = '.msp') or
     (Ext = '.ocx') or (Ext = '.sys') or (Ext = '.cpl') or (Ext = '.drv') or
     (Ext = '.cat') or (Ext = '.vbs') or (Ext = '.xpi') or (Ext = '.msix') or
     (Ext = '.msixbundle') or (Ext = '.appx') or (Ext = '.appxbundle') or
     (Ext = '.ax') or (Ext = '.efi') or (Ext = '.scr') or (Ext = '.pyd') then
  begin
    AlreadyExists := False;

    for j := 0 to ListView1.Items.Count - 1 do
    begin
      if SameText(ListView1.Items[j].Caption, FullPath) then
      begin
        AlreadyExists := True;
        Break;
      end;
    end;

   if not AlreadyExists then
    begin
      ListItem := ListView1.Items.Add;
      ListItem.Caption := FullPath;
      ListItem.ImageIndex := GetShellIconIndex(FullPath);
      ListItem.SubItems.Add(Caption_Queued);
    end;
  end;
end;
   }
procedure TFormQBSigner.AskRepairSigntool;
var
  Detail: string;
begin
  Detail := '';
  if FFirstError <> '' then
    Detail := sLineBreak + sLineBreak + 'Details: ' + FFirstError;

  if Application.MessageBox(
    PChar('signtool.exe could not run. It may be damaged or missing a required component.'
    + Detail + sLineBreak + sLineBreak + 'Do you want to repair signtool now?'),
    PChar(MyAppName), MB_YESNO or MB_ICONERROR) = IDYES then
    RepairSigntool1Click(nil);
end;

  {
procedure TFormQBSigner.ScanFolderForSignableFiles(const FolderPath: string;
  Depth: Integer = 0);
const
  MaxScanDepth = 32; // khub deep ba loop-hoye-jawa folder structure hole thamiye dao
var
  SearchRec: TSearchRec;
  FullPath: string;
  IsReparsePoint: Boolean;
begin
  if Depth > MaxScanDepth then
    Exit;

  // Prothome ei folder-er direct file gulo check koro
  if FindFirst(IncludeTrailingPathDelimiter(FolderPath) + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue;

        FullPath := IncludeTrailingPathDelimiter(FolderPath) + SearchRec.Name;

        IsReparsePoint := (SearchRec.FindData.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;

        if (SearchRec.Attr and faDirectory) <> 0 then
        begin
          if not IsReparsePoint then
            // Subfolder pele recursively abar call koro
            ScanFolderForSignableFiles(FullPath, Depth + 1);
        end
        else
          // File hole signable kina check kore add koro
          AddFileToListIfSignable(FullPath);

      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;


}

procedure TFormQBSigner.SelectAndScrollToItem(Index: Integer);
begin
  if (Index < 0) or (Index >= ListView1.Items.Count) then  Exit;
  ListView1.ClearSelection;
  ListView1.Items[Index].Selected := True;
  ListView1.Items[Index].Focused  := True;
  ListView1.ItemFocused := ListView1.Items[Index];
  ListView1.Items[Index].MakeVisible(False);
end;

procedure TFormQBSigner.SelectTimestampUrlOrDefault(const PreferredUrl: string);
var
  Idx: Integer;
begin
  Idx := -1;
  if PreferredUrl <> '' then
    Idx := EditTimestampUrl.Items.IndexOf(PreferredUrl);

  if Idx >= 0 then
    EditTimestampUrl.ItemIndex := Idx    // age-e select kora URL pawa gele shei-tai
  else
    EditTimestampUrl.ItemIndex := 0;     // na pele fallback first item
end;


procedure TFormQBSigner.SetListViewImageList(UseStatusIcons: Boolean);
begin
  if UseStatusIcons then
    SendMessage(ListView1.Handle, LVM_SETIMAGELIST, LVSIL_SMALL,
      VirtualImageList1.Handle)
  else if FSysImageList <> 0 then
    SendMessage(ListView1.Handle, LVM_SETIMAGELIST, LVSIL_SMALL, FSysImageList);
end;

function TFormQBSigner.GetShellIconIndex(const FileName: string): Integer;
var
  SHFileInfo: TSHFileInfo;
begin
  FillChar(SHFileInfo, SizeOf(SHFileInfo), 0);
  if SHGetFileInfo(PChar(FileName), 0, SHFileInfo, SizeOf(SHFileInfo),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON) <> 0 then
    Result := SHFileInfo.iIcon
  else
    Result := -1; // icon না পেলে default (কোনো icon দেখাবে না)
end;





procedure TFormQBSigner.HideImportProgress;
begin
  if Assigned(FImportProgressLabel) then
    FImportProgressLabel.Visible := False;
end;


procedure TFormQBSigner.ImportDroppedPaths(const Paths: TArray<string>);
begin
  IsImportingFiles := True;
  DisabledEverythingWhileSigning;
  BtnSign.Caption := SignCaption;
  ProgressBar1.Visible := False;
  FImportLastTick := 0;
  ShowImportProgress(Format('Preparing files 0/%d', [Length(Paths)]));

  TTask.Run(
    procedure
    var
      ExistingNames: TDictionary<string, Byte>;
      CollectedEntries: TList<TPair<string, Integer>>;
      PendingPfx, ErrMsg: string;
      i, TopLevelTotal: Integer;
      Ext, FullPath, KeyLower: string;
      IconIdx: Integer;
      ComInited: Boolean;
    begin
      ComInited := Succeeded(CoInitialize(nil));
      ExistingNames := TDictionary<string, Byte>.Create;
      CollectedEntries := TList<TPair<string, Integer>>.Create;
      PendingPfx := '';
      ErrMsg := '';
      TopLevelTotal := Length(Paths);
      try
        // Phase 1: স্ক্যান — এরর হলেও যেন Phase 2 চলে
        try
          TThread.Synchronize(nil,
            procedure
            var
              k: Integer;
            begin
              for k := 0 to ListView1.Items.Count - 1 do
                ExistingNames.AddOrSetValue(LowerCase(ListView1.Items[k].Caption), 0);
            end);

          for i := 0 to High(Paths) do
          begin
            FullPath := Paths[i];
            if DirectoryExists(FullPath) then
              ScanFolderCollectForImport(FullPath, 0, ExistingNames, CollectedEntries)
            else
            begin
              Ext := LowerCase(ExtractFileExt(FullPath));
              if (Ext = '.pfx') or (Ext = '.p12') then
                PendingPfx := FullPath
              else
              begin
                KeyLower := LowerCase(FullPath);
                if IsSignableExtension(Ext) and not ExistingNames.ContainsKey(KeyLower) then
                begin
                  ExistingNames.Add(KeyLower, 0);
                  IconIdx := GetShellIconIndex(FullPath);
                  CollectedEntries.Add(TPair<string, Integer>.Create(FullPath, IconIdx));
                  ReportImportScanProgress(CollectedEntries.Count);
                end;
              end;
            end;
            ReportImportProgress(i + 1, TopLevelTotal, 'Preparing files');
          end;
        except
          on E: Exception do
            ErrMsg := E.Message;
        end;

        // Phase 2: UI আপডেট — finally-তে সবসময় UI আনলক হবে
        TThread.Synchronize(nil,
          procedure
          var
            k: Integer;
            NewItem: TListItem;
            Entry: TPair<string, Integer>;
          begin
            try
              ShowImportProgress(Format('Adding to list... 0/%d', [CollectedEntries.Count]));
              ListView1.Items.BeginUpdate;
              try
                for k := 0 to CollectedEntries.Count - 1 do
                begin
                  Entry := CollectedEntries[k];
                  NewItem := ListView1.Items.Add;
                  NewItem.Caption := Entry.Key;
                  NewItem.ImageIndex := Entry.Value;
                  NewItem.SubItems.Add(Caption_Queued);
                end;
              finally
                ListView1.Items.EndUpdate;
              end;

              if PendingPfx <> '' then
              begin
                EditPfxFile.Text := PendingPfx;
                WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
                  LatPFXFolder, ExtractFileDir(PendingPfx));
                TryAutoFillPasswordForPFX;
              end;
              FixListViewColumnWidth;
            finally
              HideImportProgress;
              EnableEverythingAfterSign;
              IsImportingFiles := False;
            end;

            if ErrMsg <> '' then
              Application.MessageBox(
                PChar('Some files could not be imported:' + sLineBreak + ErrMsg),
                PChar(MyAppName), MB_OK or MB_ICONWARNING);
          end);
      finally
        CollectedEntries.Free;
        ExistingNames.Free;
        if ComInited then
          CoUninitialize;
      end;
    end);
end;



function TFormQBSigner.IsSignableExtension(const Ext: string): Boolean;
begin
  Result :=
    (Ext = '.exe') or (Ext = '.dll') or (Ext = '.msi') or (Ext = '.msp') or
    (Ext = '.ocx') or (Ext = '.sys') or (Ext = '.cpl') or (Ext = '.drv') or
    (Ext = '.cat') or (Ext = '.vbs') or (Ext = '.xpi') or (Ext = '.msix') or
    (Ext = '.msixbundle') or (Ext = '.appx') or (Ext = '.appxbundle') or
    (Ext = '.ax') or (Ext = '.efi') or (Ext = '.scr') or (Ext = '.pyd');
end;

procedure TFormQBSigner.SgningHashDetection(Sender: TObject);
begin
  if Sender = SHAL1 then
  begin
    SHAL1.Checked := True;
    SHAM2.Checked := False;
    if DontRemoveOldSignature1.Checked then
      ShowModernRFCTimestampsUrlCollections
    else
      ShowLegacyTimestampsUrlCollections;

    if CheckBoxUseTimestampService.Checked then
      SelectTimestampUrlOrDefault(ReadRegistryStringsForSettings(HKEY_CURRENT_USER,
        MyRegistryPath, GetCurrentTimestampUrlRegKey));
    Exit;
  end
  else if Sender = SHAM2 then
  begin
    SHAL1.Checked := False;
    SHAM2.Checked := True;
    ShowModernRFCTimestampsUrlCollections;
    if CheckBoxUseTimestampService.Checked then
      SelectTimestampUrlOrDefault(ReadRegistryStringsForSettings(HKEY_CURRENT_USER,
        MyRegistryPath, GetCurrentTimestampUrlRegKey));
    Exit;
  end;
end;

procedure TFormQBSigner.ShowinFileExplorer;
var
  Item: TListItem;
  FullPath: string;
begin
  Item := ListView1.Selected;
  if not Assigned(Item) then Exit;
  FullPath := Item.Caption;
  if FileExists(FullPath) then
  begin
    ShellExecute(Handle, 'open', 'explorer.exe',
      PChar('/select,"' + FullPath + '"'), nil, SW_SHOWNORMAL);
  end
end;

procedure TFormQBSigner.ShowImportProgress(const AText: string);
begin
  if not Assigned(FImportProgressLabel) then Exit;
  CenterImportProgressLabel;
  FImportProgressLabel.Caption := AText;
  FImportProgressLabel.Visible := True;
  FImportProgressLabel.BringToFront;
end;

procedure TFormQBSigner.ShowinExplorer1Click(Sender: TObject);
begin
   ShowinFileExplorer;
end;

procedure TFormQBSigner.ShowLegacyTimestampsUrlCollections; var i: Integer;

  begin EditTimestampUrl.Items.Clear;
  for i := 0 to High(LegacyUrls) do EditTimestampUrl.Items.Add
    (LegacyUrls[i]) end;

    procedure TFormQBSigner.ShowModernRFCTimestampsUrlCollections;
  var i: Integer;

  begin EditTimestampUrl.Items.Clear;
  for i := 0 to High(ModernRFCUrls) do EditTimestampUrl.Items.Add
    (ModernRFCUrls[i]) end;

procedure TFormQBSigner.ShowTimestamp1Click(Sender: TObject); begin

  if not ShowTimestamp1.Checked then
  begin
       if CheckBoxUseTimestampService.Checked then
      begin
      Application.MessageBox('Please turn off the Timestamp service first.', 'Information', MB_OK or MB_ICONINFORMATION);
      Exit
      end;
  TimestampGrpBox.Visible := False; // Make hidden
  ShowTimestamp1.Checked := True;

  end
  else
  begin TimestampGrpBox.Visible := True;
  WriteRegistryIntegerForSettings(HKEY_CURRENT_USER, MyRegistryPath,
    IsTimestampHidden, 0); ShowTimestamp1.Checked := False; end;

  end;

   
procedure TFormQBSigner.SignFilesInBackground(
  const PfxFile, Password, TimeStampURL, Description, SignToolPath, DigestAlgo: string;
  const UseTimestampService, DontRemoveOldSignature: Boolean;
  const FilesToSign: TArray<string>);
var
  SignedCount, FailedCount, i: Integer;
  FileLine, SignCmd, CmdOutput: string;
  ExitCode: Cardinal;
  Cancelled: Boolean;
begin
  SignedCount := 0;
  FailedCount := 0;
  Cancelled := False;

  for i := 0 to High(FilesToSign) do
  begin
    // প্রতিটা ফাইল শুরুর আগে cancel চেক
    if InterlockedCompareExchange(FSigningCancelRequested, 0, 0) <> 0 then
    begin
      Cancelled := True;
      Break;
    end;

    FileLine := Trim(FilesToSign[i]);

    if FileLine = '' then
      Continue;

    TThread.Synchronize(nil,
      procedure
      begin
        SelectAndScrollToItem(i);
        if (i < ListView1.Items.Count) and
           (ListView1.Items[i].SubItems.Count > 0) then
        begin
          ListView1.Items[i].SubItems[0] := Caption_Signing;
          ListView1.UpdateItems(i, i);
        end;
      end);

    if not FileExists(FileLine) then
    begin
      TThread.Synchronize(nil,
        procedure
        begin
          if (i < ListView1.Items.Count) and
             (ListView1.Items[i].SubItems.Count > 0) then
          begin
            ListView1.Items[i].SubItems[0] := Caption_Missing;
            ListView1.UpdateItems(i, i);
          end;
        end);
      Continue;
    end;

    // Build the SignTool command (সব আর্গুমেন্ট escape করা)
    SignCmd := EscapeCmdArg(SignToolPath) + ' sign /f ' + EscapeCmdArg(PfxFile) +
      ' /p ' + EscapeCmdArg(Password);

    if UseTimestampService then
    begin
      // SHA1 + append না হলে legacy /t, নাহলে RFC3161 (/tr + /td sha256)
      if (not DontRemoveOldSignature) and SameText(DigestAlgo, 'sha1') then
        SignCmd := SignCmd + ' /t ' + EscapeCmdArg(TimeStampURL)
      else
        SignCmd := SignCmd + ' /tr ' + EscapeCmdArg(TimeStampURL) + ' /td sha256';
    end;

    SignCmd := SignCmd + ' /fd ' + DigestAlgo;
    if DontRemoveOldSignature then
      SignCmd := SignCmd + ' /as';
    if Description <> '' then
      SignCmd := SignCmd + ' /d ' + EscapeCmdArg(Description);
    SignCmd := SignCmd + ' ' + EscapeCmdArg(FileLine);

    ExitCode := RunCommandGetExitCode(SignCmd, CmdOutput);

    if ExitCode = 0 then
      Inc(SignedCount)
    else
    begin
      Inc(FailedCount);
      if FFirstError = '' then
        FFirstError := CleanSignToolOutput(CmdOutput);
    end;

    TThread.Synchronize(nil,
      procedure
      begin
        if (i < ListView1.Items.Count) and
           (ListView1.Items[i].SubItems.Count > 0) then
        begin
          if ExitCode = 0 then
            ListView1.Items[i].SubItems[0] := Caption_Signed
          else
            ListView1.Items[i].SubItems[0] := Caption_Failed;

          ListView1.UpdateItems(i, i);
        end;
      end);

    if ExitCode >= $C0000000 then
    begin
      FSignToolBroken := True;
      Break;
    end;

    // ফাইল শেষ হওয়ার পর ESC চাপা হলে
    if InterlockedCompareExchange(FSigningCancelRequested, 0, 0) <> 0 then
    begin
      Cancelled := True;
      Break;
    end;
  end;

  FFailedCount := FailedCount;

  TThread.Synchronize(nil,
    procedure
    var
      k: Integer;
    begin
      if SignedCount > 0 then
      begin
        UpsertRecentPFX(PfxFile, Password);
        UpsertCaption(Description);
        LoadRecentPFXIntoCombo;
        LoadCaptionsIntoCombo;
      end;

      // ESC চাপলে (বা signtool ক্র্যাশ করলে) যেগুলো এখনও Ready আছে সেগুলো Aborted
      if Cancelled or FSignToolBroken then
      begin
        for k := 0 to ListView1.Items.Count - 1 do
          if (ListView1.Items[k].SubItems.Count > 0) and
             SameText(ListView1.Items[k].SubItems[0], Caption_Ready) then
            ListView1.Items[k].SubItems[0] := Caption_Aborted;
      end;

      ListView1.ClearSelection;
      ListView1.Invalidate;

      if Cancelled then
        MessageBeep(MB_ICONINFORMATION)
      else if (FailedCount > 0) and (SignedCount = 0) then
        MessageBeep(MB_ICONERROR)
      else
        MessageBeep(MB_ICONINFORMATION);
    end);
end;



procedure TFormQBSigner.Website1Click(Sender: TObject);
  begin
  OpenURL(MyAppUrl)

  end;


  {
procedure TFormQBSigner.WMDropFiles(var Msg: TWMDropFiles);
var
  FileCount, i: Integer;
  FileName: array[0..MAX_PATH] of Char;
  Ext: string;
  FullPath: string;
begin
  if IsSigningInProgress then
  begin
    DragFinish(Msg.Drop);
    Exit;
  end;

  FileCount := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);
  for i := 0 to FileCount - 1 do
  begin
    DragQueryFile(Msg.Drop, i, FileName, MAX_PATH);
    FullPath := FileName;

    // Folder dropped hole -> recursively shob signable file khuje add koro
    if DirectoryExists(FullPath) then
    begin
      ScanFolderForSignableFiles(FullPath);
      Continue;
    end;

    Ext := LowerCase(ExtractFileExt(FullPath));

    // PFX / P12 dropped -> সরাসরি Certificate ফিল্ডে বসাও, list এ যাবে না
    if (Ext = '.pfx') or (Ext = '.p12') then
    begin
      EditPfxFile.Text := FullPath;

      // Browse dialog এর মতোই last-used ফোল্ডার সেভ করে রাখলাম (consistency)
      WriteRegistryStringsForSettings(HKEY_CURRENT_USER, MyRegistryPath,
        LatPFXFolder, ExtractFileDir(FullPath));

      // Recent list এ আগে থেকে থাকলে password auto-fill হবে (existing logic reuse)
      TryAutoFillPasswordForPFX;

      Continue; // এই ফাইলটা আর নিচের signable-check এ যাবে না
    end;

    // Shadharon file drop hole normal check
    AddFileToListIfSignable(FullPath);
  end;
  DragFinish(Msg.Drop);
  FixListViewColumnWidth;
end;
       }

procedure TFormQBSigner.WMDropFiles(var Msg: TWMDropFiles);
var
  FileCount, i: Integer;
  FileNameBuf: array[0..MAX_PATH] of Char;
  DroppedPaths: TArray<string>;
begin
  if IsSigningInProgress or IsImportingFiles then
  begin
    DragFinish(Msg.Drop);
    Exit;
  end;

  FileCount := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);
  SetLength(DroppedPaths, FileCount);
  for i := 0 to FileCount - 1 do
  begin
    DragQueryFile(Msg.Drop, i, FileNameBuf, MAX_PATH);
    DroppedPaths[i] := FileNameBuf;
  end;
  DragFinish(Msg.Drop);   // taratari chere dao, message handler block hobe na

  if Length(DroppedPaths) = 0 then Exit;
  ImportDroppedPaths(DroppedPaths);
end;

end.
