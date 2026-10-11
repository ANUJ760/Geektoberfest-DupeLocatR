@echo off
:: dlr.cmd - DupeLocatR command-line shim (installed by winget, lives next to DupeLocatr.ps1)
:: Usage: dlr [folder]   |   dlr help
setlocal
set "SCRIPT=%~dp0DupeLocatr.ps1"
if not exist "%SCRIPT%" (
    echo [DupeLocatR] ERROR: DupeLocatr.ps1 not found next to dlr.cmd
    exit /b 1
)
if /i "%~1"=="--version" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Version
    exit /b
)
if /i "%~1"=="-v" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Version
    exit /b
)
set "HELP="
if /i "%~1"=="help" set "HELP=1"
if /i "%~1"=="-h" set "HELP=1"
if /i "%~1"=="--help" set "HELP=1"
if "%~1"=="-?" set "HELP=1"
if "%~1"=="/?" set "HELP=1"
if defined HELP (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Help
    exit /b
)
if "%~1"=="" (set "TARGET=%CD%") else set "TARGET=%~f1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Path "%TARGET%"
endlocal
