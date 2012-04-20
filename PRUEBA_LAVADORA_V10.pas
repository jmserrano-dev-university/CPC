program PRUEBA_LAVADORA_V10;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, u_rs232, u_inicial;


{$R *.res}

begin
  Application.Title:='TEST CPC';
  Application.Initialize;
  Application.CreateForm(TF_INICIAL, F_INICIAL);
  Application.Run;
end.

