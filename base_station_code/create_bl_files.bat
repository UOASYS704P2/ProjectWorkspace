@echo off

:: THIS FILE IS GENERATED BY APPBUILDER, DO NOT MODIFY
:: CONFIGURE VIA ENV VARS

:: use PATH_GCCARM env var to override default path for gcc-arm
if "%PATH_GCCARM%"=="" (
  set OBJCOPY="D:\SiliconLabs\SimplicityStudio\v4\developer\toolchains\gnu_arm\4.9_2015q3\bin\arm-none-eabi-objcopy.exe"
) else (
  set OBJCOPY=%PATH_GCCARM%\bin\arm-none-eabi-objcopy.exe
)

:: use PATH_SCMD env var to override default path for Simplicity Commander
if "%PATH_SCMD%"=="" (
  set COMMANDER="D:\SiliconLabs\SimplicityStudio\v4\developer\adapter_packs\commander\commander.exe"
) else (
  set COMMANDER=%PATH_SCMD%\commander.exe
)

:: use PATH_OUT env var to override the full path for the .out file

:: default file extension of GCC and IAR
set FILE_EXTENSION_GCC="*.axf"
set FILE_EXTENSION_IAR="*.out"

:: output path of the OTA and UART DFU ebl and gbl files (relative to project root)
set PATH_EBL=output_ebl
set PATH_GBL=output_gbl

:: names of the OTA and UART DFU output files
set OTA_STACK_NAME=stack
set OTA_APP_NAME=app
set UARTDFU_FULL_NAME=full

:: names of the sign and encypt key files
set GBL_SIGING_KEY_FILE=app-sign-key.pem
set GBL_ENCRYPT_KEY_FILE=app-encrypt-key.txt

:: change the working dir to the dir of the batch file, which should be in the project root
cd %~dp0

for /f "delims=" %%i in ('dir *.axf *.out /b/s') do set PATH_OUT=%%i
if "%PATH_OUT%"=="" (
  echo "Error: neither %FILE_EXTENSION_GCC% nor %FILE_EXTENSION_IAR% found"
  echo Was the project compiled and linked successfully?
  pause
  goto:eof
)

if not exist "%OBJCOPY%" (
  echo Error: gcc-arm objcopy not found at '%OBJCOPY%'
  echo Use PATH_GCCARM env var to override default path for gcc-arm.
  pause
  goto:eof
)

if not exist "%COMMANDER%" (
  echo Error: Simplicity Commander not found at '%COMMANDER%'
  echo Use PATH_SCMD env var to override default path for Simplicity Commander.
  pause
  goto:eof
)

echo **********************************************************************
echo Converting .out to .ebl files
echo **********************************************************************
echo.
echo .out file used:
echo %PATH_OUT%
echo.
echo output folders:
echo %~dp0%PATH_EBL%
echo %~dp0%PATH_GBL%

if not exist %PATH_EBL% (
  mkdir %PATH_EBL%
)
if not exist %PATH_GBL% (
  mkdir %PATH_GBL%
)

:: create the EBL & GBL files
echo.
echo **********************************************************************
echo Creating %OTA_STACK_NAME%.ebl and %OTA_STACK_NAME%.gbl for OTA
echo **********************************************************************
echo.
%OBJCOPY% -O srec -j .text_stack* "%PATH_OUT%" "%PATH_EBL%\%OTA_STACK_NAME%.srec"
if errorlevel 1 (
  pause
  goto:eof
)
%COMMANDER% ebl create "%PATH_EBL%\%OTA_STACK_NAME%.ebl" --app "%PATH_EBL%\%OTA_STACK_NAME%.srec" -d EFR32F256
%COMMANDER% gbl create "%PATH_GBL%\%OTA_STACK_NAME%.gbl" --app "%PATH_EBL%\%OTA_STACK_NAME%.srec"

echo.
echo **********************************************************************
echo Creating %OTA_APP_NAME%.ebl and %OTA_APP_NAME%.gbl for OTA
echo **********************************************************************
echo.
%OBJCOPY% -O srec -j .text_app* "%PATH_OUT%" "%PATH_EBL%\%OTA_APP_NAME%.srec"
if errorlevel 1 (
  pause
  goto:eof
)
%COMMANDER% ebl create "%PATH_EBL%\%OTA_APP_NAME%.ebl" --app "%PATH_EBL%\%OTA_APP_NAME%.srec" -d EFR32F256
%COMMANDER% gbl create "%PATH_GBL%\%OTA_APP_NAME%.gbl" --app "%PATH_EBL%\%OTA_APP_NAME%.srec"

:: create the full EBL & GBL files for UART DFU
echo.
echo **********************************************************************
echo Creating %UARTDFU_FULL_NAME%.ebl and %UARTDFU_FULL_NAME%.gbl for UART DFU
echo **********************************************************************
echo.
%OBJCOPY% -O srec -R .text_bootloader* "%PATH_OUT%" "%PATH_EBL%\%UARTDFU_FULL_NAME%.srec"
if errorlevel 1 (
  pause
  goto:eof
)
%COMMANDER% ebl create "%PATH_EBL%\%UARTDFU_FULL_NAME%.ebl" --app "%PATH_EBL%\%UARTDFU_FULL_NAME%.srec" -d EFR32F256
%COMMANDER% gbl create "%PATH_GBL%\%UARTDFU_FULL_NAME%.gbl" --app "%PATH_EBL%\%UARTDFU_FULL_NAME%.srec"

:: create encrypted GBL file for secure boot if encrypt-key file exist
if exist %GBL_ENCRYPT_KEY_FILE% (
  echo.
  echo **********************************************************************
  echo Creating encrypted .gbl files
  echo **********************************************************************
  echo.
  %COMMANDER% gbl create "%PATH_GBL%\%OTA_STACK_NAME%-encrypted.gbl" --app "%PATH_EBL%\%OTA_STACK_NAME%.srec" --encrypt %GBL_ENCRYPT_KEY_FILE%
  echo.
  %COMMANDER% gbl create "%PATH_GBL%\%OTA_APP_NAME%-encrypted.gbl" --app "%PATH_EBL%\%OTA_APP_NAME%.srec" --encrypt %GBL_ENCRYPT_KEY_FILE%
  echo.
  %COMMANDER% gbl create "%PATH_GBL%\%UARTDFU_FULL_NAME%-encrypted.gbl" --app "%PATH_EBL%\%UARTDFU_FULL_NAME%.srec" --encrypt %GBL_ENCRYPT_KEY_FILE%
)

:: create signed GBL file for secure boot if sign-key file exists
if exist %GBL_SIGING_KEY_FILE% (
  echo.
  echo **********************************************************************
  echo Creating signed .gbl files
  echo **********************************************************************
  echo.
  %COMMANDER% convert "%PATH_EBL%\%OTA_STACK_NAME%.srec" --secureboot --keyfile %GBL_SIGING_KEY_FILE% -o "%PATH_EBL%\%OTA_STACK_NAME%-signed.srec"
  %COMMANDER% gbl create "%PATH_GBL%\%OTA_STACK_NAME%-signed.gbl" --app "%PATH_EBL%\%OTA_STACK_NAME%-signed.srec" --sign %GBL_SIGING_KEY_FILE%
  echo.
  %COMMANDER% convert "%PATH_EBL%\%OTA_APP_NAME%.srec" --secureboot --keyfile %GBL_SIGING_KEY_FILE% -o "%PATH_EBL%\%OTA_APP_NAME%-signed.srec"
  %COMMANDER% gbl create "%PATH_GBL%\%OTA_APP_NAME%-signed.gbl" --app "%PATH_EBL%\%OTA_APP_NAME%-signed.srec" --sign %GBL_SIGING_KEY_FILE%
  echo.
  %COMMANDER% convert "%PATH_EBL%\%UARTDFU_FULL_NAME%.srec" --secureboot --keyfile %GBL_SIGING_KEY_FILE% -o "%PATH_EBL%\%UARTDFU_FULL_NAME%-signed.srec"
  %COMMANDER% gbl create "%PATH_GBL%\%UARTDFU_FULL_NAME%-signed.gbl" --app "%PATH_EBL%\%UARTDFU_FULL_NAME%-signed.srec" --sign %GBL_SIGING_KEY_FILE%
  
  :: create signed and encrypted GBL file for if both sign-key and encrypt-key file exist
  if exist %GBL_ENCRYPT_KEY_FILE% (
    echo.
    echo **********************************************************************
    echo Creating signed and encrypted .gbl files
    echo **********************************************************************
    echo.
    %COMMANDER% gbl create "%PATH_GBL%\%OTA_STACK_NAME%-signed-encrypted.gbl" --app "%PATH_EBL%\%OTA_STACK_NAME%-signed.srec" --encrypt %GBL_ENCRYPT_KEY_FILE% --sign %GBL_SIGING_KEY_FILE%
    echo.
    %COMMANDER% gbl create "%PATH_GBL%\%OTA_APP_NAME%-signed-encrypted.gbl" --app "%PATH_EBL%\%OTA_APP_NAME%-signed.srec" --encrypt %GBL_ENCRYPT_KEY_FILE% --sign %GBL_SIGING_KEY_FILE%
    echo.
    %COMMANDER% gbl create "%PATH_GBL%\%UARTDFU_FULL_NAME%-signed-encrypted.gbl" --app "%PATH_EBL%\%UARTDFU_FULL_NAME%-signed.srec" --encrypt %GBL_ENCRYPT_KEY_FILE% --sign %GBL_SIGING_KEY_FILE%
  )
)

:: clean up output dir
del "%PATH_EBL%\*.srec"

pause