@echo off
setlocal
cd /d "%~dp0"
title Compilar identificacion del CPU - Windows x64
rem Buscar NASM instalado o una copia portable en la carpeta herramientas.
set "ensamblador="
if exist "%~dp0herramientas\nasm.exe" set "ensamblador=%~dp0herramientas\nasm.exe"
if not defined ensamblador for %%N in (nasm.exe) do set "ensamblador=%%~$PATH:N"
if not defined ensamblador if exist "%ProgramFiles%\NASM\nasm.exe" set "ensamblador=%ProgramFiles%\NASM\nasm.exe"
if not defined ensamblador if exist "%LOCALAPPDATA%\bin\NASM\nasm.exe" set "ensamblador=%LOCALAPPDATA%\bin\NASM\nasm.exe"
if not defined ensamblador (
    echo Falta NASM. Consulta INSTRUCCIONES.txt, apartado de compilacion.
    pause
    exit /b 1
)
rem Detectar Visual Studio o Build Tools usando vswhere, sin cambiar el sistema.
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "usebackq tokens=*" %%V in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        call "%%V\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
    )
)
if not defined VSCMD_ARG_TGT_ARCH (
    echo Falta el entorno de Visual C++ x64.
    echo Instala Build Tools con C++ y Windows SDK, segun INSTRUCCIONES.txt.
    echo O abre x64 Native Tools Command Prompt for VS y ejecuta este BAT.
    pause
    exit /b 1
)
if /i not "%VSCMD_ARG_TGT_ARCH%"=="x64" (
    echo Abre x64 Native Tools Command Prompt for VS y ejecuta este BAT.
    pause
    exit /b 1
)
where link.exe >nul 2>&1
if errorlevel 1 (
    echo No se encontro link.exe de Visual Studio.
    pause
    exit /b 1
)
echo Compilando cpu.asm...
"%ensamblador%" -f win64 "cpu.asm" -o "cpu.obj"
if errorlevel 1 goto error
link.exe /nologo /machine:x64 /subsystem:console /entry:inicio /nodefaultlib /nxcompat /dynamicbase /out:cpu.exe cpu.obj kernel32.lib
if errorlevel 1 goto error
echo.
echo Compilacion terminada. Abre EJECUTAR.bat.
pause
exit /b 0
:error
echo.
echo No se pudo compilar. Lee el error que aparece arriba.
pause
exit /b 1
