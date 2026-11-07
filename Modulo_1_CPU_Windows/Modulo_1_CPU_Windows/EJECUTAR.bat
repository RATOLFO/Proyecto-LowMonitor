@echo off
setlocal
cd /d "%~dp0"
title Modulo 1 - Identificacion del CPU
if not exist "cpu.exe" (
    echo ERROR: falta cpu.exe. Extrae primero todos los archivos del ZIP.
    echo Si deseas reconstruirlo, ejecuta COMPILAR.bat.
    pause
    exit /b 1
)
"%~dp0cpu.exe"
set "resultado=%errorlevel%"
if not "%resultado%"=="0" echo ERROR: el programa termino con codigo %resultado%.
echo.
pause
exit /b %resultado%
