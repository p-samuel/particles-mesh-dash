program Mesh;

uses
  System.StartUpCopy,
  FMX.Forms,
  Mesh.Main in 'src\Mesh.Main.pas' {FormMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
