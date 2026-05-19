#!/usr/bin/env bash
set -e

MARKER_START="# === Claude Env Injector 自动生成区 ==="
MARKER_END="# ====================================="

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

RC_FILE=$(detect_rc)

# ---- 读取 API Key ----
echo ""
echo "🚀 Claude Env Injector — DeepSeek 环境变量注入工具"
echo ""

while true; do
  read -rp "🔑 请输入你的 DeepSeek API Key: " api_key
  if [[ -n "$api_key" ]]; then
    break
  fi
  echo "❌ API Key 不能为空，请重新输入。"
done

# ---- 生成代码块 ----
BLOCK="${MARKER_START}
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

# ---- 幂等写入 ----
if grep -qF "$MARKER_START" "$RC_FILE" 2>/dev/null; then
  # 替换旧区块：删除旧块，追加新块
  # 用 awk 实现多行替换
  tmp_file=$(mktemp)
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$BLOCK" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; print block; next }
    !skip { print }
  ' "$RC_FILE" > "$tmp_file"
  mv "$tmp_file" "$RC_FILE"
  echo ""
  echo "🔄 已更新 ${RC_FILE} 中的 DeepSeek 配置。"
else
  echo "" >> "$RC_FILE"
  echo "$BLOCK" >> "$RC_FILE"
  echo ""
  echo "✅ 已成功将 use-deepseek 函数注入到 ${RC_FILE}"
fi

echo ""
echo "请执行以下命令使其生效："
echo ""
echo "  source ${RC_FILE}"
echo ""
echo "然后输入 use-deepseek 即可切换至 DeepSeek 引擎。"
echo ""
