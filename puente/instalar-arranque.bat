@echo off
rem Hace que el puente se inicie solo cada vez que se inicia sesion en Windows
rem y lo arranca ahora mismo. Basta con ejecutarlo una vez.
> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\puente-proyectores.bat" (
  echo @echo off
  echo start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0puente.ps1"
)
if errorlevel 1 (
  echo No se pudo instalar el arranque automatico.
  pause
  exit /b 1
)
call "%~dp0iniciar-puente.bat"
echo Listo. El puente esta en marcha y se iniciara solo al encender el totem.
echo Prueba: abre http://localhost:8123/ping en un navegador (no debe dar error de conexion).
pause
