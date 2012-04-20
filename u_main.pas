unit u_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, MMSystem,SysUtils,Dialogs,Windows,IniFiles,DateUtils, FileUtil, LResources, Forms, u_rs232;

  const
   CRLF=#13+#10;
   CR=#13;
   IOCTL_BUZZ_ON = 16;
   IOCTL_BUZZ_OFF= 17;
   ERRORLECTURA=-3333;
  SIPF_OFF    =	$00000000;
  SIPF_ON     =	$00000001;
  SIPF_DOCKED =	$00000002;
  SIPF_LOCKED =	$00000004;

function ActivarRele(rl:integer):integer;
function DesActivarRele(rl:integer):integer;
function RecibirDatos(var rc:string;tmout:int64;lg:integer):integer;
procedure EnviarDatos(ss:string);
procedure Bip(duracion:integer);
procedure MostrarTeclado(IPStatus:DWORD);
{$IFDEF WINCE}
function WDTClear(): WordBool; stdcall; external 'wdtn.dll' name 'WDT_Open';
function WDTStop(): WordBool; stdcall; external 'wdtn.dll' name 'WDT_Close';
function SipShowIM(IPStatus:DWORD):Integer; stdcall; external 'coredll.dll' name 'SipShowIM';
{$ENDIF}


var
beepdriver,comport:LongWord;
pitido:boolean;
implementation
//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure MostrarTeclado(IPStatus:DWORD);
begin
{$IFDEF WINCE}
SipShowIM(IPStatus);
{$ENDIF}
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure EnviarDatos(ss:string);
begin
try
WriteComP(comport,PCHAR(ss),length(ss));
finally
end;
end;
//*********************************************************************************************************
//
//
//*********************************************************************************************************
function RecibirDatos(var rc:string;tmout:int64;lg:integer):integer;
var
    vc:string;
    i,p,r:integer;
    tg:longint;
begin
tg:=GetTickCount()+tmout;

result:=0;
vc:='';
rc:=vc;
try
     repeat

          r:=Readstr(comport);
          if  r >0 then
            begin
                    vc:=vc+string(BufferRXCOM);
                    p:=Pos(#10#13,vc);
                for i:=0 to r do BufferRXCOM[i]:=#0;
                if (Length(vc)>=lg) OR (p>2) then
                  begin
                      result:=1;
                      if p>2 then rc:=copy(vc,0,p-1)
                      else rc:=vc;
                      exit;
                  end;

          end;
     until GetTickCount()>tg;
finally
//  rc:=vc;
end;
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
function ActivarRele(rl:integer):integer;
var
cd,rs:string;

begin
     result:=1;
      cd:=format('A%d',[rl])+CR;
      EnviarDatos(cd);
      RecibirDatos(rs,100,6);
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
function DesActivarRele(rl:integer):integer;
var
cd,rs:string;
begin
     result:=1;
      cd:=format('D%d',[rl])+CR;
      EnviarDatos(cd);
      RecibirDatos(rs,100,6);
end;

//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure Bip(duracion:integer);
var durante:Integer;
begin
 {$ifdef WINCE}
    If (pitido = True) and  (beepdriver <> INVALID_HANDLE_VALUE) Then
           begin
                DeviceIoControl(beepdriver, IOCTL_BUZZ_ON, nil, 0, nil, 0, nil, nil);
                durante:=duracion*500;
                while (durante>0) do
                begin
                    Application.ProcessMessages();
                    durante := durante - 1;
                end;
                DeviceIoControl(beepdriver, IOCTL_BUZZ_OFF, nil, 0, nil, 0, nil, nil);
           end;
   {$else}
   if pitido then SysUtils.Beep;
  {$endif}

end;
end.

