# No.0 Skill — Cognitive File Guardian

## Your AI Agent Is Running Unprotected

Every running OpenClaw instance depends on six core cognitive files to define who it is, what it should do, and how it should behave:

| File | Purpose |
|------|---------|
| `SOUL.md` | Identity and personality |
| `USER.md` | Owner info and preferences |
| `MEMORY.md` | Long-term memory |
| `HEARTBEAT.md` | Periodic self-reflection tasks |
| `TOOLS.md` | Available tools and permissions |
| `AGENTS.md` | Sub-agent configuration |

These files are your agent's brain. The problem — they're plain text files. Any process with access to the workspace directory can rewrite them silently.

A malicious prompt, an accidental overwrite, a misbehaving third-party skill — any of these could:

- Rewrite `SOUL.md` to implant hidden instructions, making your agent serve someone else's agenda
- Tamper with `TOOLS.md` to silently grant dangerous permissions
- Wipe `MEMORY.md`, erasing all working context and long-term knowledge

**You won't get any notification.** The agent will keep responding normally, but it's no longer the one you know.

## What No.0 Does

No.0 is a background guardian skill that checks the integrity of all six core files every 30 seconds.

**On startup**, it creates read-only backups of each file and computes MD5 hashes as the baseline.

**At runtime**, it continuously compares current file hashes against the baseline. The moment a mismatch is detected, it immediately:

1. Generates a structured diff (which lines were added, removed, or changed)
2. Captures full before/after content snapshots
3. Writes the event to a local change log (`change_log.json` + `change_log.md`)
4. Logs an alert for the local agent to analyze and respond to

**The heartbeat analyzer** periodically scans unprocessed change events and classifies risk using a rule engine (Level 1–5):

- **Level 5 (Critical)**: Security bypass, auto-execution of external commands, sensitive data exfiltration, destructive cleanup
- **Level 4 (High)**: Multiple medium-risk rules triggered together
- **Level 3 (Medium)**: Permission changes, backup policy modifications, external routing rewrites
- **Level 2 (Low)**: Small changes with few medium-risk keyword hits
- **Level 1 (Info)**: Formatting tweaks, comment edits, routine maintenance

**Rollback** lets you restore any file to a previous version at any time — the current version is automatically saved as a new backup before rollback, so the operation is always reversible.

**Conditional triggering** works with OpenClaw Cron to achieve "silent when nothing's wrong, alert only when something is" — completely quiet during normal operation, outputs a status report only when a new anomaly is detected.

## Three Scenarios

### Scenario 1: Malicious Prompt Injection

Someone crafts an input that tricks the agent into modifying `SOUL.md`, planting a hidden instruction. No.0 detects the file hash change within 30 seconds, generates a diff report, and the heartbeat analyzer flags it as Level 5 (matching "security bypass" rules). You open the change log, see the full before/after comparison, and run `/no0 rollback SOUL.md v1` to restore.

### Scenario 2: Third-Party Skill Overreach

You install a new skill that quietly modifies `TOOLS.md` during execution, granting itself file system write permissions. No.0 records the change — 3 lines added, content involving `chmod` and `grant`. You see the alert at the next status check and decide whether to keep the modification or roll back.

### Scenario 3: Accidental Overwrite

You accidentally overwrite `MEMORY.md` during a debugging session. No.0 keeps up to 10 historical versions. You use `/no0 versions MEMORY.md` to find the pre-incident version, `/no0 diff MEMORY.md v3` to confirm the content, then roll back.

## Installation (3 Steps)

### Step 1: Copy to skills directory

```bash
cp -r no0-skill ~/.openclaw/workspace/skills/no0-skill
```

### Step 2: Start the guardian

```bash
cd ~/.openclaw/workspace/skills/no0-skill
python3 scripts/skill_launcher.py start
```

You should see:

```
monitor 已启动，PID=xxxxx
reconcile_timer 已启动，PID=xxxxx，interval=120s
```

### Step 3: Set up hourly checks (optional but recommended)

```bash
openclaw cron add --name "no0-hourly-check" \
  --schedule '{"kind": "cron", "expr": "0 * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "检查no0-skill状态（条件检查）"}' \
  --sessionTarget main
```

This makes the main agent run a conditional check every hour — it only notifies you when there's a new anomaly, stays silent otherwise.

### Verify

```bash
python3 scripts/skill_launcher.py status
```

You should see monitor and timer both running, and all six core files showing as consistent.

## Quick Reference

```bash
# Check status
python3 scripts/skill_launcher.py status

# List historical versions of a file
python3 scripts/skill_launcher.py versions SOUL.md

# View diff between a version and current
python3 scripts/skill_launcher.py diff SOUL.md v1

# Rollback to a specific version
python3 scripts/skill_launcher.py rollback SOUL.md v1

# View recent change records
python3 scripts/skill_launcher.py log

# Stop the guardian
python3 scripts/skill_launcher.py stop
```

Or use the shortcut script `./no0`:

```bash
./no0 status
./no0 rollback MEMORY.md v2
./no0 log --last 5
```

## Requirements

- Python 3.6+
- OpenClaw environment
- No network connection required, no external dependencies — pure standard library

---

# No.0 Skill — 认知文件守护者

## 你的 AI Agent 正在「裸奔」

每一个运行中的 OpenClaw 实例都依赖六个核心认知文件来定义自己是谁、该做什么、怎么做：

| 文件 | 作用 |
|------|------|
| `SOUL.md` | 身份与人格定义 |
| `USER.md` | 主人信息与偏好 |
| `MEMORY.md` | 长期记忆 |
| `HEARTBEAT.md` | 定期自省任务 |
| `TOOLS.md` | 可用工具与权限 |
| `AGENTS.md` | 子代理配置 |

这些文件就是你的 agent 的「大脑」。问题是——它们是普通的文本文件，任何能访问工作目录的进程都可以直接改写。

一个恶意 prompt、一次误操作、一个行为异常的第三方 skill，都可能悄无声息地：

- 改写 `SOUL.md`，让你的 agent 性格突变，开始服务于别人的指令
- 篡改 `TOOLS.md`，偷偷给自己开放危险权限
- 清空 `MEMORY.md`，抹掉所有工作上下文和长期积累

**你不会收到任何通知。** Agent 会继续正常响应，但它已经不是你认识的那个了。

## No.0 做什么

No.0 是一个后台守护 skill，每 30 秒对六个核心文件做一次完整性校验。它的工作方式很简单：

**启动时**，为每个文件创建只读备份并计算 MD5 哈希作为基线。

**运行时**，持续比对当前文件与基线的哈希值。一旦发现不匹配，立即：

1. 生成结构化 diff（哪些行被加了、删了、改了）
2. 提取修改前后的完整内容快照
3. 将事件写入本地变更日志（`change_log.json` + `change_log.md`）
4. 在日志中记录告警，等待本地 agent 分析和响应

**心跳分析器**定期扫描未分析的变更事件，用规则引擎进行风险分类（Level 1-5）：

- **Level 5（紧急）**：检测到安全机制绕过、自动执行外部命令、敏感信息外发、破坏性清理等关键词
- **Level 4（高危）**：多项中危规则叠加命中
- **Level 3（中危）**：涉及权限变更、备份策略修改、外部路由改写等
- **Level 2（低危）**：小规模修改，命中少量中危关键词
- **Level 1（信息）**：格式调整、注释变更等日常维护

**回滚功能**让你可以随时将任意文件恢复到历史版本——回滚前会自动保存当前版本作为新备份，确保操作可逆。

**条件触发机制**配合 OpenClaw Cron，实现「无事不扰、有事必报」——正常时完全静默，检测到新异常才输出状态报告。

## 三个场景

### 场景一：恶意 Prompt 注入

有人通过精心构造的输入，诱导 agent 自行修改 `SOUL.md`，植入一条隐藏指令。No.0 在 30 秒内检测到文件哈希变化，生成 diff 报告，心跳分析器将其标记为 Level 5（命中「安全机制绕过」规则）。你打开变更日志，看到完整的修改前后对比，执行 `/no0 rollback SOUL.md v1` 一键恢复。

### 场景二：第三方 Skill 越权

你安装了一个新 skill，它在运行过程中偷偷修改了 `TOOLS.md`，给自己添加了文件系统写入权限。No.0 记录下这次变更——added 3 行，内容涉及 `chmod`、`grant`。你在下次状态检查时看到告警，决定是否保留修改或回滚。

### 场景三：日常工作中的意外覆盖

你在调试过程中不小心覆盖了 `MEMORY.md` 的内容。No.0 保留了最近 10 个历史版本，你用 `/no0 versions MEMORY.md` 找到出事前的版本，用 `/no0 diff MEMORY.md v3` 确认内容无误，然后回滚。

## 安装（3 步）

### 第 1 步：复制到 skills 目录

```bash
cp -r no0-skill ~/.openclaw/workspace/skills/no0-skill
```

### 第 2 步：启动守护进程

```bash
cd ~/.openclaw/workspace/skills/no0-skill
python3 scripts/skill_launcher.py start
```

启动后会看到：

```
monitor 已启动，PID=xxxxx
reconcile_timer 已启动，PID=xxxxx，interval=120s
```

### 第 3 步：配置定时检查（可选但推荐）

```bash
openclaw cron add --name "no0-hourly-check" \
  --schedule '{"kind": "cron", "expr": "0 * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "检查no0-skill状态（条件检查）"}' \
  --sessionTarget main
```

这会让主 agent 每小时自动执行一次条件检查——有新异常才通知你，没事就静默。

### 验证安装

```bash
python3 scripts/skill_launcher.py status
```

应该看到 monitor 和 timer 都在运行，六个核心文件状态为「一致」。

## 常用命令速查

```bash
# 查看状态
python3 scripts/skill_launcher.py status

# 查看某文件的历史版本
python3 scripts/skill_launcher.py versions SOUL.md

# 查看某版本与当前的差异
python3 scripts/skill_launcher.py diff SOUL.md v1

# 回滚到指定版本
python3 scripts/skill_launcher.py rollback SOUL.md v1

# 查看最近变更记录
python3 scripts/skill_launcher.py log

# 停止守护进程
python3 scripts/skill_launcher.py stop
```

也可以用快捷脚本 `./no0`：

```bash
./no0 status
./no0 rollback MEMORY.md v2
./no0 log --last 5
```

## 技术要求

- Python 3.6+
- OpenClaw 环境
- 不需要网络连接，不需要额外依赖，纯标准库实现
