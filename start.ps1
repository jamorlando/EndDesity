$ErrorActionPreference = "Stop"

$Host.UI.RawUI.WindowTitle = "团队工作日志与智能复盘系统 - 一键启动器"
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$backendDir = Join-Path $rootDir "backend"
$frontendDir = Join-Path $rootDir "frontend"
$venvDir = Join-Path $backendDir ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"

function Write-Banner {
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "      团队工作日志与智能复盘管理系统 (Enterprise Dev-Log)" -ForegroundColor Green
    Write-Host "                 一键全栈启动中枢 (FastAPI + Vue3)" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-WorkingPython {
    $projectCandidates = @(
        (Join-Path $backendDir ".venv\Scripts\python.exe"),
        (Join-Path $rootDir ".venv\Scripts\python.exe"),
        (Join-Path $backendDir "venv\Scripts\python.exe"),
        (Join-Path $rootDir "venv\Scripts\python.exe")
    )

    foreach ($candidate in $projectCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            try {
                & $candidate -c "import sys; print(sys.executable)" *> $null
                if ($LASTEXITCODE -eq 0) { return $candidate }
            } catch { }
        }
    }

    $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        try {
            & $pythonCommand.Source -c "import sys; print(sys.executable)" *> $null
            if ($LASTEXITCODE -eq 0) { return $pythonCommand.Source }
        } catch { }
    }

    $pyCommand = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($pyCommand) {
        try {
            $resolved = & $pyCommand.Source -3 -c "import sys; print(sys.executable)" 2>$null
            if ($LASTEXITCODE -eq 0 -and $resolved) { return $resolved.Trim() }
        } catch { }
    }

    return $null
}

function Test-PythonImports([string]$pythonExe) {
    & $pythonExe -c "import fastapi, uvicorn, sqlalchemy, asyncmy, greenlet, pydantic, bcrypt, jwt, httpx, multipart, jieba, puremagic, docx" *> $null
    return ($LASTEXITCODE -eq 0)
}

Write-Banner

try {
    $pythonExe = Get-WorkingPython
    if (-not $pythonExe) {
        Write-Host "[错误] 未找到可用的 Python 3 运行时。" -ForegroundColor Red
        Write-Host "当前电脑上的 py.exe 只是启动器，不代表 Python 本体已安装。" -ForegroundColor Yellow
        Write-Host "请安装 Python 3.12 (64-bit) 后重新双击本脚本：" -ForegroundColor Yellow
        Write-Host "https://www.python.org/downloads/release/python-31210/" -ForegroundColor Cyan
        exit 1
    }

    $pythonVersion = & $pythonExe --version 2>&1
    Write-Host "[1/5] Python 环境就绪: $pythonVersion" -ForegroundColor Green

    if (-not (Test-Path -LiteralPath $venvPython)) {
        Write-Host "[2/5] 首次运行，正在创建后端虚拟环境..." -ForegroundColor Yellow
        & $pythonExe -m venv $venvDir
        if ($LASTEXITCODE -ne 0) { throw "创建 Python 虚拟环境失败。" }
    } else {
        Write-Host "[2/5] 项目虚拟环境就绪。" -ForegroundColor Green
    }
    $pythonExe = $venvPython

    if (-not (Test-PythonImports $pythonExe)) {
        Write-Host "[3/5] 正在安装/更新后端依赖，首次运行需要几分钟..." -ForegroundColor Yellow
        & $pythonExe -m pip install --disable-pip-version-check -r (Join-Path $backendDir "requirements.txt")
        if ($LASTEXITCODE -ne 0) { throw "后端依赖安装失败，请检查网络后重试。" }
    }
    Write-Host "[3/5] 后端依赖就绪。" -ForegroundColor Green

    $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    $npmCommand = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $nodeCommand -or -not $npmCommand) {
        throw "未检测到 Node.js/npm，请安装 Node.js LTS 并加入 PATH。"
    }
    $nodeVersion = & $nodeCommand.Source --version
    if (-not (Test-Path -LiteralPath (Join-Path $frontendDir "node_modules"))) {
        Write-Host "[4/5] 正在安装前端依赖..." -ForegroundColor Yellow
        & $npmCommand.Source --prefix $frontendDir install
        if ($LASTEXITCODE -ne 0) { throw "前端依赖安装失败，请检查网络后重试。" }
    }
    Write-Host "[4/5] Node.js 环境就绪: $nodeVersion" -ForegroundColor Green

    $mysqlService = Get-Service -Name "MySQL8" -ErrorAction SilentlyContinue
    if ($mysqlService -and $mysqlService.Status -ne "Running") {
        Write-Host "正在尝试启动 MySQL8 服务..." -ForegroundColor Yellow
        Start-Service -Name "MySQL8" -ErrorAction SilentlyContinue
    } elseif (-not $mysqlService) {
        Write-Host "[提示] 未发现 MySQL8 系统服务，请确保数据库已通过其他方式启动。" -ForegroundColor Yellow
    }

    foreach ($port in @(8000, 5173)) {
        $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        foreach ($processId in ($connections | Select-Object -ExpandProperty OwningProcess -Unique)) {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] 已释放端口 $port (PID: $processId)" -ForegroundColor Yellow
        }
    }

    Write-Host "[5/5] 正在启动前后端服务..." -ForegroundColor Green
    $backendCommand = '"' + $pythonExe + '" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000'
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $backendDir -ArgumentList @("/k", $backendCommand)
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $frontendDir -ArgumentList @("/k", "npm.cmd run dev")

    $frontendReady = $false
    $backendReady = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        if (-not $frontendReady) {
            try {
                $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:5173" -TimeoutSec 1
                $frontendReady = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500)
            } catch { }
        }
        if (-not $backendReady) {
            try {
                $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:8000/health" -TimeoutSec 1
                $backendReady = ($response.StatusCode -eq 200)
            } catch { }
        }
        if ($frontendReady -and $backendReady) { break }
        Start-Sleep -Seconds 1
    }

    Write-Host ""
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " 前端界面: http://localhost:5173" -ForegroundColor Cyan
    Write-Host " 后端接口: http://127.0.0.1:8000" -ForegroundColor Cyan
    Write-Host " Swagger:  http://127.0.0.1:8000/docs" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray

    if ($frontendReady -and $backendReady) {
        Start-Process "http://localhost:5173"
        Write-Host "系统已成功启动！若需停止，请双击 [一键停止.bat]。" -ForegroundColor Green
    } else {
        $failedServices = @()
        if (-not $frontendReady) { $failedServices += "前端" }
        if (-not $backendReady) { $failedServices += "后端" }
        throw "$($failedServices -join '、') 30 秒内未就绪，请查看对应服务窗口中的报错。"
    }
    exit 0
} catch {
    Write-Host ""
    Write-Host "[错误] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
