@echo off
REM Run Flutter - this batch file helps avoid PATH issues
cd /d "%~dp0"

REM Try to find Flutter in common locations
if exist "%USERPROFILE%\AppData\Local\flutter\bin\flutter.bat" (
  "%USERPROFILE%\AppData\Local\flutter\bin\flutter.bat" %*
  exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
  "%USERPROFILE%\flutter\bin\flutter.bat" %*
  exit /b %ERRORLEVEL%
)

if exist "C:\flutter\bin\flutter.bat" (
  "C:\flutter\bin\flutter.bat" %*
  exit /b %ERRORLEVEL%
)

REM If not found in common locations, try PATH
flutter %*
