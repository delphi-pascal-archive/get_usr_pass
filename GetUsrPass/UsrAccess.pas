Unit UsrAccess;

interface

uses
  Windows, Classes, SysUtils;

type
  PNET_DISPLAY_USER = ^TNET_DISPLAY_USER;
  TNET_DISPLAY_USER = record
    usri1_name : LPWSTR;
    usri1_comment : LPWSTR;
    usri1_flags : DWord;
    usri1_full_name : LPWSTR;
    usri1_user_id : DWord;
    usri1_next_index : DWord;
  end;

type
  TLMWideChar = record
    Value : PWideChar;
    Length: DWord;
  end;

TNetDisplayUserArray = array[0..(MaxInt div SizeOf(TNET_DISPLAY_USER))-1] of TNET_DISPLAY_USER;

type
TNetUserChangePassword = function(DomainName, UserName, OldPassword, NewPassword: LPCWSTR): DWord; stdcall;
TNetApiBufferFree = function(Buffer: Pointer): dWord; stdcall;
TNetQueryDisplayInformation = function(ServerName: LPCWSTR; Level, Index, EntriesRequested, PrefMaxLen: DWord; var ReturnedCount: DWord; var Buffer: Pointer): dword; stdcall;

const
NERR_SUCCESS = 0;

var
    FName    : string;
    FServer  : string;
    FUserList    : TStringList;
    NETAPI32    : THandle = 0;
    ADVAPI32    : THandle = 0;
    NETAPI32DLL : PChar   = 'netapi32.dll';
    ADVAPI32DLL : PChar   = 'advapi32.dll';
    _NetUserChangePassword : TNetUserChangePassword = nil;
    _NetApiBufferFree : TNetApiBufferFree = nil;
    _NetQueryDisplayInformation : TNetQueryDisplayInformation = nil;

function StNetUserChangePassword(DomainName, UserName, OldPassword,
                                 NewPassword: string): dword;
function GetUserList(UsrList: TStrings): Boolean;

implementation

function ServerUncName(Name: string): string;
begin
  if (Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion < 5) then
    Result := '\\' + Name
  else
    Result := Name;
end;

procedure CvtToWideChar(const S: string; var WS: TLMWideChar);
var
  S1 : string;
begin
  if WS.Value <> nil then
    FreeMem(WS.Value, WS.Length);
  S1 := Trim(S);
  if Length(S1) > 0 then begin
    WS.Length := (Length(S1) + 1) * 2;
    GetMem(WS.Value, WS.Length);
    StringToWideChar(S1, WS.Value, WS.Length);
  end else begin
    WS.Length := 0;
    WS.Value := nil;
  end;
end;

function IsAdvApi32: Boolean;
begin
  if ADVAPI32 = 0 then
    ADVAPI32 := LoadLibrary(ADVAPI32DLL);

  Result := (ADVAPI32 <> 0);
end;

function IsNetApi32: Boolean;
begin
  if NETAPI32 = 0 then
  NETAPI32 := LoadLibrary(NETAPI32DLL);
  Result := (NETAPI32 <> 0);
end;

function StNetUserChangePassword(DomainName, UserName, OldPassword,
                                 NewPassword: string): dword;
var
  D, U, O, N : TLMWideChar;
begin
  Result := 0;
  if IsNetApi32 then begin
    if (@_NetUserChangePassword = nil) then
      @_NetUserChangePassword := GetProcAddress(NETAPI32, 'NetUserChangePassword');

    if (@_NetUserChangePassword <> nil) then begin
      DomainName := ServerUncName(DomainName);

      D.Value := nil;
      U.Value := nil;
      O.Value := nil;
      N.Value := nil;
      try
        CvtToWideChar(DomainName, D);
        CvtToWideChar(UserName, U);
        CvtToWideChar(OldPassword, O);
        CvtToWideChar(NewPassword, N);
        Result := _NetUserChangePassword(D.Value, U.Value, O.Value, N.Value);
      finally
        FreeMem(D.Value, D.Length);
        FreeMem(U.Value, U.Length);
        FreeMem(O.Value, O.Length);
        FreeMem(N.Value, N.Length);
      end;
    end;
  end;
end;

function StNetApiBufferFree(Buffer: Pointer): dWord;
begin
  Result := 0;
  if IsNetApi32 then begin
    if (@_NetApiBufferFree = nil) then
      @_NetApiBufferFree := GetProcAddress(NETAPI32, 'NetApiBufferFree');

    if (@_NetApiBufferFree <> nil) then
      Result := _NetApiBufferFree(Buffer)
  end;
end;

function StNetQueryDisplayInformation(ServerName: string; Level, Index,
                                      EntriesRequested, PrefMaxLen: DWord;
                                      var ReturnedCount: DWord;
                                      var Buffer: Pointer): dword;
var
  S : TLMWidechar;
begin
  Result := 0;
  if IsNetApi32 then begin
    if (@_NetQueryDisplayInformation = nil) then
      @_NetQueryDisplayInformation := GetProcAddress(NETAPI32, 'NetQueryDisplayInformation');
    if (@_NetQueryDisplayInformation <> nil) then begin
      ServerName := ServerUncName(ServerName);
      S.Value := nil;
      try
        CvtToWideChar(ServerName, S);
        Result := _NetQueryDisplayInformation(S.Value, Level, Index,
                                              EntriesRequested, PrefMaxLen,
                                              ReturnedCount, Buffer);
      finally
        FreeMem(S.Value, S.Length);
      end;
    end;
    end;
end;

function GetUserList(UsrList: TStrings): Boolean;
var
  ErrorD : DWord;
  Index : Integer;
  Buffer : Pointer;
  EntriesRead : DWord;
  MoreData : Boolean;
  NextIndex : DWord;
begin
  MoreData := True;
  NextIndex := 0;
  try
    while MoreData do begin
      ErrorD := StNetQueryDisplayInformation(FServer, 1, NextIndex, DWord(-1),
                                             DWord(-1), EntriesRead, Buffer);
      if ((ErrorD = NERR_SUCCESS) or (ErrorD = ERROR_MORE_DATA)) then begin
        try
          if EntriesRead > 0 then begin                                {!!.02}
            for Index := 0 to EntriesRead-1 do begin
             UsrList.Add(TNetDisplayUserArray(Buffer^)[Index].usri1_name);
            end;
          end;                                                         {!!.02}
          MoreData := (ErrorD = ERROR_MORE_DATA);
        finally
          StNetApiBufferFree(Buffer);
        end;
        end;
    end;
  finally
  end;
end;

end.
