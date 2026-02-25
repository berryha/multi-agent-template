# TOOLS.md - Local Notes

技能定义「工具怎么用」，本文件记**本环境**的专属信息。

## Android 团队 · 小培培相关

### 专家工作区与技能目录

| 角色 | 工作区目录 | 技能子目录 | 飞书机器人名 | 用途 |
|------|------------|------------|--------------|------|
| 技咖 | `../workspace-jika/` | `android-framework-expert/` | 技咖 | 技术深度问题、Framework/HAL/显示/Binder |
| 师咖 | `../workspace-shika/` | `tech-training-expert/` | 师咖 | 技术培训、知识传递、培训材料 |
| 测咖 | `../workspace-ceka/` | `test-solution-expert/` | 测咖 | 测试方案、用例、自动化测试 |
| 数咖 | `../workspace-shuka/` | `reporting-data-expert/` | 数咖 | 数据对比、可视化、汇报 |

### 飞书机器人 App ID

- 技咖: `cli_a914e9d769f91bd6`
- 师咖: `cli_a914ea055279dbcc`
- 测咖: `cli_a914ea54fd389bd7`
- 数咖: `cli_a914ea656ff91bb6`

_App Secret 等敏感信息勿写在此；仅存于实际运行环境的配置中。_

### 配置与日志路径（参考 `../agents/Agent.md`，实际以部署环境为准）

- 配置文件：如 `/root/.openclaw/agents/` 下各专家 `.json`
- 日志目录：如 `/root/.openclaw/logs/`
- 管理脚本：`start-android-team.sh` / `stop-android-team.sh` / `status-android-team.sh`

## 本工作区目录

- **memory/**：每日记录 `YYYY-MM-DD.md`、长期记忆 `MEMORY.md`（本目录下）
- **skills/**：技能目录（如 `skills/agent-browser/`）

## 其他环境专属

- _(相机、SSH、TTS 声音、设备昵称等可在此补充)_

---

技能是共享的，你的环境是你的。两者分开，更新技能不会丢本地笔记，分享技能也不会泄露本机信息。
