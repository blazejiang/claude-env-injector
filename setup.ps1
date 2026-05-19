$ErrorActionPreference = "Stop"

# ============================================================
#  Claude Code + DeepSeek 一键安装脚本 (Windows PowerShell)
#  用法: irm https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/setup.ps1 | iex
# ============================================================

$MARKER_START = "# === Claude Env Injector 自动生成区 ==="
$MARKER_END = "# ====================================="

# ---- 颜色辅助 ----
function Write-Info  { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host $msg -ForegroundColor Red }

# ---- 检测 PowerShell 配置文件路径 ----
function Get-ProfilePath {
    $pwsh7 = Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $pwsh5 = Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path (Split-Path $pwsh7 -Parent)) { return $pwsh7 }
    return $pwsh5
}

# ---- 步骤 1: 检查 / 安装 Node.js ----
function Install-NodeJS {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($nodeCmd) {
        $version = (node -v) -replace 'v','' -split '\.' | Select-Object -First 1
        if ([int]$version -ge 18) {
            Write-Ok "✅ Node.js $(node -v) 已安装"
            return
        } else {
            Write-Warn "⚠️  Node.js 版本过低 ($(node -v))，需要 >= 18"
        }
    }

    Write-Info "📦 正在安装 Node.js..."

    # 优先尝试 winget
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Info "  使用 winget 安装 Node.js..."
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    } else {
        # 回退到 chocolatey
        $choco = Get-Command choco -ErrorAction SilentlyContinue
        if ($choco) {
            Write-Info "  使用 Chocolatey 安装 Node.js..."
            choco install nodejs-lts -y
        } else {
            Write-Err "❌ 无法自动安装 Node.js。请手动安装 Node.js >= 18："
            Write-Err "   https://nodejs.org/"
            Write-Err "   安装后重新运行此脚本。"
            exit 1
        }
    }

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Err "❌ Node.js 安装失败，请手动安装后重试。"
        exit 1
    }
    Write-Ok "✅ Node.js $(node -v) 安装成功"
}

# ---- 步骤 2: 安装 Claude Code ----
function Install-Claude {
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        Write-Ok "✅ Claude Code 已安装"
        return
    }

    Write-Info "📦 正在安装 Claude Code..."
    npm install -g @anthropic-ai/claude-code

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Ok "✅ Claude Code 安装成功"
    } else {
        Write-Err "❌ Claude Code 安装失败，请检查 npm 全局安装路径。"
        exit 1
    }
}

# ---- 步骤 3: 配置 DeepSeek ----
function Set-DeepSeek {
    param([string]$ApiKey)

    $ProfilePath = Get-ProfilePath
    $ProfileDir = Split-Path $ProfilePath -Parent
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }

    $Block = @"
$MARKER_START
function use-deepseek {
  `$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
  `$env:ANTHROPIC_AUTH_TOKEN="$ApiKey"
  `$env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
  `$env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
  `$env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
  `$env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
  `$env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
  `$env:CLAUDE_CODE_EFFORT_LEVEL="max"
  Write-Host "✅ 已成功切换至 DeepSeek 引擎！" -ForegroundColor Green
}
$MARKER_END
"@

    $exists = $false
    if (Test-Path $ProfilePath) {
        $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
        if ($content -and $content.Contains($MARKER_START)) {
            $exists = $true
        }
    }

    if ($exists) {
        $content = Get-Content $ProfilePath -Raw
        $regex = [regex]::Escape($MARKER_START) + '[\s\S]*?' + [regex]::Escape($MARKER_END)
        $newContent = [regex]::Replace($content, $regex, $Block.Trim())
        Set-Content -Path $ProfilePath -Value $newContent -NoNewline
        Write-Ok "🔄 已更新 $ProfilePath 中的 DeepSeek 配置"
    } else {
        Add-Content -Path $ProfilePath -Value "`n$Block"
        Write-Ok "✅ 已将 use-deepseek 函数注入到 $ProfilePath"
    }

    return $ProfilePath
}

# ---- 主流程 ----
function Main {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "║   🚀 Claude Code + DeepSeek 一键安装脚本       ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host ""

    # 读取 API Key
    $apiKey = ""
    while ([string]::IsNullOrWhiteSpace($apiKey)) {
        $apiKey = Read-Host "🔑 请输入你的 DeepSeek API Key"
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Err "❌ API Key 不能为空，请重新输入。"
        }
    }
    Write-Host ""

    # 步骤 1
    Write-Info "━━━ 步骤 1/3: 检查 Node.js ━━━"
    Install-NodeJS
    Write-Host ""

    # 步骤 2
    Write-Info "━━━ 步骤 2/3: 安装 Claude Code ━━━"
    Install-Claude
    Write-Host ""

    # 步骤 3
    Write-Info "━━━ 步骤 3/3: 配置 DeepSeek ━━━"
    $profilePath = Set-DeepSeek -ApiKey $apiKey
    Write-Host ""

    # 完成提示
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "║              🎉 安装完成！                      ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host ""
    Write-Host "  1️⃣  加载配置:     " -NoNewline; Write-Host ". `"$profilePath`"" -ForegroundColor Cyan
    Write-Host "  2️⃣  切换 DeepSeek: " -NoNewline; Write-Host "use-deepseek" -ForegroundColor Cyan
    Write-Host "  3️⃣  启动 Claude:   " -NoNewline; Write-Host "claude" -ForegroundColor Cyan
    Write-Host ""
}

Main
