# claude-env-injector

> 轻量级跨平台 CLI 工具，一键将 DeepSeek API 环境变量注入到终端配置文件，让你用 DeepSeek 引擎驱动 Claude Code。

## 使用方式

### 一键安装 Claude Code + 配置 DeepSeek（推荐）

自动安装 Node.js、Claude Code，并注入 DeepSeek 环境变量：

**macOS / Linux：**

```bash
curl -fsSL https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/setup.sh | bash
```

**Windows PowerShell：**

```powershell
irm https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/setup.ps1 | iex
```

### 仅配置 DeepSeek（Claude Code 已安装）

**macOS / Linux：**

```bash
curl -fsSL https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/install.sh | bash
```

**Windows PowerShell：**

```powershell
irm https://raw.githubusercontent.com/blazejiang/claude-env-injector/main/install.ps1 | iex
```

### npx 直接运行（需要 Node.js）

```bash
npx github:blazejiang/claude-env-injector
```

## 运行效果

### 一键安装（setup.sh / setup.ps1）

运行后自动完成 Node.js 安装、Claude Code 安装、DeepSeek 配置：

```
╔══════════════════════════════════════════════════╗
║   🚀 Claude Code + DeepSeek 一键安装脚本       ║
╚══════════════════════════════════════════════════╝

🔑 请输入你的 DeepSeek API Key: sk-xxxxxxxxxxxx

━━━ 步骤 1/3: 检查 Node.js ━━━
✅ Node.js v22.12.0 已安装

━━━ 步骤 2/3: 安装 Claude Code ━━━
📦 正在安装 Claude Code...
✅ Claude Code 安装成功

━━━ 步骤 3/3: 配置 DeepSeek ━━━
✅ 已将 use-deepseek 函数注入到 ~/.zshrc

╔══════════════════════════════════════════════════╗
║              🎉 安装完成！                      ║
╚══════════════════════════════════════════════════╝

  1️⃣  加载配置:     source ~/.zshrc
  2️⃣  切换 DeepSeek: use-deepseek
  3️⃣  启动 Claude:   claude
```

### 仅配置 DeepSeek（install.sh / install.ps1）

```
🚀 Claude Env Injector — DeepSeek 环境变量注入工具

🔑 请输入你的 DeepSeek API Key: sk-xxxxxxxxxxxx

✅ 已成功将 use-deepseek 函数注入到 ~/.zshrc

请执行以下命令使其生效：

  source ~/.zshrc

然后输入 use-deepseek 即可切换至 DeepSeek 引擎。
```

## 生效后使用

```bash
# 1. 加载配置
source ~/.zshrc   # macOS/Linux
# 或重启 PowerShell（Windows）

# 2. 切换至 DeepSeek 引擎
use-deepseek

# 3. 正常使用 claude
claude
```

## 支持的平台

| 平台 | 注入目标文件 |
| --- | --- |
| macOS (zsh) | `~/.zshrc` |
| macOS (bash) | `~/.bash_profile` |
| Linux | `~/.bashrc` / `~/.zshrc` |
| Windows PowerShell 7+ | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` |
| Windows PowerShell 5.x | `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` |

## 注入的环境变量

| 变量名 | 值 |
| --- | --- |
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` |
| `ANTHROPIC_AUTH_TOKEN` | 你输入的 DeepSeek API Key |
| `ANTHROPIC_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` |

## 幂等性

支持重复运行：

- **首次运行**：在配置文件末尾追加 `use-deepseek` 函数
- **再次运行**：自动替换已有的配置区块，不会产生重复内容

## 手动卸载

编辑你的终端配置文件（如 `~/.zshrc`），删除 `# === Claude Env Injector 自动生成区 ===` 到 `# =====================================` 之间的内容即可。

## License

MIT
