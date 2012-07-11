unit u_inicial;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils, FileUtil, DateUtils, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, ComCtrls, Spin, u_rs232;

type

  { TF_INICIAL }

  TF_INICIAL = class(TForm)
    BT_RELE1: TSpeedButton;
    BT_RELE2: TSpeedButton;
    BT_RELE3: TSpeedButton;
    BT_RELE4: TSpeedButton;
    BT_RELE5: TSpeedButton;
    BT_SALIR: TBitBtn;
    BT_OPENPORT: TButton;
    CHK0: TCheckBox;
    CHK1: TCheckBox;
    CHK2: TCheckBox;
    CHK3: TCheckBox;
    CHK4: TCheckBox;
    CHK5: TCheckBox;
    GroupBox2: TGroupBox;
    IMG1: TImage;
    LB_1: TLabel;
    LB_2: TLabel;
    LB_3: TLabel;
    LB_4: TLabel;
    LB_5: TLabel;
    LB_CN1: TLabel;
    LB_CN2: TLabel;
    LB_CN3: TLabel;
    LB_RELES: TLabel;
    LB_PORT: TLabel;
    LB_RELES1: TLabel;
    LB_0: TLabel;
    LB_CN0: TLabel;
    LB_PN_ANALOGICAS: TLabel;
  LB_VERSION: TLabel;
  LB_ARRANCANDO: TLabel;
  PB_CN1: TProgressBar;
  PB_CN2: TProgressBar;
  PB_CN3: TProgressBar;
  PN_ANALOGICAS: TPanel;
  PN_ENTRADAS: TPanel;
  PN_RELES: TPanel;
  BT_RELE0: TSpeedButton;
  PB_CN0: TProgressBar;
  TMR_ACTUALIZAR: TTimer;
  SP_PORT: TUpDown;
  procedure BTI_TERMINAR_APLICACIONClick(Sender: TObject);
  procedure BT_OPENPORTClick(Sender: TObject);
  procedure BT_RELE0Click(Sender: TObject);
  procedure BT_RELE1Click(Sender: TObject);
  procedure BT_RELE2Click(Sender: TObject);
  procedure BT_RELE3Click(Sender: TObject);
  procedure BT_RELE4Click(Sender: TObject);
  procedure BT_RELE5Click(Sender: TObject);
  procedure BT_SALIRClick(Sender: TObject);

  procedure FormActivate(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure SP_PORTClick(Sender: TObject);
  procedure TMR_ACTUALIZARTimer(Sender: TObject);
  procedure ActualizarEntradasDigitales();
  procedure ActualizarEntradasAnalogicas();
  private
    public
    { public declarations }
  end; 

var
  F_INICIAL: TF_INICIAL;
  parametrosformato:TFormatSettings;
  estadorele:array[1..6] of boolean;
implementation

uses u_main;
{ TF_INICIAL }

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure TF_INICIAL.FormCreate(Sender: TObject);
var P:pointer;
   i:integer;
begin
 DecimalSeparator:='.';
 ThousandSeparator:=',';
 BufferRXCOM:=StrAlloc (50);
 for i:=0 to 50 do BufferRXCOM[i]:=#0;
 pitido:=TRUE;

 beepdriver := INVALID_HANDLE_VALUE;
  {$ifdef WINCE}
  If (beepdriver = INVALID_HANDLE_VALUE) then
  begin
    P := PWideChar(UTF8Decode('LED1:'));
    beepdriver := CreateFile(P, GENERIC_READ Or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, longword(0));
    If (beepdriver = INVALID_HANDLE_VALUE) then  showmessage('ERROR BEEP SYSTEM!');
  end;
  {$endif}


end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************

procedure TF_INICIAL.SP_PORTClick(Sender: TObject);
begin
  Bip(2);
  LB_PORT.Caption:=IntToStr(SP_PORT.Position);
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure TF_INICIAL.TMR_ACTUALIZARTimer(Sender: TObject);
begin
     TMR_ACTUALIZAR.Enabled:=False;
     ActualizarEntradasDigitales();
     ActualizarEntradasAnalogicas();
     TMR_ACTUALIZAR.Enabled:=TRUE;
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure TF_INICIAL.BTI_TERMINAR_APLICACIONClick(Sender: TObject);
begin

StrDispose(BufferRXCOM);
Application.ProcessMessages;
Application.Terminate;
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_OPENPORTClick(Sender: TObject);
var puerto:integer;
begin
puerto:=StrToInt(LB_PORT.Caption);
If BT_OPENPORT.Caption='CERRAR' then
   begin
        if (comport<>INVALID_HANDLE_VALUE) then
        begin
        CloseComp(comport);

    BT_OPENPORT.Caption:='ABRIR';
    TMR_ACTUALIZAR.Enabled:=FALSE;
    SP_PORT.Enabled:=True;
    PN_RELES.Enabled:=FALSE;
    exit;
    end;
   end
else
    comport:=OpenComP(puerto,115200);
    if comport =INVALID_HANDLE_VALUE then
     begin
     ShowMessage('ERROR. No se puede abrir el puerto seleccionado COM'+inttostr(puerto));
     PN_RELES.Enabled:=FALSE;
     exit;
     end
    else
    begin
        BT_OPENPORT.Caption:='CERRAR';
       TMR_ACTUALIZAR.Enabled:=TRUE;
       SP_PORT.Enabled:=FALSE;
       PN_RELES.Enabled:=TRUE;
    end;
end;

//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.ActualizarEntradasDigitales();
var lct,r,i,msk:integer;
  cd,rs:string;
  st:boolean;
begin
    rs:='';
    EnviarDatos('E*'+CR);
    RecibirDatos(rs,100,6);
    lct:=StrToIntdef(rs,-1);
    msk:=1;
    for i:=0 to 5 do
    begin
    r:=msk and lct;
    st:=false;
    if r=0 then  st:=true;
    case i of
        0:   CHK0.Checked:=st;
        1:   CHK1.Checked:=st;
        2:   CHK2.Checked:=st;
        3:   CHK3.Checked:=st;
        4:   CHK4.Checked:=st;
        5:   CHK5.Checked:=st;
    end;
    msk:=msk*2;
    end;
end;

//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.ActualizarEntradasAnalogicas();
var lct,i:integer;
  cd,rs:string;
begin
    for i:=0 to 3 do
    begin
    rs:='';
    cd:=format('AD%d',[i])+CR;
    EnviarDatos(cd);
    RecibirDatos(rs,100,6);
    lct:=StrToIntdef(rs,0);
    case i of
        0:
          begin
          LB_CN0.Caption:=format('CN[%d]=%d',[i,lct]);
          PB_CN0.Position:=lct;
          end;
        1:
          begin
          LB_CN1.Caption:=format('CN[%d]=%d',[i,lct]);
          PB_CN1.Position:=lct;
          end;
        2:
          begin
          LB_CN2.Caption:=format('CN[%d]=%d',[i,lct]);
          PB_CN2.Position:=lct;
          end;
        3:
          begin
          LB_CN3.Caption:=format('CN[%d]=%d',[i,lct]);
          PB_CN3.Position:=lct;
          end;
    end;

    end;

end;


//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE0Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE0.Down then    ActivarRele(0)
    else   DesActivarRele(0);
end;


//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE1Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE1.Down then    ActivarRele(1)
    else   DesActivarRele(1);
end;

//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE2Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE2.Down then    ActivarRele(2)
    else   DesActivarRele(2);
end;
//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE3Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE3.Down then    ActivarRele(3)
    else   DesActivarRele(3);
end;
//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE4Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE4.Down then    ActivarRele(4)
    else   DesActivarRele(4);
end;
//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.BT_RELE5Click(Sender: TObject);
begin
Bip(2);
    if BT_RELE5.Down then    ActivarRele(5)
    else   DesActivarRele(5);
end;

procedure TF_INICIAL.BT_SALIRClick(Sender: TObject);
begin

end;

//*********************************************************************************************************
//
//*********************************************************************************************************
procedure TF_INICIAL.FormActivate(Sender: TObject);
begin
      LB_PORT.Caption:=IntToStr(SP_PORT.Position);
end;


initialization
  {$I u_inicial.lrs}

end.

