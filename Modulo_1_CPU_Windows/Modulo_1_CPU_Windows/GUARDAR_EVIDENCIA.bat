@echo off
setlocal
cd /d "%~dp0"
if not exist "cpu.exe" (
    echo ERROR: falta cpu.exe. Extrae primero todos los archivos del ZIP.
    pause
    exit /b 1
)
if exist "evidencia_cpu.txt" (
    choice /c SN /n /m "Ya existe evidencia_cpu.txt. Reemplazar [S/N]? "
    if errorlevel 2 exit /b 0
)
"%~dp0cpu.exe" > "%~dp0evidencia_cpu.txt"
if errorlevel 1 (
    echo No se pudo generar la evidencia. Revisa permisos y el ejecutable.
    pause
    exit /b 1
)
type "%~dp0evidencia_cpu.txt"
echo.
echo Evidencia guardada en evidencia_cpu.txt, dentro de esta carpeta.
pause
