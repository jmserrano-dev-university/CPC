program PRUEBA_LAVADORA_V10;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, pl_excontrols, u_rs232, u_inicial, lavadora;


{$R *.res}

begin
  Application.Title:='Lavadora SALASER';
  Application.Initialize;
  //Application.CreateForm(TF_INICIAL, F_INICIAL);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

