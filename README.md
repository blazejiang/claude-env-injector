# claude-env-injector

> 轻量级跨平台 CLI 工具，一键将 DeepSeek API 环境变量注入到终端配置文件，让你用 DeepSeek 引擎驱动 Claude Code。

## 使用方式

### 方式一：npx 直接运行（推荐）

```bash
npx github:blazejiang/claude-env-injector
```

### 方式二：全局安装

```bash
npm install -g claude-env-injector
claude-env-injector
```

### 方式三：本地运行

```bash
git clone https://github.com/jiangaoxiang/claude-env-injector.git
cd claude-env-injector
npm install
node index.js
```

## 运行效果

运行后会提示输入你的 DeepSeek API Key：

```
🚀 Claude Env Injector — DeepSeek 环境变量注入工具

? 🔑 请输入你的 DeepSeek API Key: sk-xxxxxxxxxxxx

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
