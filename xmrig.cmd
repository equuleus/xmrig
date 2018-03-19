@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
TITLE XMRig

REM Pool addresses (with alternative):
SET POOL_ADDRESS[1]=pool.monero.hashvault.pro
SET POOL_PORT[1]=5555
SET POOL_ADDRESS[2]=pool.monero.hashvault.pro
SET POOL_PORT[2]=7777

REM Proxy addresses (with alternative):
SET PROXY_ADDRESS[1]=192.168.0.1
SET PROXY_PORT[1]=5555
SET PROXY_ADDRESS[2]=192.168.0.2
SET PROXY_PORT[2]=7777

REM Wallet for pool:
SET WALLET=4...
rem SET WALLET=Sumo...
REM Worker ID:
SET ID=%COMPUTERNAME%
REM E-mail address for pool (auto-registration):
SET EMAIL=user@server.com

SET PROGRAM_API_ADDRESS=127.0.0.1
SET PROGRAM_API_PORT_CPU=10001
SET PROGRAM_API_PORT_NVIDIA=10002
SET PROGRAM_API_PORT_AMD=10003

SET USE_PROXY=true
SET ALLOW_MANUAL_SELECT=true

SET PROGRAM_SHOW_CONSOLE=true
SET PROGRAM_SHOW_GUI=true
SET PROGRAM_GUI_REFRESH=3

SET SRC=%~dp0
SET PROGRAM_TITLE=XMRig
SET PROGRAM_PATH=%SRC:~0,-1%
SET PROGRAM_CPU_FILENAME=xmrig.exe
SET PROGRAM_NVIDIA_FILENAME=xmrig-nvidia.exe
SET PROGRAM_AMD_FILENAME=xmrig-amd.exe
SET PROGRAM_PS_FILENAME=xmrig.ps1
rem SET PROGRAM_PS_START=C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe -executionpolicy unrestricted -file "%PROGRAM_PATH%\%PROGRAM_PS_FILENAME%"
SET PROGRAM_PS_START=C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe -executionpolicy unrestricted -windowstyle hidden -file "%PROGRAM_PATH%\%PROGRAM_PS_FILENAME%"

SET PROGRAM_PARAMETERS=--algo=cryptonight --keepalive --retries=5 --retry-pause=5 --donate-level=1 --print-time=30 

REM SETTINGS FOR: INTEL Core i7 3770k-4770k-7770k:
SET PROGRAM_CPU_PARAMETERS=--av=1 --threads=4 --cpu-affinity=0xAA --cpu-priority=5
REM SETTINGS FOR: NVIDIA GeForce GT 740
SET PROGRAM_NVIDIA_PARAMETERS=--cuda-devices=0 --cuda-launch=94x4 --cuda-bfactor=6 --cuda-bsleep=50
REM SETTINGS FOR: AMD Radeon RX Vega 64:
SET PROGRAM_AMD_PARAMETERS=--opencl-devices=0 --opencl-launch=2016x8 --opencl-platform=1 --opencl-devices=0 --opencl-launch=1800x8 --opencl-platform=1 --opencl-devices=1 --opencl-launch=2016x8 --opencl-platform=1 --opencl-devices=1 --opencl-launch=1800x8 --opencl-platform=1

SET PROGRAM_CPU_DIFF=20000
SET PROGRAM_NVIDIA_DIFF=10000
SET PROGRAM_AMD_DIFF=200000

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
REM OverdriveNTool you can find here: https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/
SET TOOL=%SRC%\OverdriveNTool.exe
SET TOOL_PARAMETERS=-consoleonly -r1 -p1"(1) AMD Radeon RX Vega64 8G HBM2 Liquid Cooling" -r2 -p2"(2) AMD Radeon RX Vega64 8G HBM2 Liquid Cooling"
REM Download (https://www.youtube.com/watch?v=8Uq3Om2MXOE) and apply registry in ".\REG\MorePowerVega64_142_Modded_fixed.reg". More info here: http://www.overclock.net/t/1633446/preliminary-view-of-amd-vega-bios/250#post_26297003

IF "%USE_PROXY%" EQU "true" (
	CALL :SETTINGS_SET_URL_LIST "PROXY"
	SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% --nicehash 
) ELSE (
	CALL :SETTINGS_SET_URL_LIST "POOL"
)
IF "%URL_LIST%" NEQ "" (
	SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% %URL_LIST% 
) ELSE (
	ECHO.
	ECHO ERROR: No valid address and port set. Can not continue loading.
	GOTO END
)

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

:SETTINGS_SET_URL_LIST
 	IF NOT DEFINED URL_LIST_COUNT (
		SET URL_TYPE=%~1
		SET URL_START=%~2
		IF "!URL_START!" EQU "" (
			SET URL_LIST_COUNT=1
		) ELSE (
			SET URL_LIST_COUNT=!URL_START!
		)
	)
	IF "%URL_TYPE%" EQU "POOL" (
		IF DEFINED POOL_ADDRESS[%URL_LIST_COUNT%] (
			CALL SET URL_ADDRESS=%%POOL_ADDRESS[%URL_LIST_COUNT%]%%
			IF DEFINED POOL_PORT[%URL_LIST_COUNT%] (
				CALL SET URL_PORT=%%POOL_PORT[%URL_LIST_COUNT%]%%
			)
		) ELSE (
			GOTO END
		)
	) ELSE (
		IF "%URL_TYPE%" EQU "PROXY" (
			IF DEFINED PROXY_ADDRESS[%URL_LIST_COUNT%] (
				CALL SET URL_ADDRESS=%%PROXY_ADDRESS[%URL_LIST_COUNT%]%%
				IF DEFINED PROXY_PORT[%URL_LIST_COUNT%] (
					CALL SET URL_PORT=%%PROXY_PORT[%URL_LIST_COUNT%]%%
				)
			) ELSE (
				GOTO END
			)
		) ELSE (
			GOTO END
		)
	)
	IF "%URL_ADDRESS%" NEQ "" (
		IF "%URL_PORT%" NEQ "" (
			IF NOT DEFINED URL_LIST (
				SET URL_LIST=--url=%URL_ADDRESS%:%URL_PORT%
			) ELSE (
				SET URL_LIST=%URL_LIST% --url=%URL_ADDRESS%:%URL_PORT%
			)
			SET URL_PORT=
		) ELSE (
			ECHO.
			ECHO ERROR: PORT ^(variable "%URL_TYPE%_PORT[%URL_LIST_COUNT%]"^) is not set for %URL_TYPE%_ADDRESS[%URL_LIST_COUNT%]: "%URL_ADDRESS%".
		)
		SET URL_ADDRESS=
	)
	SET /A URL_LIST_COUNT=!URL_LIST_COUNT!+1
	GOTO SETTINGS_SET_URL_LIST
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
	IF "%PARAMETER%" EQU "CPU" (
		SET DIFF=%PROGRAM_CPU_DIFF%
		SET API_PORT=%PROGRAM_API_PORT_CPU%
	)
	IF "%PARAMETER%" EQU "NVIDIA" (
		SET DIFF=%PROGRAM_NVIDIA_DIFF%
		SET API_PORT=%PROGRAM_API_PORT_NVIDIA%
	)
	IF "%PARAMETER%" EQU "AMD" (
		SET DIFF=%PROGRAM_AMD_DIFF%
		SET API_PORT=%PROGRAM_API_PORT_AMD%
	)
	IF "%DIFF%" NEQ "" SET USER=%USER%+%DIFF%
	SET PASSWORD=%ID%-%PARAMETER%
	IF "%EMAIL%" NEQ "" SET PASSWORD=%PASSWORD%:%EMAIL%
	IF "%USE_PROXY%" EQU "true" (
		SET PROGRAM_PARAMETERS=--user=%ID%-%PARAMETER% %PROGRAM_PARAMETERS%
	) ELSE (
		SET PROGRAM_PARAMETERS=--user=%USER% --pass=%PASSWORD% %PROGRAM_PARAMETERS%
	)
	IF "%PROGRAM_SHOW_CONSOLE%" NEQ "true" SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% --background
	IF "%API_PORT%" NEQ "" SET PROGRAM_PARAMETERS=%PROGRAM_PARAMETERS% --api-port=%API_PORT% --api-worker-id=%ID%-%PARAMETER%
	SET API_PROCESS=%PROGRAM_FILENAME:~0,-4%
	SET API_ADDRESS=%PROGRAM_API_ADDRESS%
	CD "%PROGRAM_PATH%"
	IF "%~1" EQU "ELEVATE" (
		IF "%PARAMETER%" EQU "AMD" (
			IF EXIST "%DEVCON%" (
				CALL "%DEVCON%" disable "PCI\VEN_1002&DEV_687F" > NUL
				CALL "%TIMEOUT%" /T 3 /NOBREAK > NUL
				CALL "%DEVCON%" enable "PCI\VEN_1002&DEV_687F" > NUL
				CALL "%TOOL%" %TOOL_PARAMETERS%
				CLS
			) ELSE (
				ECHO.
				ECHO ERROR: Can not find "%DEVCON%".
			)
		)
		CALL "%PROGRAM_PATH%\%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
	) ELSE (
		IF "%PROGRAM_SHOW_GUI%" EQU "true" (
			START CMD /C "%PROGRAM_PS_START% -address %API_ADDRESS% -port %API_PORT% -process %API_PROCESS% -refresh %PROGRAM_GUI_REFRESH%"
		)
		START "%PROGRAM_TITLE%" /D "%PROGRAM_PATH%" "%PROGRAM_FILENAME%" %PROGRAM_PARAMETERS%
	)
GOTO END

:CHECK
	IF EXIST "%TASKLIST%" (
		FOR /F "tokens=2 delims=," %%A IN ('%TASKLIST% /FI "ImageName EQ %PROGRAM_FILENAME%" /FO:CSV /NH^| FIND /I "%PROGRAM_FILENAME%"') DO SET TASK_PID=%%~A > NUL
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
