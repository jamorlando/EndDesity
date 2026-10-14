@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title 团队工作日志与智能复盘系统 - 一键停止器

echo ====================================================================
echo      团队工作日志与智能复盘管理系统 - 一键停止器
echo ====================================================================
echo.
echo 正在停止前后端服务并释放端口 (8000 与 5173)...
echo.

set killed_count=0

REM 停止 8000 端口占用进程树 FastAPI Uvicorn
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8000" ^| findstr "LISTENING"') do (
    taskkill /F /T /PID %%a >nul 2>&1
    if !errorlevel! equ 0 (
        echo  [OK] 已停止占用 8000 端口的后端服务进程树 (PID: %%a)
        set /a killed_count+=1
    )
)

REM 停止 5173 端口占用进程树 Vite Node.js
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5173" ^| findstr "LISTENING"') do (
    taskkill /F /T /PID %%a >nul 2>&1
    if !errorlevel! equ 0 (
        echo  [OK] 已停止占用 5173 端口的前端服务进程树 (PID: %%a)
        set /a killed_count+=1
    )
)

echo.
if !killed_count! equ 0 (
    echo [提示] 未发现运行中的系统端口进程，系统已处于停止状态。
) else (
    echo [完成] 共计停止了 !killed_count! 个服务进程树，所有系统端口已彻底释放。
)
echo.
echo ====================================================================
echo  已完成清理，窗口将在 3 秒后自动关闭。
echo ====================================================================
ping 127.0.0.1 -n 4 >nul