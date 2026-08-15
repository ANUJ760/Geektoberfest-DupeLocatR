@echo off
:: dlr.cmd — DupeLocatR command-line shim
:: Installed by winget (portable); always lives next to DupeLocatr.ps1
:: Usage: dlr                 (scans current directory)
::        dlr -Path "D:\Photos"  is NOT supported via this shim; open PS directly for that
setlocal
set "SCRIPT=%~dp0DupeLocatr.ps1"
if not exist "%SCRIPT%" (
    echo [DupeLocatR] ERROR: DupeLocatr.ps1 not found next to dlr.cmd
    echo Expected: %SCRIPT%
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Path "%CD%"
endlocal
