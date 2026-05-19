#!/usr/bin/env node

import inquirer from "inquirer";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

// ============ 常量 ============

const MARKER_START = "# === Claude Env Injector 自动生成区 ===";
const MARKER_END = "# =====================================";
const BLOCK_REGEX = new RegExp(
  `${escapeRegex(MARKER_START)}[\\s\\S]*?${escapeRegex(MARKER_END)}`,
  "g"
);

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// ============ 交互式获取 API Key ============

async function askApiKey() {
  const { apiKey } = await inquirer.prompt([
    {
      type: "input",
      name: "apiKey",
      message: "🔑 请输入你的 DeepSeek API Key:",
      validate: (input) =>
        input.trim() ? true : "API Key 不能为空，请重新输入",
    },
  ]);
  return apiKey.trim();
}

// ============ 平台检测与配置 ============

/**
 * 检测当前平台，返回 { type, rcPath, sourceCmd }
 * - type: "unix" | "windows"
 * - rcPath: 配置文件的绝对路径
 * - sourceCmd: 生效时需执行的命令提示
 */
function detectPlatform() {
  const platform = os.platform();

  if (platform === "win32") {
    // Windows: 优先 PowerShell 7+ (pwsh), 回退到 Windows PowerShell 5.x
    const pwsh7 = path.join(
      os.homedir(),
      "Documents",
      "PowerShell",
      "Microsoft.PowerShell_profile.ps1"
    );
    const pwsh5 = path.join(
      os.homedir(),
      "Documents",
      "WindowsPowerShell",
      "Microsoft.PowerShell_profile.ps1"
    );

    // 如果 pwsh7 目录已存在，优先使用；否则用 pwsh5 的路径
    const rcPath = fs.existsSync(path.dirname(pwsh7)) ? pwsh7 : pwsh5;
    return {
      type: "windows",
      rcPath,
      sourceCmd: `. "${rcPath}"`,
    };
  }

  // 类 Unix: macOS / Linux / WSL / Git Bash
  const shell = process.env.SHELL || "";
  let rcPath;
  if (shell.includes("zsh")) {
    rcPath = path.join(os.homedir(), ".zshrc");
  } else if (shell.includes("bash")) {
    // macOS 的 login shell 读 .bash_profile，Linux 读 .bashrc
    rcPath = os.platform() === "darwin"
      ? path.join(os.homedir(), ".bash_profile")
      : path.join(os.homedir(), ".bashrc");
  } else {
    // 兜底：尝试 .profile
    rcPath = path.join(os.homedir(), ".profile");
  }

  return {
    type: "unix",
    rcPath,
    sourceCmd: `source ${rcPath}`,
  };
}

// ============ Shell 函数代码生成 ============

function generateUnixBlock(apiKey) {
  return `${MARKER_START}
use-deepseek() {
  export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
  export ANTHROPIC_AUTH_TOKEN="${apiKey}"
  export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
  export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
  export CLAUDE_CODE_EFFORT_LEVEL="max"
  echo "✅ 已成功切换至 DeepSeek 引擎！"
}
${MARKER_END}`;
}

function generateWindowsBlock(apiKey) {
  return `${MARKER_START}
function use-deepseek {
  $env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
  $env:ANTHROPIC_AUTH_TOKEN="${apiKey}"
  $env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
  $env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
  $env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
  $env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
  $env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
  $env:CLAUDE_CODE_EFFORT_LEVEL="max"
  Write-Host "✅ 已成功切换至 DeepSeek 引擎！" -ForegroundColor Green
}
${MARKER_END}`;
}

// ============ 幂等写入配置文件 ============

/**
 * 将代码块写入目标文件。
 * - 若已存在旧区块，用正则替换（幂等更新）。
 * - 若不存在，追加到文件末尾。
 * 返回 "injected" | "updated"
 */
function writeBlock(rcPath, block) {
  // 确保目标目录存在（Windows PowerShell 目录可能不存在）
  const dir = path.dirname(rcPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  let content = fs.existsSync(rcPath) ? fs.readFileSync(rcPath, "utf-8") : "";

  if (BLOCK_REGEX.test(content)) {
    // 替换旧区块
    content = content.replace(BLOCK_REGEX, block.trim());
    fs.writeFileSync(rcPath, content, "utf-8");
    return "updated";
  }

  // 追加新区块
  const separator = content.length > 0 && !content.endsWith("\n") ? "\n" : "";
  fs.appendFileSync(rcPath, separator + block + "\n", "utf-8");
  return "injected";
}

// ============ 主流程 ============

async function main() {
  console.log("\n🚀 Claude Env Injector — DeepSeek 环境变量注入工具\n");

  const apiKey = await askApiKey();
  const { type, rcPath, sourceCmd } = detectPlatform();
  const block =
    type === "windows"
      ? generateWindowsBlock(apiKey)
      : generateUnixBlock(apiKey);

  const result = writeBlock(rcPath, block);

  if (result === "updated") {
    console.log(`\n🔄 已更新 ${rcPath} 中的 DeepSeek 配置。`);
  } else {
    console.log(`\n✅ 已成功将 use-deepseek 函数注入到 ${rcPath}`);
  }

  console.log(`\n请执行以下命令使其生效：\n`);
  console.log(`  ${sourceCmd}\n`);
  console.log(`然后输入 use-deepseek 即可切换至 DeepSeek 引擎。\n`);
}

main().catch((err) => {
  console.error("❌ 执行出错:", err.message);
  process.exit(1);
});
