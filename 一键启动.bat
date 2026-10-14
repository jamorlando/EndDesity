@echo off
chcp 65001 >nul
title 团队工作日志与智能复盘系统 - 一键启动器

REM 由 PowerShell 统一处理 Python 探测、虚拟环境和依赖安装。
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo [错误] 启动失败，请根据上方提示处理。
    pause
)

exit /b %EXIT_CODE%
