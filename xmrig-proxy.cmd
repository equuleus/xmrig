@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
CLS
TITLE XMRig Proxy

SET POOL_MONERO=pool.minemonero.pro
SET PORT_MONERO=5555
SET WALLET_MONERO=4...

SET POOL_SUMOKOIN=pool.sumomining.pro
SET PORT_SUMOKOIN=5555
SET WALLET_SUMOKOIN=Sumo...

SET POOL_DEFAULT=%POOL_MONERO%
SET PORT_DEFAULT=%PORT_MONERO%
SET WALLET_DEFAULT=%WALLET_MONERO%

SET DIFF=2000
SET ID=PROXY
SET EMAIL=user@server.com
SET PROXY_ADDRESS=192.168.0.1
SET PROXY_PORT=5555

SET SRC=%~dp0
SET PROGRAM_TITLE=XMRig Proxy
SET PROGRAM_PATH=%SRC:~0,-1%
SET PROGRAM_FILENAME=xmrig-proxy.exe

SET TASKKILL=%SystemRoot%\System32\taskkill.exe
SET TASKLIST=%SystemRoot%\System32\tasklist.exe

CALL :SELECT %1

SET PROGRAM_PARAMETERS=--url=%POOL%:%PORT% --user=%WALLET%+%DIFF% --pass=%ID%:%EMAIL% --keepalive --bind %PROXY_ADDRESS%:%PROXY_PORT%

SET CSCRIPT=%SystemRoot%\System32\cscript.exe

IF EXIST "%PROGRAM_PATH%\%PROGRAM_FILENAME%" (
	IF EXIST "%CSCRIPT%" (
		CALL :TEST %1
	) ELSE (
		CALL :START
	)
)
GOTO END

:SELECT
	IF "%~1" NEQ "" (
		IF "%~1" EQU "MONERO" (
			SET POOL=%POOL_MONERO%
			SET PORT=%PORT_MONERO%
			SET WALLET=%WALLET_MONERO%
		) ELSE IF "%~1" EQU "SUMOKOIN" (
			SET POOL=%POOL_SUMOKOIN%
			SET PORT=%PORT_SUMOKOIN%
			SET WALLET=%WALLET_SUMOKOIN%
		) ELSE (
			SET POOL=%POOL_DEFAULT%
			SET PORT=%PORT_DEFAULT%
			SET WALLET=%WALLET_DEFAULT%
		)
	) ELSE (
		SET POOL=%POOL_DEFAULT%
		SET PORT=%PORT_DEFAULT%
		SET WALLET=%WALLET_DEFAULT%
	)
GOTO END

:TEST
	NET SESSION >NUL 2>&1
	IF "%ERRORLEVEL%" EQU "0" (
		CALL :START
	) ELSE (
		ECHO CreateObject^("Shell.Application"^).ShellExecute "%~snx0","%~1","%~sdp0","runas","%PROGRAM_TITLE%">"%TEMP%\%PROGRAM_FILENAME%.vbs"
		%CSCRIPT% //nologo "%TEMP%\%PROGRAM_FILENAME%.vbs"
		IF EXIST "%TEMP%\%PROGRAM_FILENAME%.vbs" DEL "%TEMP%\%PROGRAM_FILENAME%.vbs"
	)
GOTO END

:START
	CALL :CHECK
	CD "%PROGRAM_PATH%"
	CALL "%PROGRAM_PATH%\%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
rem	START "%PROGRAM_TITLE%" /D "%PROGRAM_PATH%" "%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
GOTO END

:CHECK
	FOR /F "tokens=2 delims=," %%A IN ('%TASKLIST% /FI "ImageName EQ %PROGRAM_FILENAME%" /FO:CSV /NH^| FIND /I "%PROGRAM_FILENAME%"') DO SET TASK_PID=%%~A
	IF "%TASK_PID%" NEQ "" (
		%TASKKILL% /F /IM "%PROGRAM_FILENAME%">NUL
	)
GOTO END

:END
GOTO :EOF
