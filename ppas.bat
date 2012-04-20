@echo off
SET THEFILE=sx16_2440_v106
echo Assembling %THEFILE%
C:\pp\bin\i386-win32\arm-wince-as.exe -mfpu=softvfp -o SX16_2440_V106.o SX16_2440_V106.s
if errorlevel 1 goto asmend
Del SX16_2440_V106.s
SET THEFILE=QX2
echo Linking %THEFILE%
C:\pp\bin\i386-win32\arm-wince-ld.exe -m arm_wince_pe  --gc-sections  -s --subsystem wince --entry=_WinMainCRTStartup    -o QX2 link.res
if errorlevel 1 goto linkend
arm-wince-postw32.exe --subsystem gui --input QX2 --stack 262144
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occured while assembling %THEFILE%
goto end
:linkend
echo An error occured while linking %THEFILE%
:end
