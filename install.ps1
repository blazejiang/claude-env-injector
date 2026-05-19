$ErrorActionPreference = "Stop"

$MARKER_START = "# === Claude Env Injector 自动生成区 ==="
$MARKER_END = "# ====================================="

# ---- 检测 PowerShell 配置文件路径 ----
function Get-ProfilePath {
    # PowerShell 7+ (pwsh)
    $pwsh7 = Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    # Windows PowerShell 5.x
    $pwsh5 = Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

    if (Test-Path (Split-Path $pwsh7 -Parent)) {
        return $pwsh7
    }
    return $pwsh5
}

$ProfilePath = Get-ProfilePath

# ---- 读取 API Key ----
Write-Host ""
Write-Host "🚀 Claude Env Injector — DeepSeek 环境变量注入工具" -ForegroundColor Cyan
Write-Host ""

$apiKey = ""
while ([string]::IsNullOrWhiteSpace($apiKey)) {
    $apiKey = Read-Host "🔑 请输入你的 DeepSeek API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "❌ API Key 不能为空，请重新输入。" -ForegroundColor Red
    }
}

# ---- 生成代码块 ----
$Block = @"
$MARKER_START
function use-deepseek {
  `$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
  `$env:ANTHROPIC_AUTH_TOKEN="$apiKey"
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

# ---- 幂等写入 ----
$ProfileDir = Split-Path $ProfilePath -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$exists = $false
if (Test-Path $ProfilePath) {
    $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($MARKER_START)) {
        $exists = $true
    }
}

if ($exists) {
    # 替换旧区块
    $regex = [regex]::Escape($MARKER_START) + '[\s\S]*?' + [regex]::Escape($MARKER_END)
    $newContent = [regex]::Replace($content, $regex, $Block.Trim())
    Set-Content -Path $ProfilePath -Value $newContent -NoNewline
    Write-Host ""
    Write-Host "🔄 已更新 $ProfilePath 中的 DeepSeek 配置。" -ForegroundColor Yellow
} else {
    Add-Content -Path $ProfilePath -Value "`n$Block"
    Write-Host ""
    Write-Host "✅ 已成功将 use-deepseek 函数注入到 $ProfilePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "请执行以下命令使其生效："
Write-Host ""
Write-Host "  . `"$ProfilePath`"" -ForegroundColor Cyan
Write-Host ""
Write-Host "然后输入 use-deepseek 即可切换至 DeepSeek 引擎。"
Write-Host ""
