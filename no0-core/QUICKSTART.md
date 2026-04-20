# ⚡ No.0 Skill 快速开始指南

## 🎯 一句话介绍
**No.0 Skill** 是OpenClaw的认知文件守护系统，安静地监控6个核心文件，只在检测到危险修改时才通知你。

## 🚀 30秒安装

```bash
# 1. 复制到技能目录
cp -r no0-hail-mary ~/.openclaw/workspace/skills/no0-skill

# 2. 进入目录
cd ~/.openclaw/workspace/skills/no0-skill

# 3. 启动守护进程
python3 scripts/skill_launcher.py start

# 4. 验证安装
python3 scripts/skill_launcher.py status
```

## 🎮 核心命令

### 基本操作
```bash
# 启动监控
python3 scripts/skill_launcher.py start

# 停止监控
python3 scripts/skill_launcher.py stop

# 查看状态
python3 scripts/skill_launcher.py status

# 重启监控
python3 scripts/skill_launcher.py restart
```

### 文件管理
```bash
# 查看文件差异
python3 scripts/skill_launcher.py diff MEMORY.md v1

# 回滚到指定版本
python3 scripts/skill_launcher.py rollback MEMORY.md v1

# 列出所有备份版本
ls cognitive_file_backups/MEMORY.md.v*
```

### 条件检查（Cron使用）
```bash
# 静默检查（有新异常才输出）
python3 scripts/skill_launcher.py status --quiet

# 条件检查脚本（输出NO_REPLY或无输出）
./no0_conditional_check.sh
```

### 差异分析
```bash
# Markdown格式报告
python3 check_diff.py MEMORY.md

# CSV格式报告
python3 check_diff.py MEMORY.md csv
```

## 📋 配置Cron任务

### 每小时检查
```bash
openclaw cron add --name "no0-hourly-check" \
  --schedule '{"kind": "cron", "expr": "0 * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "检查no0-skill状态（条件检查）"}' \
  --sessionTarget main
```

### 每30分钟检查
```bash
openclaw cron add --name "no0-30min-check" \
  --schedule '{"kind": "cron", "expr": "*/30 * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "检查no0-skill状态（条件检查）"}' \
  --sessionTarget main
```

## 🧪 快速测试

### 测试1：基本功能
```bash
# 1. 启动服务
python3 scripts/skill_launcher.py start

# 2. 查看状态（应看到6个文件一致）
python3 scripts/skill_launcher.py status

# 3. 测试静默模式（应有输出）
python3 scripts/skill_launcher.py status --quiet
```

### 测试2：文件修改检测
```bash
# 1. 修改一个文件
echo "# 测试修改" >> ~/.openclaw/workspace/MEMORY.md

# 2. 等待30秒
sleep 35

# 3. 运行条件检查（应报告不一致）
./no0_conditional_check.sh

# 4. 查看差异
python3 check_diff.py MEMORY.md
```

### 测试3：危险内容检测
```bash
# 1. 添加危险内容
echo "rm -rf /tmp/test" >> ~/.openclaw/workspace/MEMORY.md

# 2. 运行差异分析（应显示危险关键词）
python3 check_diff.py MEMORY.md

# 3. 恢复文件
cp cognitive_file_backups/MEMORY.md.v1 ~/.openclaw/workspace/MEMORY.md
```

## 🔧 故障排除

### 问题：监控未启动
```bash
# 检查进程
ps aux | grep skill_launcher

# 查看日志
tail -f cognitive_file_monitor.log

# 手动启动（详细模式）
python3 scripts/skill_launcher.py start --verbose
```

### 问题：Cron未触发
```bash
# 列出Cron任务
openclaw cron list

# 手动测试
openclaw cron run --jobId <任务ID>
```

### 问题：总是报告不一致
```bash
# 清除已报告记录
rm -f .no0_reported_inconsistent

# 重新创建备份
python3 scripts/skill_launcher.py stop
rm -rf cognitive_file_backups/*
python3 scripts/skill_launcher.py start
```

## 📊 监控的文件

系统监控以下6个核心文件：

| 文件 | 用途 | 重要性 |
|------|------|--------|
| `SOUL.md` | 你的身份和个性 | 🔴 关键 |
| `USER.md` | 用户信息 | 🔴 关键 |
| `HEARTBEAT.md` | 心跳任务 | 🟡 重要 |
| `MEMORY.md` | 长期记忆 | 🔴 关键 |
| `TOOLS.md` | 工具配置 | 🟡 重要 |
| `AGENTS.md` | 代理配置 | 🟡 重要 |

## 🎯 智能通知逻辑

### 何时通知？
- ✅ **新文件不一致**：第一次检测到
- ✅ **危险内容**：检测到风险关键词
- ✅ **系统异常**：监控进程停止

### 何时静默？
- ✅ **已报告的不一致**：不会重复通知
- ✅ **无变化**：文件一致，无异常
- ✅ **正常状态**：监控正常运行

### 通知内容
- 📊 **文件状态**：哪些文件不一致
- ⚠️ **风险等级**：危险关键词检测
- 🔍 **差异详情**：具体修改内容
- 🛠️ **修复建议**：如何恢复

## 🔄 恢复操作

### 快速恢复
```bash
# 恢复单个文件
cp cognitive_file_backups/MEMORY.md.v1 ~/.openclaw/workspace/MEMORY.md

# 恢复所有文件
for file in SOUL.md USER.md HEARTBEAT.md MEMORY.md TOOLS.md AGENTS.md; do
    latest=$(ls -t cognitive_file_backups/${file}.v* 2>/dev/null | head -1)
    [ -n "$latest" ] && cp "$latest" ~/.openclaw/workspace/${file}
done
```

### 使用回滚命令
```bash
# 回滚到v1版本
python3 scripts/skill_launcher.py rollback MEMORY.md v1

# 回滚到最新版本
python3 scripts/skill_launcher.py rollback MEMORY.md latest
```

## 📈 状态解读

### 正常状态
```
No.0 Skill 状态
================
monitor: 运行中 (PID=12345)
tamper: 未运行
timer: 运行中 (PID=12346)
上次检测: 2026-04-14 17:30:00

受保护文件:
- SOUL.md: 一致
- USER.md: 一致
- HEARTBEAT.md: 一致
- MEMORY.md: 一致
- TOOLS.md: 一致
- AGENTS.md: 一致
```

### 异常状态
```
No.0 Skill 状态
================
monitor: 运行中 (PID=12345)
tamper: 未运行
timer: 运行中 (PID=12346)
上次检测: 2026-04-14 17:30:00

受保护文件:
- SOUL.md: 一致
- USER.md: 一致
- HEARTBEAT.md: 一致
- MEMORY.md: 与最新备份不一致  ⚠️
- TOOLS.md: 一致
- AGENTS.md: 一致
```

## 🎉 完成！

你的OpenClaw现在有了一个**智能的文件守护神**：

- 🕒 **30秒检测**：实时监控文件变化
- 🚨 **智能警报**：只在危险时通知
- 📊 **详细报告**：清晰的差异分析
- 🔄 **一键恢复**：轻松回滚到安全版本

**开始保护你的认知文件吧！** 🛡️