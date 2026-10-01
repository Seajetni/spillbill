@echo off
echo ========================================================
echo       SplitBill - 1-Click Windows App Builder
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Fetching Flutter dependencies...
call flutter pub get
if errorlevel 1 goto error

echo.
echo [2/3] Building Windows Release binary...
call flutter build windows --release
if errorlevel 1 goto error

echo.
echo [3/3] Compiling 1-Click Installer (SplitBill_Setup.exe)...
set ISCC="C:\Users\seaza\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
if not exist %ISCC% set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %ISCC% set ISCC="C:\Program Files\Inno Setup 6\ISCC.exe"

%ISCC% "%~dp0installer.iss"
if errorlevel 1 goto error

copy /y "%~dp0dist\SplitBill_Setup.exe" "%~dp0SplitBill_Setup.exe" >nul

echo.
echo ========================================================
echo [SUCCESS] SplitBill_Setup.exe created successfully!
echo Location: %~dp0SplitBill_Setup.exe
echo ========================================================
echo.
pause
exit /b 0

:error
echo.
echo [ERROR] Build failed! Please check the output above.
pause
exit /b 1
