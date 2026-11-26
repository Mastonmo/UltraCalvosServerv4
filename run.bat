@echo off
title Minecraft Forge Server - Logs
cd /d "%~dp0"

echo Recuerda que, para cerrar el server, abre el archivo stop.bat!
java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.4.28/win_args.txt nogui %* <nul
