program SRC;

uses
  Forms,
  uMain in 'uMain.pas' {MainFrm},
  AboutFrm in 'AboutFrm.pas' {AboutForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.Run;
end.
