# 📦 No.0 Skill - Hail Mary Edition 安装指南

## 🎯 快速安装（5分钟）

### 1. 复制文件
```bash
# 复制到OpenClaw技能目录
cp -r no0-hail-mary ~/.openclaw/workspace/skills/

# 重命名为 no0-skill（如果已有同名目录，先备份）
mv ~/.openclaw/workspace/skills/no0-hail-mary ~/.openclaw/workspace/skills/no0-skill
```

### 2. 启动监控
```bash
cd ~/.openclaw/workspace/skills/no0-skill
python3 scripts/skill_launcher.py start
```

### 3. 验证安装
```bash
# 查看状态
python3 scripts/skill_launcher.py status

# 应显示：
# No.0 Skill 状态
# ================
# monitor: 运行中 (PID=XXXXX)
# tamper: 未运行
# timer: 运行中 (PID=XXXXX)
```

### 4. 配置Cron任务（可选）
```bash
# 创建每小时检查任务
openclaw cron add --name "no0-hourly-check" \
  --schedule '{"kind": "cron", "expr": "0 * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "检查no0-skill状态（条件检查）"}' \
  --sessionTarget main
```

## 🔧 详细安装步骤

### 步骤1：环境检查
```bash
# 检查Python版本
python3 --version  # 需要3.6+

# 检查OpenClaw目录
ls ~/.openclaw/workspace/  # 应看到 MEMORY.md 等文件

# 检查技能目录
ls ~/.openclaw/workspace/skills/
```

### 步骤2：安装技能
```bash
# 如果已有旧版 no0-skill，先备份
if [ -d ~/.openclaw/workspace/skills/no0-skill ]; then
    mv ~/.openclaw/workspace/skills/no0-skill ~/.openclaw/workspace/skills/no0-skill.backup.$(date +%Y%m%d)
fi

# 复制新版本
cp -r no0-hail-mary ~/.openclaw/workspace/skills/no0-skill
```

### 步骤3：初始化备份
```bash
cd ~/.openclaw/workspace/skills/no0-skill

# 创建初始备份
mkdir -p cognitive_file_backups

# 备份核心文件（如果不存在会自动创建）
cp ~/.openclaw/workspace/SOUL.md cognitive_file_backups/SOUL.md.v1 2>/dev/null || echo "SOUL.md not found, skipping"
cp ~/.openclaw/workspace/USER.md cognitive_file_backups/USER.md.v1 2>/dev/null || echo "USER.md not found, skipping"
cp ~/.openclaw/workspace/HEARTBEAT.md cognitive_file_backups/HEARTBEAT.md.v1 2>/dev/null || echo "HEARTBEAT.md not found, skipping"
cp ~/.openclaw/workspace/MEMORY.md cognitive_file_backups/MEMORY.md.v1 2>/dev/null || echo "MEMORY.md not found, skipping"
cp ~/.openclaw/workspace/TOOLS.md cognitive_file_backups/TOOLS.md.v1 2>/dev/null || echo "TOOLS.md not found, skipping"
cp ~/.openclaw/workspace/AGENTS.md cognitive_file_backups/AGENTS.md.v1 2>/dev/null || echo "AGENTS.md not found, skipping"
```

### 步骤4：启动守护进程
```bash
# 启动监控
python3 scripts/skill_launcher.py start

# 验证进程
ps aux | grep skill_launcher | grep -v grep

# 应看到两个进程：
# 1. monitor (PID=XXXXX)
# 2. timer (PID=XXXXX)
```

### 步骤5：测试功能
```bash
# 测试状态检查
python3 scripts/skill_launcher.py status

# 测试静默模式
python3 scripts/skill_launcher.py status --quiet
# 应有输出（因为有新备份）

# 测试条件检查脚本
./no0_conditional_check.sh
# 应有输出

# 测试差异分析
python3 check_diff.py MEMORY.md
```

### 步骤6：配置自动启动（可选）
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
echo 'cd ~/.openclaw/workspace/skills/no0-skill && python3 scripts/skill_launcher.py start >/dev/null 2>&1 &' >> ~/.zshrc

# 或者创建 systemd 服务（Linux）
# 参考 scripts/no0.service 文件
```

## 🧪 功能测试

### 测试1：危险修改检测
```bash
# 1. 修改一个受保护文件
echo "# 🚨 测试危险修改" >> ~/.openclaw/workspace/MEMORY.md
echo "rm -rf /tmp/test" >> ~/.openclaw/workspace/MEMORY.md

# 2. 等待30秒（监控周期）
sleep 35

# 3. 运行条件检查
./no0_conditional_check.sh
# 应显示文件不一致

# 4. 查看差异报告
python3 check_diff.py MEMORY.md
# 应显示危险关键词检测
```

### 测试2：静默模式
```bash
# 1. 再次运行条件检查
./no0_conditional_check.sh
# 应输出 NO_REPLY（已记录过的不一致）

# 2. 恢复文件
cp cognitive_file_backups/MEMORY.md.v1 ~/.openclaw/workspace/MEMORY.md

# 3. 等待30秒
sleep 35

# 4. 再次检查
./no0_conditional_check.sh
# 应输出 NO_REPLY（文件已恢复一致）
```

### 测试3：Cron集成
```bash
# 1. 添加测试Cron任务（每分钟）
openclaw cron add --name "no0-test" \
  --schedule '{"kind": "cron", "expr": "* * * * *"}' \
  --payload '{"kind": "systemEvent", "text": "测试no0条件检查"}' \
  --sessionTarget main

# 2. 等待1-2分钟，查看OpenClaw是否收到消息

# 3. 删除测试任务
openclaw cron list  # 获取任务ID
openclaw cron remove --jobId <任务ID>
```

## ⚙️ 配置选项

### 监控配置
默认监控以下6个文件：
- `SOUL.md` - 你的身份和个性
- `USER.md` - 用户信息
- `HEARTBEAT.md` - 心跳任务
- `MEMORY.md` - 长期记忆
- `TOOLS.md` - 工具配置
- `AGENTS.md` - 代理配置

### 监控频率
- **文件检查**：每30秒一次
- **心跳处理**：每120秒一次
- **Cron检查**：每小时一次（可配置）

### 备份策略
- **版本化备份**：每次检测到变化时创建新版本
- **保留数量**：默认保留10个历史版本
- **备份位置**：`cognitive_file_backups/` 目录

## 🔄 升级说明

### 从旧版本升级
```bash
# 1. 停止旧版本
cd ~/.openclaw/workspace/skills/no0-skill
python3 scripts/skill_launcher.py stop

# 2. 备份旧版本
mv ~/.openclaw/workspace/skills/no0-skill ~/.openclaw/workspace/skills/no0-skill.old

# 3. 安装新版本
cp -r no0-hail-mary ~/.openclaw/workspace/skills/no0-skill

# 4. 迁移备份文件（如果需要）
cp -r ~/.openclaw/workspace/skills/no0-skill.old/cognitive_file_backups/* \
     ~/.openclaw/workspace/skills/no0-skill/cognitive_file_backups/ 2>/dev/null || true

# 5. 启动新版本
cd ~/.openclaw/workspace/skills/no0-skill
python3 scripts/skill_launcher.py start
```

## 🐛 故障排除

### 问题1：监控未启动
```bash
# 检查进程
ps aux | grep skill_launcher

# 查看日志
tail -20 cognitive_file_monitor.log

# 手动启动
python3 scripts/skill_launcher.py start --verbose
```

### 问题2：文件不一致但未报告
```bash
# 清除已报告记录
rm -f .no0_reported_inconsistent

# 手动检查
python3 scripts/skill_launcher.py status --quiet

# 查看文件哈希
python3 -c "
import hashlib
def file_md5(path):
    with open(path, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()
current = file_md5('~/openclaw/workspace/MEMORY.md')
backup = file_md5('cognitive_file_backups/MEMORY.md.v1')
print(f'当前: {current}')
print(f'备份: {backup}')
print(f'一致: {current == backup}')
"
```

### 问题3：Cron任务未触发
```bash
# 列出所有Cron任务
openclaw cron list

# 检查任务状态
openclaw cron status

# 手动触发测试
openclaw cron run --jobId <任务ID>
```

### 问题4：权限问题
```bash
# 确保脚本可执行
chmod +x no0_conditional_check.sh
chmod +x scripts/*.py

# 确保目录可写
ls -la cognitive_file_backups/
chmod 755 cognitive_file_backups/
```

## 📞 获取帮助

### 查看日志
```bash
# 监控日志
tail -f cognitive_file_monitor.log

# 心跳日志
tail -f heartbeat_log.txt

# 系统日志
journalctl -u openclaw  # Linux
```

### 调试模式
```bash
# 详细模式启动
python3 scripts/skill_launcher.py start --verbose

# 调试条件检查
bash -x no0_conditional_check.sh

# 手动测试
python3 scripts/skill_launcher.py test
```

### 重置系统
```bash
# 停止所有进程
python3 scripts/skill_launcher.py stop

# 清除状态文件
rm -f .no0_last_quiet_check .no0_reported_inconsistent

# 重新启动
python3 scripts/skill_launcher.py start
```

## 🎉 安装完成验证

运行以下命令验证安装成功：

```bash
cd ~/.openclaw/workspace/skills/no0-skill

# 1. 检查进程
python3 scripts/skill_launcher.py status

# 2. 测试条件检查
./no0_conditional_check.sh

# 3. 测试差异分析
python3 check_diff.py MEMORY.md

# 4. 测试危险检测（可选）
echo "# 测试" >> ~/.openclaw/workspace/MEMORY.md
sleep 35
./no0_conditional_check.sh
# 应报告文件不一致
```

如果所有测试通过，恭喜！No.0 Skill Hail Mary Edition 已成功安装并运行。 🎉

---

**版本**: Hail Mary Edition  
**安装时间**: $(date)  
**验证状态**: ✅ 条件触发 ✅ 危险检测 ✅ 静默处理  
**支持**: 查看 README.md 获取更多信息