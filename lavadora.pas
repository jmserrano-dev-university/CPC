unit lavadora;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, cyAdvLed, cySimpleGauge, cySkinButton,
  cyMathParser, TplGnouMeterUnit, TplLCDScreenUnit, TplLEDIndicatorUnit,
  TplLed7SegUnit, TplSideBarUnit, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Grids, ColorBox, u_main, u_rs232,
  Windows;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    _lPrelavado: TLabel;
    _lLavado1: TLabel;
    _lAclarado: TLabel;
    _lLavado2: TLabel;
    _lAclarado2: TLabel;
    _lCentrifugado: TLabel;
    Led7SegIzq1: TplLed7Seg;
    ledDetergente: TcyAdvLed;
    ledTambor: TcyAdvLed;
    cyAdvLed3: TcyAdvLed;
    cyAdvLed6: TcyAdvLed;
    Label12: TLabel;
    LbNotificacion: TLabel;
    ledOnOff: TcyAdvLed;
    LedNChargue: TcyAdvLed;
    LedPort: TcyAdvLed;
    cyAdvLed4: TcyAdvLed;
    cyAdvLed5: TcyAdvLed;
    Label6: TLabel;
    Led7SegDer: TplLed7Seg;
    Led7SegIzq: TplLed7Seg;
    ProgressBar1: TProgressBar;
    ProgressTemp: TProgressBar;
    ProgressAgua: TProgressBar;
    Temperatura: TLabel;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Temporizador: TTimer;
    procedure ActualizarEntradasAnalogicas();
    procedure ActualizarEntradasDigitales();
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure Image4Click(Sender: TObject);
    procedure Image5Click(Sender: TObject);
    procedure TemporizadorTimer(Sender: TObject);
    procedure AbrirConexiones();
    procedure CerrarConexiones();
    procedure habilitarInterfaz();
    procedure deshabilitarInterfaz();

    //-- Subetapas de la lavadora
    procedure cargarAgua();
    procedure cargarDetergente(cantidad:integer);
    procedure girarTamborDerIzq(cantidad:integer;nrele:integer);
    procedure vaciadoAgua(cantidad:integer);


    //---- FASES de la lavadora
    procedure prelavado();
    procedure lavado();
    procedure aclarado();
    procedure centrifugado();
    procedure stop();
    //---- FIN de FASES de la lavadora

    //--- INICIO de Procedimientos de control
    procedure detenerRelog();
    procedure continuarRelog();
    procedure mostrarNotificacion(cadena:String; col:TColor);
    procedure desActivarLedsIndicadores();
    procedure limpiarColorEtiquetas();
    procedure colorearEtiqueta(etiqueta:TLabel);
    //--- FIN de Procedimientos de control

  private
    { private declarations }
  public
    { public declarations }
  end;

var
   Form2: TForm2;
   puertoAbierto: Boolean;
   puerto: Integer;
   //
   primeraEntradaFase: Boolean;
   TempGlobal: integer;  //Tiempo global de duración del programa
   TempFase: integer;    //Tiempo parcial de duración de una fase
   MaximoTemperatura: integer;   //Nivel maximo de temperatura
   MaximoNivelAgua: integer;     //Nivel maximo de agua
   TiempoEspera: integer;        //Tiempo de espera para conseguir temperatura
   Temperatura: integer;       //
   Comenzar: boolean; //Variable que indica el inicio del lavado

   //Variable que muestra la variable por la que nos encontramos
   Fase: integer;
   //Variables prelavado
   Programa: integer;     //Programa seleccionado en relación a la carga de la lavadora
   comprobacionAgua: Boolean;

   //Variable para el control del relog -> Controlando detenciones por errores
   continueClock: Boolean;
   detenido: Boolean;

implementation


{ TForm2 }

procedure TForm2.FormActivate(Sender: TObject);
var P:pointer;
   i:integer;
begin

 //Inicializaciones
   detenido:=false;
 puerto:=4;
 Comenzar:=false;
 Fase:=1;
 TempGlobal:=0;
 primeraEntradaFase:= true;
 MaximoTemperatura:=80;
 MaximoNivelAgua:=10;
 TiempoEspera:=5;
 continueClock:=true; //Variable para controlar el funcionamiento del reloj

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
  deshabilitarInterfaz();
  AbrirConexiones();
end;

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   DesActivarRele(0);
   DesActivarRele(1);
   DesActivarRele(2);
   DesActivarRele(3);
   DesActivarRele(4);
   DesActivarRele(5);
   CerrarConexiones();
end;

procedure TForm2.Image4Click(Sender: TObject);
begin

end;

procedure TForm2.Image5Click(Sender: TObject);
begin

end;




procedure TForm2.AbrirConexiones();
BEGIN

     comport:=OpenComP(puerto,115200);
        if comport =INVALID_HANDLE_VALUE then
         begin
         ShowMessage('ERROR. No se puede abrir el puerto seleccionado COM'+inttostr(puerto));
         exit;
         end
        else
        begin
           Temporizador.Enabled:=TRUE;
        end;
end;

procedure TForm2.CerrarConexiones();
BEGIN
    if (comport<>INVALID_HANDLE_VALUE) then
            begin
            CloseComp(comport);


        Temporizador.Enabled:=FALSE;
        exit;
        end;
end;

procedure TForm2.desActivarLedsIndicadores();
begin
          DesActivarRele(0);
          DesActivarRele(1);
          DesActivarRele(2);
          DesActivarRele(4);
          DesActivarRele(5);
          ledDetergente.LedValue:=false;
          ledTambor.LedValue:=false;
          cyAdvLed3.LedValue:=false;
          cyAdvLed6.LedValue:=false;
          cyAdvLed4.LedValue:=false;
          cyAdvLed5.LedValue:=false;



end;

procedure TForm2.ActualizarEntradasAnalogicas();
var lct,i:integer;
  cd,rs:string;
begin
    for i:=0 to 2 do
    begin
    rs:='';
    cd:=format('AD%d',[i])+CR;
    EnviarDatos(cd);
    RecibirDatos(rs,100,6);
    lct:=StrToIntdef(rs,0);
    case i of
        0:
          begin
          ProgressAgua.Position:=lct;
          end;
        1:
          begin
          ProgressTemp.Position:=lct;
          end;
        2:
          begin
          //Temperatura:=lct;
          ProgressBar1.Position:=140;
          Label12.Caption:=rs;
          end;

    end;

    end;

end;

procedure TForm2.limpiarColorEtiquetas();
begin
    _lPrelavado.Color:=clNone;
    _lLavado1.Color:=clNone;
    _lAclarado.Color:=clNone;
    _lAclarado2.Color:=clNone;
    _lCentrifugado.Color:=clNone;
    _lLavado2.Color:=clNone;

end;

procedure TForm2.colorearEtiqueta(etiqueta:TLabel);
begin
    limpiarColorEtiquetas();
    etiqueta.Color:=clLime;
end;

procedure TForm2.TemporizadorTimer(Sender: TObject);
begin
     Temporizador.Enabled:=False;
     ActualizarEntradasAnalogicas();
     ActualizarEntradasDigitales();
     if ledOnOff.LedValue = true then
        BEGIN
             habilitarInterfaz(); //Habilitamos la intefaz

        end
     else
         BEGIN
         deshabilitarInterfaz(); //Desahabilitamos la interfaz
         //Reiniciamos todo el proceso

         end;
     //Comprobación de paso por fases
     if Comenzar = true then
     BEGIN
     Led7SegIzq1.Value:= TempGlobal div 100;
     Led7SegIzq.Value:= (TempGlobal mod 100) div 10;
     Led7SegDer.Value:= (TempGlobal mod 100) mod 10;
     Begin
     //Programas

     if ledOnOff.LedValue = true then
     BEGIN
     if detenido =true then
     BEGIN
        detenido:=false;
        continuarRelog();
        DesActivarRele(3);
     end;
     if LedPort.LedValue = false then
     BEGIN
     //Programa 1 - Carga Completa
     if LedNChargue.LedValue = true then
     BEGIN
       case Fase of
          1:
            begin
                 colorearEtiqueta(_lPrelavado);
                 prelavado();
            end;
          2:
            begin
                 colorearEtiqueta(_lLavado1);
                 lavado();
            end;
          3:
            begin
                 colorearEtiqueta(_lAclarado);
                 aclarado();
            end;
          4:
            begin
                 colorearEtiqueta(_lLavado2);
                 lavado();
            end;
          5:
            begin
                 colorearEtiqueta(_lAclarado2);
                 aclarado();
            end;
          6:
            begin
                 colorearEtiqueta(_lCentrifugado);
                 centrifugado();
            end;
          7:
            begin
                 limpiarColorEtiquetas();
                 stop();
            end;
          8:
            BEGIN
            Button2.Enabled:=true;
            if Led7SegDer.IsEnabled then
            BEGIN
            Led7SegDer.Enabled:=false;
            Led7SegIzq.Enabled:=false;
            Led7SegIzq1.Enabled:=false;
            end
            else
              BEGIN
               Led7SegDer.Enabled:=true;
               Led7SegIzq.Enabled:=true;
               Led7SegIzq1.Enabled:=true;
              end;

            end;

       end;
       end
     else
         BEGIN
          case Fase of
          1:
            begin
                 colorearEtiqueta(_lPrelavado);
                 prelavado();
            end;
          2:
            begin
                 colorearEtiqueta(_lLavado1);
                 lavado();
            end;
          3:
            begin
                 colorearEtiqueta(_lAclarado);
                 aclarado();
            end;
          4:
            begin
                 colorearEtiqueta(_lCentrifugado);
                 centrifugado();
            end;
          5:
            begin
                 limpiarColorEtiquetas();
                 stop();
            end;
          6:
            BEGIN
            Button2.Enabled:=true;
            if Led7SegDer.IsEnabled then
            BEGIN
            Led7SegDer.Enabled:=false;
            Led7SegIzq.Enabled:=false;
            Led7SegIzq1.Enabled:=false;
            end
            else
              BEGIN
               Led7SegDer.Enabled:=true;
               Led7SegIzq.Enabled:=true;
               Led7SegIzq1.Enabled:=true;
              end;


         end;
          end;
          end;
         end
     else
     BEGIN
          TempFase:=0;
          desActivarLedsIndicadores();
            ActivarRele(3);
          detenido:= true;
          detenerRelog();
          mostrarNotificacion('La puerta se encuentra abierta', Tcolor($0000FF));
     end;
     end
     else
     BEGIN

          Comenzar:=false;
          TempGlobal:=0;
          Fase:=1;
          TempFase:=0;
          //detenerRelog();
          //detenido:=true;
          desActivarLedsIndicadores();
          mostrarNotificacion('Proceso de lavado interrumpido', Tcolor($0000FF));
          Button2.Enabled:=true;
          Temporizador.Enabled:=false;
     end;
     end;
end;

     Temporizador.Enabled:=TRUE;
end;

//Control de relog

procedure TForm2.detenerRelog();
BEGIN
    continueClock:=false;
    Led7SegIzq.DimColor:=TColor($000044);
    Led7SegDer.DimColor:=TColor($000044);
    Led7SegIzq1.DimColor:=TColor($000044);

    Led7SegIzq.BrightColor:=TColor($0000FF);
    Led7SegDer.BrightColor:=TColor($0000FF);
    Led7SegIzq1.BrightColor:=TColor($0000FF);
end;

procedure TForm2.continuarRelog();
BEGIN
    continueClock:=true;
    Led7SegIzq.DimColor:=TColor($008000);
    Led7SegDer.DimColor:=TColor($008000);
    Led7SegIzq1.DimColor:=TColor($008000);

    Led7SegIzq.BrightColor:=TColor($00FF00);
    Led7SegDer.BrightColor:=TColor($00FF00);
    Led7SegIzq1.BrightColor:=TColor($00FF00);
end;

//Habilitaciones y deshabilitaciones de interfaz

procedure TForm2.habilitarInterfaz();
BEGIN
   LedPort.Enabled:=true;
   LedNChargue.Enabled:=true;
   ProgressAgua.Show;
   ProgressTemp.Show;
   cyAdvLed4.Show;
   cyAdvLed5.Show;
   ledDetergente.Show;
   ledTambor.Show;
   cyAdvLed3.Show;
   cyAdvLed6.Show;
   Panel1.Enabled:=true;
   Panel2.Enabled:=true;
   Panel3.Enabled:=true;
   Panel4.Enabled:=true;
   Panel5.Enabled:=true;
end;

procedure TForm2.deshabilitarInterfaz();
BEGIN
   LedPort.Enabled:=false;
   LedNChargue.Enabled:=false;
   ProgressAgua.Hide;
   ProgressTemp.Hide;
   cyAdvLed4.Hide;
   cyAdvLed5.Hide;
   ledDetergente.Hide;
   ledTambor.Hide;
   cyAdvLed3.Hide;
   cyAdvLed6.Hide;
   //Panel1.Enabled:=false;
   Panel2.Enabled:=false;
   Panel3.Enabled:=false;
   Panel4.Enabled:=false;
   Panel5.Enabled:=false;
end;

//Notificaciones
procedure TForm2.mostrarNotificacion(cadena:String; col:TColor);
BEGIN
    LbNotificacion.Font.Color:=col;
    LbNotificacion.Caption:=cadena;
end;


// ------------------------------ Fases de cada programa


procedure TForm2.prelavado();

begin

   if TempFase < 15 then cargarAgua();
   if (TempFase >= 15) AND (TempFase <= 20) then cargarDetergente(20);
   if (TempFase >20) AND (TempFase <= 25) then girarTamborDerIzq(25,4);
   if (TempFase >25) AND (TempFase <= 30) then girarTamborDerIzq(30,3);
   if (TempFase >30) AND (TempFase <= 38) then vaciadoAgua(38);
   if TempFase = 39 then    //Pasamos a la siguiente fase
      BEGIN
           Fase:=Fase+1;
           TempFase:=0;
      end;
end;

procedure TForm2.lavado();
BEGIN

   if TempFase < 15 then cargarAgua();
   if (TempFase >=15) AND (TempFase <=20) then cargarDetergente(20);
   if (TempFase >20) AND (TempFase <= 25) then girarTamborDerIzq(25,4);
   if (TempFase >25) AND (TempFase <= 30) then girarTamborDerIzq(30,3);
   if (TempFase >30) AND (TempFase <= 35) then girarTamborDerIzq(35,4);
   if (TempFase >35) AND (TempFase <= 40) then girarTamborDerIzq(40,3);
   if (TempFase >40) AND (TempFase <= 48) then vaciadoAgua(48);
   if TempFase = 49 then    //Pasamos a la siguiente fase
      BEGIN
           Fase:=Fase+1;
           TempFase:=0;
      end;

end;


procedure TForm2.aclarado();
BEGIN
   if TempFase < 15 then cargarAgua();
   if (TempFase >=15) AND (TempFase <= 20) then girarTamborDerIzq(20,4);
   if (TempFase >20) AND (TempFase <= 25) then girarTamborDerIzq(25,3);
   if (TempFase >25) AND (TempFase <= 30) then girarTamborDerIzq(30,4);
   if (TempFase >30) AND (TempFase <= 35) then girarTamborDerIzq(35,3);
   if (TempFase >35) AND (TempFase <= 43) then vaciadoAgua(43);
   if TempFase = 44 then    //Pasamos a la siguiente fase
      BEGIN
           Fase:=Fase+1;
           TempFase:=0;
      end;
end;

procedure TForm2.centrifugado();
BEGIN
   if TempFase < 5  then girarTamborDerIzq(5,4);
   if (TempFase >=5) AND (TempFase <= 10)  then girarTamborDerIzq(10,3);
   if (TempFase >10) AND (TempFase <= 15)  then girarTamborDerIzq(15,4);
   if (TempFase >15) AND (TempFase <= 20)  then girarTamborDerIzq(20,3);
   if TempFase = 21 then    //Pasamos a la siguiente fase
      BEGIN
           Fase:=Fase+1;
           TempFase:=0;
      end;

end;

procedure TForm2.stop();
BEGIN
     if TempFase <= 8 then vaciadoAgua(8);
     if TempFase = 9 then
        BEGIN
           Fase:=Fase+1;
           TempFase:=0;
      end;
end;

//------------------------------ FIN de Fases intermedias



//Carga del agua y calentamiento de la misma
procedure TForm2.cargarAgua();
begin
     if primeraEntradaFase = true then
      begin
          primeraEntradaFase:=false;
          TempFase:=0;
          mostrarNotificacion('Comienzo de Prelavado',TColor($FF0000));
          //LbNotificacion.Caption:='Comienzo de Prelavado';
          if  LedNChargue.LedValue = true then
           BEGIN
           Programa:=1;
           end
          else
           Programa:=0;
      end
     else
      begin
      if TempFase < 10 then
       begin
         if TempFase < 5 then
          BEGIN
           LbNotificacion.Font.Color:=TColor($008000);
           mostrarNotificacion('Calentando agua',TColor($FF0000));
           //LbNotificacion.Caption:='Calentando agua';
           cyAdvLed6.LedValue:=true; //Encedemos led de calentador
           ActivarRele(5);
           END;

           if TempFase = 5 then
            BEGIN
                if ProgressTemp.Position > 500 then
                 BEGIN
                   cyAdvLed6.LedValue:=false; //Apagamos led de calentador
                   DesActivarRele(5);
                   cyAdvLed4.LedValue:=false;
                   comprobacionAgua:=true;
                   mostrarNotificacion('Lectura temperatura correcta',TColor($FF0000));
                   //LbNotificacion.Caption:='Lectura temperatura correcta';
                   ActivarRele(0);
                   cyAdvLed3.LedValue:=true;
                   continuarRelog();

;
                 END
                else
                 BEGIN
                   TempFase:=4;
                   cyAdvLed4.LedValue:=true; //Si tras 5 seg no se alcanza la temperatura mostramos error
                   //LbNotificacion.Caption:='Temperatura incorrecta';
                   mostrarNotificacion('Temperatura incorrecta',TColor($0000FF));
                   detenerRelog();
                 end;
                 end;
            end;
       TempFase:=TempFase+1;

       end;
      if TempFase =15 then
       BEGIN
          cyAdvLed6.LedValue:=false;
          if Programa = 0 then
           BEGIN
               if ProgressAgua.Position < 250 then
                BEGIN
                  cyAdvLed5.LedValue:=True;
                  TempFase:=6;
                  //LbNotificacion.Caption:='Nivel de agua incorrecto';
                  mostrarNotificacion('Nivel de agua incorrecto',TColor($0000FF));
                  detenerRelog();

                end
               else
                BEGIN
                  cyAdvLed5.LedValue:=False;
                  //LbNotificacion.Caption:='Nivel de agua correcto';
                  mostrarNotificacion('Nivel de agua correcto',TColor($FF0000));
                   cyAdvLed3.LedValue:=false;
                  //Fase:=2;
                  //TempFase:=0;
                  primeraEntradaFase:=true;
                  continuarRelog();
                  TempGlobal:=TempGlobal-1;
                  DesActivarRele(0);
                end;

           end
          else
           BEGIN
             if ProgressAgua.Position < 500 then
                BEGIN
                  cyAdvLed5.LedValue:=True;
                   //LbNotificacion.Caption:='Nivel de agua incorrecto';
                   mostrarNotificacion('Nivel de agua incorrecto',TColor($0000FF));
                  TempFase:=10; //Modificado para que no tarde tanto tiempo
                  detenerRelog();
                  END
               else
                BEGIN
                  cyAdvLed5.LedValue:=False;
                  //LbNotificacion.Caption:='Nivel de agua correcto';
                  mostrarNotificacion('Nivel de agua correcto',TColor($FF0000));
                  //Fase:=2;
                  //TempFase:=0;
                  cyAdvLed3.LedValue:=false;
                  primeraEntradaFase:=true;
                  continuarRelog();
                  TempGlobal:=TempGlobal-1;
                  DesActivarRele(0);
                end;
           end;
       end;

             if continueClock = true then TempGlobal:=TempGlobal+1;
      end;
//end.



procedure TForm2.cargarDetergente(cantidad:integer);
BEGIN


     if TempFase < cantidad then
        begin
          TempFase:=TempFase+1 ;
          ledDetergente.LedValue:=true;
          //LbNotificacion.Caption:='Añadiendo detergente';
          mostrarNotificacion('Añadiendo detergente',TColor($FF0000));
          ActivarRele(1);
        end
     else
     BEGIN
     if TempFase = cantidad then
        begin
          ledDetergente.LedValue:=false;
          TempGlobal:=TempGlobal -1;
          TempFase:=TempFase+1;
          DesActivarRele(1);
        end;
     end;

      if continueClock = true then TempGlobal:=TempGlobal+1;

end;

procedure TForm2.girarTamborDerIzq(cantidad:integer;nrele:integer);
BEGIN
      if TempFase < cantidad then
         BEGIN
           TempFase:=TempFase+1;
           ledTambor.LedValue:=true;
           //LbNotificacion.Caption:='Girando tambor';
           mostrarNotificacion('Girando tambor',TColor($FF0000));
           ActivarRele(5);
         end
       else
       BEGIN
      if TempFase = cantidad then
         BEGIN
           ledTambor.LedValue:=false;
           TempGlobal:=TempGlobal -1;
           TempFase:=TempFase+1;
           DesActivarRele(5);
         end;
       end;
          if continueClock = true then TempGlobal:=TempGlobal+1;
end;

procedure TForm2.vaciadoAgua(cantidad:integer);
BEGIN
     if TempFase < cantidad then
        BEGIN
         cyAdvLed3.LedValue:=true;
         TempFase:=TempFase+1;
         //LbNotificacion.caption:='Vaciando agua';
         mostrarNotificacion('Vaciando agua',TColor($FF0000));
         ActivarRele(3);
        end
      else
      BEGIN
     if TempFase =  cantidad then
        BEGIN
         if ProgressAgua.Position <70 then
            BEGIN
               cyAdvLed5.LedValue:=false;
               cyAdvLed3.LedValue:=false;
               //LbNotificacion.caption:='Tambor vaciado';
               mostrarNotificacion('Tambor vaciado',TColor($FF0000));
               continuarRelog();
               TempFase:=TempFase+1;
               DesActivarRele(3);
             end
         else
             BEGIN
               cyAdvLed3.LedValue:=true;
               cyAdvLed5.LedValue:=true;
               //LbNotificacion.caption:='Error desagüe';
               mostrarNotificacion('Error desagüe',TColor($FF0000));
               TempFase:=TempFase-5;
               detenerRelog();


             end;
         end;
      end;
      if continueClock = true then TempGlobal:=TempGlobal+1;
end;


procedure TForm2.ActualizarEntradasDigitales();
var lct,r,i,msk:integer;
  cd,rs:string;
  st:boolean;
begin
    rs:='';
    EnviarDatos('E*'+CR);
    RecibirDatos(rs,100,6);
    lct:=StrToIntdef(rs,-1);
    msk:=1;
    for i:=0 to 2 do
    begin
    r:=msk and lct;
    st:=false;
    if r=0 then  st:=true;
    case i of
        0:   ledOnOff.LedValue:=st;
        1:   LedPort.LedValue:=st;
        2:   LedNChargue.LedValue:=st;
    end;
    msk:=msk*2;
    end;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
//        if (comport<>INVALID_HANDLE_VALUE) then
    CerrarConexiones();
    CloseComp(comport);
    Temporizador.Enabled:=FALSE;
    Comenzar:=false;
    ExitProcess(0);


end;


procedure TForm2.Button2Click(Sender: TObject);
begin
     desActivarLedsIndicadores();
   Temporizador.Enabled:=TRUE;
   Comenzar:=true;
   Fase:=1;
   TempFase:=0;
   TempGlobal:=0;
   Button2.Enabled:=false;


end;









initialization
  puertoAbierto:=false;
  {$I lavadora.lrs}

end.

