#!/usr/bin/env bash
set -e

# ============================================================
#  Claude Code + DeepSeek 一键安装脚本
#  用法: curl -fsSL https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/setup.sh | bash
# ============================================================

MARKER_START="# === Claude Env Injector 自动生成区 ==="
MARKER_END="# ====================================="

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}$*${NC}"; }
ok()    { echo -e "${GREEN}$*${NC}"; }
warn()  { echo -e "${YELLOW}$*${NC}"; }
err()   { echo -e "${RED}$*${NC}"; }

# ---- 检测 shell 配置文件 ----
detect_rc() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    echo "$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      echo "$HOME/.bash_profile"
    else
      echo "$HOME/.bashrc"
    fi
  else
    echo "$HOME/.profile"
  fi
}

# ---- 检测操作系统 ----
detect_os() {
  case "$(uname -s)" in
    Darwin*)  echo "macos";;
    Linux*)   echo "linux";;
    MINGW*|MSYS*|CYGWIN*)  echo "windows";;
    *)        echo "unknown";;
  esac
}

# ---- 步骤 1: 检查 / 安装 Node.js ----
install_nodejs() {
  if command -v node &>/dev/null; then
    local node_version
    node_version=$(node -v | sed 's/v//' | cut -d. -f1)
    if [[ "$node_version" -ge 18 ]]; then
      ok "✅ Node.js $(node -v) 已安装"
      return 0
    else
      warn "⚠️  Node.js 版本过低 ($(node -v))，需要 >= 18，正在升级..."
    fi
  else
    info "📦 正在安装 Node.js..."
  fi

  local os
  os=$(detect_os)

  if [[ "$os" == "macos" ]]; then
    if command -v brew &>/dev/null; then
      info "  使用 Homebrew 安装 Node.js..."
      brew install node
    else
      err "❌ 未找到 Homebrew，请先安装 Homebrew："
      err "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      err "   然后重新运行此脚本。"
      exit 1
    fi
  elif [[ "$os" == "linux" ]]; then
    if command -v apt-get &>/dev/null; then
      info "  使用 apt 安装 Node.js..."
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt-get install -y nodejs
    elif command -v yum &>/dev/null; then
      info "  使用 yum 安装 Node.js..."
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
      sudo yum install -y nodejs
    elif command -v dnf &>/dev/null; then
      info "  使用 dnf 安装 Node.js..."
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
      sudo dnf install -y nodejs
    elif command -v pacman &>/dev/null; then
      info "  使用 pacman 安装 Node.js..."
      sudo pacman -S --noconfirm nodejs npm
    else
      err "❌ 无法自动安装 Node.js，请手动安装 (>= 18) 后重新运行此脚本。"
      exit 1
    fi
  else
    err "❌ 无法自动安装 Node.js，请手动安装 (>= 18) 后重新运行此脚本。"
    exit 1
  fi

  if ! command -v node &>/dev/null; then
    err "❌ Node.js 安装失败，请手动安装后重试。"
    exit 1
  fi
  ok "✅ Node.js $(node -v) 安装成功"
}

# ---- 步骤 2: 安装 Claude Code ----
install_claude() {
  if command -v claude &>/dev/null; then
    ok "✅ Claude Code 已安装 ($(claude --version 2>/dev/null || echo 'unknown'))"
    return 0
  fi

  info "📦 正在安装 Claude Code..."
  npm install -g @anthropic-ai/claude-code

  if command -v claude &>/dev/null; then
    ok "✅ Claude Code 安装成功"
  else
    err "❌ Claude Code 安装失败，请检查 npm 全局安装路径。"
    exit 1
  fi
}

# ---- 步骤 3: 配置 DeepSeek ----
configure_deepseek() {
  local api_key="$1"
  local rc_file
  rc_file=$(detect_rc)

  # 生成代码块
  local block="${MARKER_START}
use-deepseek() {
  export ANTHROPIC_BASE_URL=\"https://api.deepseek.com/anthropic\"
  export ANTHROPIC_AUTH_TOKEN=\"${api_key}\"
  export ANTHROPIC_MODEL=\"deepseek-v4-pro[1m]\"
  export ANTHROPIC_DEFAULT_OPUS_MODEL=\"deepseek-v4-pro[1m]\"
  export ANTHROPIC_DEFAULT_SONNET_MODEL=\"deepseek-v4-pro[1m]\"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL=\"deepseek-v4-flash\"
  export CLAUDE_CODE_SUBAGENT_MODEL=\"deepseek-v4-flash\"
  export CLAUDE_CODE_EFFORT_LEVEL=\"max\"
  echo \"✅ 已成功切换至 DeepSeek 引擎！\"
}
${MARKER_END}"

  if grep -qF "$MARKER_START" "$rc_file" 2>/dev/null; then
    local tmp_file
    tmp_file=$(mktemp)
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
      $0 == start { skip=1; next }
      $0 == end   { skip=0; next }
      !skip       { print }
    ' "$rc_file" > "$tmp_file"
    echo "" >> "$tmp_file"
    echo "$block" >> "$tmp_file"
    mv "$tmp_file" "$rc_file"
    ok "🔄 已更新 ${rc_file} 中的 DeepSeek 配置"
  else
    echo "" >> "$rc_file"
    echo "$block" >> "$rc_file"
    ok "✅ 已将 use-deepseek 函数注入到 ${rc_file}"
  fi
}

# ---- 主流程 ----
main() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║   🚀 Claude Code + DeepSeek 一键安装脚本       ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""

  # 读取 API Key
  local api_key=""
  while true; do
    read -rp "🔑 请输入你的 DeepSeek API Key: " api_key
    if [[ -n "$api_key" ]]; then
      break
    fi
    err "❌ API Key 不能为空，请重新输入。"
  done
  echo ""

  # 步骤 1
  info "━━━ 步骤 1/3: 检查 Node.js ━━━"
  install_nodejs
  echo ""

  # 步骤 2
  info "━━━ 步骤 2/3: 安装 Claude Code ━━━"
  install_claude
  echo ""

  # 步骤 3
  info "━━━ 步骤 3/3: 配置 DeepSeek ━━━"
  configure_deepseek "$api_key"
  echo ""

  # 完成提示
  local rc_file
  rc_file=$(detect_rc)
  echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║              🎉 安装完成！                      ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  1️⃣  加载配置:     ${CYAN}source ${rc_file}${NC}"
  echo -e "  2️⃣  切换 DeepSeek: ${CYAN}use-deepseek${NC}"
  echo -e "  3️⃣  启动 Claude:   ${CYAN}claude${NC}"
  echo ""
}

main
