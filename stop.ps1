# ====================================================================
# 团队工作日志与智能复盘管理系统 (PowerShell 一键停止脚本)
# ====================================================================

$Host.UI.RawUI.WindowTitle = "团队工作日志与智能复盘系统 - 一键停止器"
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       正在停止系统前后端服务并释放端口 (8000 与 5173)..." -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Cyan

$ports = @(8000, 5173)
$killed = 0

foreach ($port in $ports) {
    $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($conns) {
        $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($p in $pids) {
            cmd /c "taskkill /F /T /PID $p >nul 2>&1"
            Write-Host "  [OK] 已成功终止占用端口 $port 的进程树 (PID: $p)" -ForegroundColor Green
            $killed++
        }
    }
}

Write-Host ""
if ($killed -eq 0) {
    Write-Host "未发现运行中的系统端口进程，系统已处于停止状态。" -ForegroundColor Gray
} else {
    Write-Host "共计停止了 $killed 个服务进程，系统端口已彻底释放。" -ForegroundColor Green
}
Write-Host "====================================================================" -ForegroundColor Cyan
