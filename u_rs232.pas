unit u_rs232;

interface
uses  Windows,sysutils,classes;

function IsOpenComP(hPort:longword): Boolean;
function OpenComP(nPort,velocidad:integer):longword;
procedure CloseComP(var hPort:longword);
function WriteComP(hPort:longword; sData:PChar; cuenta: integer): Boolean;
function GetInCountP(hPort:longword): LongInt;
function Readstr(hPort:LongWord): integer;
procedure FlushComP(hPort:longword);

var BufferRXCOM:PCHAR;


implementation
uses u_inicial;
//*********************************************************************************************************
//
//
//*********************************************************************************************************
function IsOpenComP(hPort:longword): Boolean;
begin
	Result := (hPort <> INVALID_HANDLE_VALUE);
end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
function OpenComP(nPort,velocidad:integer):longword;
var
        mPort:longword;
        P:Pointer;
	dcbPort: TDCB; {device control block }
begin

  {$ifdef WINCE}
  P := PWideChar(UTF8Decode('COM'+IntToStr(nPort)+':'));
  {$else}
  P := PChar('\\.\COM' + IntToStr(nPort));
  {$endif}

	mPort := CreateFile(P, GENERIC_READ or GENERIC_WRITE, 0, nil,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, Longword(0));

	{ Ajusta el BAUD RATE y el resto de los parámetros }
	if (mPort <> INVALID_HANDLE_VALUE) then
	begin
		if GetCommState(mPort, dcbPort) then
		begin
                  dcbPort.BaudRate:= velocidad;
                  dcbPort.flags:=0;
                  dcbPort.flags:= bm_DCB_fBinary;

	          //dcbPort.fDtrControl = DTR_CONTROL_DISABLE;
	          //dcbPort.fDsrSensitivity = 0;
	          //dcbPort.fTXContinueOnXoff = 0;
	          //dcbPort.fOutX = 0;
	          //dcbPort.fInX = 0;
	          //dcbPort.fErrorChar = 0;
	          //dcbPort.fNull = 0;
	          //dcbPort.fRtsControl = RTS_CONTROL_DISABLE;
	          //dcbPort.fAbortOnError = 0;
	          //dcbPort.fDummy2 = 0;
	          dcbPort.wReserved:= 0;
	          dcbPort.XonLim:= 64;
	          dcbPort.XoffLim:= 64;
	          dcbPort.ByteSize:= 8;
	          dcbPort.Parity:= 0;
	          dcbPort.StopBits:= ONESTOPBIT;
	          dcbPort.XonChar:= #$11;
	          dcbPort.XoffChar:= #$13;
	          dcbPort.ErrorChar:= #0;
	          dcbPort.EofChar:= #0;
	          dcbPort.EvtChar:= #0;
                  SetCommState(mPort, dcbPort);
		end;
	end;

	Result := mPort;

end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure CloseComP(var hPort:LongWord);
begin
	if hPort <> INVALID_HANDLE_VALUE then
   begin
    try
     CloseHandle(hPort);
    except
    end;
   end;
  hPort:=INVALID_HANDLE_VALUE;
end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
function WriteComP(hPort:LongWord; sData:PCHAR;cuenta: integer): Boolean;
var
	dwCharsWritten: DWord;
begin
	dwCharsWritten := 0;
	Result := False; { default to error return }
try
	if hPort <> INVALID_HANDLE_VALUE then
	begin
		WriteFile(hPort, sData^, cuenta, dwCharsWritten, nil);
		if Int(dwCharsWritten) = cuenta then Result := True;
	end;

finally

end;

end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
function GetInCountP(hPort:LongWord): LongInt;
var
	statPort: TCOMSTAT;
	dwErrorCode: DWord;
begin
	Result := 0;
        dwErrorCode:=0;
       try
	if hPort <> INVALID_HANDLE_VALUE then
	 begin
		ClearCommError(hPort, dwErrorCode, @statPort);
		Result := statPort.cbInQue;
	 end;

       finally
       end;
end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
function Readstr(hPort:LongWord): integer;
var
	cbCharsAvailable, cbCharsRead: DWord;

begin
	Result :=0;
         bufferRXCOM[0]:=#0;
        try
        if hPort <> INVALID_HANDLE_VALUE then
		begin
				cbCharsAvailable := GetInCountP(hPort);
                                cbCharsRead:=0;

				if cbCharsAvailable > 0 then
				begin
        			ReadFile(hPort, BufferRXCOM^, cbCharsAvailable, cbCharsRead, nil);
                                Result:= cbCharsRead;
				end;
               	end;
          finally
        end;

end;


//*********************************************************************************************************
//
//
//*********************************************************************************************************
procedure FlushComP(hPort:LongWord);
begin
	if hPort <> INVALID_HANDLE_VALUE then
	begin
		PurgeComm(hPort, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);
	end;
end;

end.
