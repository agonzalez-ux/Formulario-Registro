@echo off
rem Arranca el puente en segundo plano (sin ventana)
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0puente.ps1"
