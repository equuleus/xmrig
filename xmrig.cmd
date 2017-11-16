@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
CLS
TITLE XMRig

SET URL=pool.monero.hashvault.pro
SET PORT=5555
SET WALLET=4...
SET ID=%COMPUTERNAME%
SET EMAIL=user@server.com

SET ALLOW_MANUAL_SELECT=true

SET SRC=%~dp0
SET PROGRAM_TITLE=XMRig
SET PROGRAM_PATH=%SRC:~0,-1%
SET PROGRAM_CPU_FILENAME=xmrig.exe
SET PROGRAM_NVIDIA_FILENAME=xmrig-nvidia.exe
SET PROGRAM_AMD_FILENAME=xmrig-amd.exe
SET PROGRAM_PARAMETERS=--algo=cryptonight --url=%URL%:%PORT% --keepalive --retries=5 --retry-pause=5 --donate-level=1 --nicehash 

REM SETTINGS FOR: INTEL Core i7 3770k-4770k-7770k:
SET PROGRAM_CPU_PARAMETERS=--av=1 --threads=4 --cpu-affinity=0xAA --cpu-priority=5
REM SETTINGS FOR: 2 x NVIDIA GTX 750ti:
SET PROGRAM_NVIDIA_PARAMETERS=--cuda-launch=24x10 --cuda-bfactor=6 --cuda-bsleep=50
REM SETTINGS FOR: NVIDIA GTX 960:
rem SET PROGRAM_NVIDIA_PARAMETERS=--cuda-devices=0 --cuda-launch=32x24 --cuda-bfactor=6 --cuda-bsleep=50
REM SETTINGS FOR: NVIDIA GTX TITAN:
rem SET PROGRAM_NVIDIA_PARAMETERS=--cuda-devices=0 --cuda-launch=32x16 --cuda-bfactor=6 --cuda-bsleep=50
REM SETTINGS FOR: AMD Radeon RX Vega 64:
SET PROGRAM_AMD_PARAMETERS=--opencl-devices=0 --opencl-launch=2016x8 --opencl-platform=2 --opencl-devices=0 --opencl-launch=1600x8 --opencl-platform=2

SET PROGRAM_CPU_DIFF=10000
SET PROGRAM_NVIDIA_DIFF=20000
SET PROGRAM_AMD_DIFF=50000

SET TASKKILL=%SystemRoot%\System32\taskkill.exe
SET TASKLIST=%SystemRoot%\System32\tasklist.exe
SET CSCRIPT=%SystemRoot%\System32\cscript.exe
SET TIMEOUT=%SystemRoot%\System32\timeout.exe
REM DEVCON you can find here: https://networchestration.wordpress.com/2016/07/11/how-to-obtain-device-console-utility-devcon-exe-without-downloading-and-installing-the-entire-windows-driver-kit-100-working-method/
REM 32: https://download.microsoft.com/download/7/D/D/7DD48DE6-8BDA-47C0-854A-539A800FAA90/wdk/Installers/82c1721cd310c73968861674ffc209c9.cab
REM Download 82c1721cd310c73968861674ffc209c9.cab, extract the file “fil5a9177f816435063f779ebbbd2c1a1d2”, and rename it to “devcon.exe”. (download size: 7.09 MB)
REM 64: https://download.microsoft.com/download/7/D/D/7DD48DE6-8BDA-47C0-854A-539A800FAA90/wdk/Installers/787bee96dbd26371076b37b13c405890.cab
REM Download 787bee96dbd26371076b37b13c405890.cab, extract the file “filbad6e2cce5ebc45a401e19c613d0a28f”, and rename it to “devcon.exe”. (download size: 7.53 MB)
SET DEVCON=%SRC%\devcon.exe

IF "%1" EQU "ELEVATE" (
	CALL :SELECT %2 %3
) ELSE (
	CALL :SELECT %1 %2
)
IF "%PARAMETER%" EQU "CPU" (
	SET PROGRAM_PATH=%PROGRAM_PATH%\CPU
	SET PROGRAM_FILENAME=%PROGRAM_CPU_FILENAME%
	SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% %PROGRAM_CPU_PARAMETERS%
)
IF "%PARAMETER%" EQU "NVIDIA" (
	SET PROGRAM_PATH=%PROGRAM_PATH%\NVIDIA
	SET PROGRAM_FILENAME=%PROGRAM_NVIDIA_FILENAME%
	SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% %PROGRAM_NVIDIA_PARAMETERS%
)
IF "%PARAMETER%" EQU "AMD" (
	SET PROGRAM_PATH=%PROGRAM_PATH%\AMD
	SET PROGRAM_FILENAME=%PROGRAM_AMD_FILENAME%
	SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% %PROGRAM_AMD_PARAMETERS%
)
CLS
IF "%PROGRAM_FILENAME%" EQU "" GOTO END
IF EXIST "%PROGRAM_PATH%\%PROGRAM_FILENAME%" (
	IF EXIST "%CSCRIPT%" (
		IF "%1" EQU "ELEVATE" (
			CALL :TEST "ELEVATE" "%PARAMETER%" "%ACTION%"
		) ELSE (
			CALL :TEST "NONE" "%PARAMETER%" "%ACTION%"
		)
	) ELSE (
		ECHO.
		ECHO ERROR: Can not find "%CSCRIPT%".
		CALL :START
	)
)
GOTO END

:SELECT
	IF "%~1" NEQ "" (
		IF "%~1" EQU "CPU" (
			SET PARAMETER=CPU
		) ELSE IF "%~1" EQU "NVIDIA" (
			SET PARAMETER=NVIDIA
		) ELSE IF "%~1" EQU "AMD" (
			SET PARAMETER=AMD
		) ELSE IF "%~1" EQU "START" (
			SET ACTION=START
		) ELSE IF "%~1" EQU "STOP" (
			SET ACTION=STOP
		)
	)
	IF "%~2" NEQ "" (
		IF "%~2" EQU "CPU" (
			SET PARAMETER=CPU
		) ELSE IF "%~2" EQU "NVIDIA" (
			SET PARAMETER=NVIDIA
		) ELSE IF "%~2" EQU "AMD" (
			SET PARAMETER=AMD
		) ELSE IF "%~2" EQU "START" (
			SET ACTION=START
		) ELSE IF "%~2" EQU "STOP" (
			SET ACTION=STOP
		)
	)
	IF "%ALLOW_MANUAL_SELECT%" NEQ "true" GOTO END
	IF "%PARAMETER%" EQU "" (
		SET /P PARAMETER="Please select a program [CPU/NVIDIA/AMD]: "
	)
	IF "%PARAMETER%" NEQ "CPU" (
		IF "%PARAMETER%" NEQ "NVIDIA" (
			IF "%PARAMETER%" NEQ "AMD" (
				SET PARAMETER=
				ECHO Select is not correct. Please input "CPU", "NVIDIA" or "AMD". Try again...
				ECHO.
				GOTO :SELECT
			)
		)
	)
	IF "%ACTION%" EQU "" (
		SET /P ACTION="Please select an action [START/STOP]: "
	)
	IF "%ACTION%" NEQ "START" (
		IF "%ACTION%" NEQ "STOP" (
			SET ACTION=
			ECHO Select is not correct. Please input "START" or "STOP". Try again...
			ECHO.
			GOTO :SELECT "%PARAMETER%"
		)
	)
GOTO END

:TEST
	NET SESSION >NUL 2>&1
	IF "%ERRORLEVEL%" EQU "0" (
		CALL :START "ELEVATE"
	) ELSE (
		IF "%~1" EQU "ELEVATE" (
			IF NOT EXIST "%TASKLIST%" (
				CALL :START
			) ELSE (
				IF NOT EXIST "%TASKKILL%" CALL :START
			)
		) ELSE (
			IF EXIST "%TASKLIST%" (
				IF EXIST "%TASKKILL%" CALL :START
			)
			CALL :ELEVATE %~2 %~3
		)
	)
GOTO END

:ELEVATE
	ECHO CreateObject^("Shell.Application"^).ShellExecute "%~snx0","ELEVATE %~1 %~2","%~sdp0","runas","%PROGRAM_TITLE%">"%TEMP%\%~n0.vbs"
	%CSCRIPT% //nologo "%TEMP%\%~n0.vbs"
	IF EXIST "%TEMP%\%~n0.vbs" DEL "%TEMP%\%~n0.vbs"
GOTO END


:START
	CALL :CHECK
	IF "%ACTION%" EQU "STOP" GOTO END
	SET USER=%WALLET%
	IF "%PARAMETER%" EQU "CPU" SET DIFF=%PROGRAM_CPU_DIFF%
	IF "%PARAMETER%" EQU "NVIDIA" SET DIFF=%PROGRAM_NVIDIA_DIFF%
	IF "%PARAMETER%" EQU "AMD" SET DIFF=%PROGRAM_AMD_DIFF%
	IF "%DIFF%" NEQ "" SET USER=%USER%+%DIFF%
	SET PASSWORD=%ID%-%PARAMETER%
	IF "%EMAIL%" NEQ "" SET PASSWORD=%PASSWORD%:%EMAIL%
	SET PROGRAM_PARAMETERS=--user=%USER% --pass=%PASSWORD% %PROGRAM_PARAMETERS%
	CD "%PROGRAM_PATH%"
	IF "%~1" EQU "ELEVATE" (
		IF "%PARAMETER%" EQU "AMD" (
			IF EXIST "%DEVCON%" (
				CALL "%DEVCON%" disable "PCI\VEN_1002&DEV_687F" > NUL
				CALL "%TIMEOUT%" /T 5 /NOBREAK > NUL
				CALL "%DEVCON%" enable "PCI\VEN_1002&DEV_687F" > NUL
				CLS
			) ELSE (
				ECHO.
				ECHO ERROR: Can not find "%DEVCON%".
			)
		)
		CALL "%PROGRAM_PATH%\%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
	) ELSE (
		START "%PROGRAM_TITLE%" /D "%PROGRAM_PATH%" "%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
	)
GOTO END

:CHECK
	IF EXIST "%TASKLIST%" (
		FOR /F "tokens=2 delims=," %%A IN ('%TASKLIST% /FI "ImageName EQ %PROGRAM_FILENAME%" /FO:CSV /NH^| FIND /I "%PROGRAM_FILENAME%"') DO SET TASK_PID=%%~A
	) ELSE (
		ECHO.
		ECHO ERROR: Can not find "%TASKLIST%".
	)
	IF "%TASK_PID%" NEQ "" (
		IF EXIST "%TASKKILL%" (
			%TASKKILL% /F /IM "%PROGRAM_FILENAME%">NUL
		) ELSE (
			ECHO.
			ECHO ERROR: Can not find "%TASKKILL%".
		)
	)
GOTO END

:END
GOTO :EOF
