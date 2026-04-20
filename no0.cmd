@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "CORE_DIR=%SCRIPT_DIR%no0-core"
set "DLC_DIR=%SCRIPT_DIR%no0-dlc-internal-control"
set "NEED_POPD=0"

pushd "%SCRIPT_DIR%" >nul 2>nul
if not errorlevel 1 (
  set "NEED_POPD=1"
  set "SCRIPT_DIR=%CD%\"
  set "CORE_DIR=%CD%\no0-core"
  set "DLC_DIR=%CD%\no0-dlc-internal-control"
)

set "PYTHON_BIN=%NO0_PYTHON%"

if not defined PYTHON_BIN (
  where py >nul 2>nul
  if not errorlevel 1 set "PYTHON_BIN=py -3"
)

if not defined PYTHON_BIN (
  where python >nul 2>nul
  if not errorlevel 1 set "PYTHON_BIN=python"
)

if not defined PYTHON_BIN (
  echo [no0] Python interpreter not found (py/python).
  exit /b 127
)

if /I "%~1"=="/no0" shift

set "CMD=%~1"
set "CORE_COMMANDS= status start stop rollback versions diff log clear clean test report "
set "DLC_COMMANDS= classify audit auth init decide "

if "%CMD%"=="" goto :help
if /I "%CMD%"=="help" goto :help
if /I "%CMD%"=="--help" goto :help
if /I "%CMD%"=="-h" goto :help

echo.%CORE_COMMANDS% | findstr /I /C:" %CMD% " >nul
if not errorlevel 1 goto :core

echo.%DLC_COMMANDS% | findstr /I /C:" %CMD% " >nul
if not errorlevel 1 goto :dlc

echo [no0] Unknown command: %CMD%
echo        Run './no0 help' for usage.
set "EXIT_CODE=1"
goto :end

:core
set "FORWARDED_ARGS=%*"
if /I "%~1"=="start" if defined NO0_RECONCILE_INTERVAL (
  echo %FORWARDED_ARGS% | findstr /I /C:"--reconcile-interval" >nul
  if errorlevel 1 set "FORWARDED_ARGS=%FORWARDED_ARGS% --reconcile-interval %NO0_RECONCILE_INTERVAL%"
)
%PYTHON_BIN% "%CORE_DIR%\scripts\skill_launcher.py" %FORWARDED_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"
goto :end

:dlc
if not exist "%DLC_DIR%" (
  echo [no0] '%CMD%' requires No.0-DLC-Internal Control, which is not installed.
  echo        Install: ./install-dlc.sh
  set "EXIT_CODE=2"
  goto :end
)
%PYTHON_BIN% "%DLC_DIR%\cli\dlc_cli.py" %*
set "EXIT_CODE=%ERRORLEVEL%"
goto :end

:help
echo No.0 -- AI Agent Safety Guardian
echo.
echo Core commands (always available):
echo   status                 Check guardian status
echo   start / stop           Manage the guardian daemon
echo   rollback ^<f^> ^<v^>    Rollback a file to a version
echo   versions ^<f^>          List versions of a file
echo   diff ^<f^> ^<v^>        Show diff against a version
echo   log [--last N]         Show recent change events
echo   clear                  Clear logs, training output, backups
echo   test                   Run local self-check
echo.
echo DLC commands (require No.0-DLC-Internal Control):
echo   classify               Data classification operations
echo   audit                  View audit log
echo   auth                   Authorization management
echo   decide ^<f^> ^<action^>    Resolve pending L5 decision (rollback v^<n^> ^| keep ^| status)
echo.
echo For details: ./no0 ^<command^> --help
set "EXIT_CODE=0"

:end
if "%NEED_POPD%"=="1" popd >nul 2>nul
exit /b %EXIT_CODE%
