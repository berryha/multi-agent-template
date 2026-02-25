#!/bin/bash
# 多 Agent 团队配置 - 直接编辑后执行 ./bootstrap-multi-agent.sh
# 用法: 编辑本文件 -> 在目标目录执行 bash bootstrap-multi-agent.sh

# ============ 协调员 ============
COORDINATOR_ID=defaults
COORDINATOR_NAME=三三
COORDINATOR_EMOJI=🤝

# ============ 服务对象（如三哥/张三） ============
OWNER_NAME=张三
OWNER_TITLE=三哥
OWNER_TIMEZONE=Asia/Shanghai
OWNER_NOTES="Android 项目领导；最终决策与审批由三哥负责。高风险建议需三哥审批，关键系统问题需立即上报三哥。"
OWNER_PROJECT="领导 Android 项目，带领 Android Framework 专业服务团队"

# ============ 模型 API ============
MODEL_DEFAULT=siliconflow/deepseek-ai/DeepSeek-V3.2
# 智谱
ZHIPU_APIKEY=afeb5f65241b4ca6b0f1138e10b16a42.JHmCbbwfGTRkxxxx
ZHIPU_BASE=https://open.bigmodel.cn/api/paas/v4
# SiliconFlow（DeepSeek）
SILICONFLOW_APIKEY=sk-jlpskggbufyhslqkxunchkfjazlvwcpykjhvozhvmkdxxxxx
SILICONFLOW_BASE=https://api.siliconflow.cn/v1

# ============ 飞书账户（id:name:appId:appSecret:description，用 | 分隔多个） ============
FEISHU_ACCOUNTS="defaults:三三:App_ID:App_Secret:三哥的总助理，Android专业团队的协调员！|\
jika:技咖:App_ID:App_Secret:Android Framework深度技术专家|\
shika:师咖:App_ID:App_Secret:技术培训专家|\
ceka:测咖:App_ID:App_Secret:测试方案专家|\
shuka:数咖:App_ID:App_Secret:汇报数据专家"

# ============ 专家列表（id:name:emoji:skillDir:description:specialties，用 | 分隔多个） ============
EXPERTS="jika:技咖:🤖:android-framework-expert:Android Framework 深度技术专家:Framework、HAL、显示系统、Binder、性能优化、系统服务|\
shika:师咖:🎓:tech-training-expert:技术培训专家:技术知识转化、培训材料、学习路径、文档编写|\
ceka:测咖:🧪:test-solution-expert:测试方案专家:测试计划、用例生成、自动化测试、覆盖率分析|\
shuka:数咖:📊:reporting-data-expert:汇报数据专家:数据对比、可视化、专业汇报、ROI分析"

# ============ 工作区路径（. 表示配置文件所在目录） ============
WORKSPACE_BASE=.

# ============ 模板目录（将脚本复制到目标目录运行时必填） ============
# 留空 = 使用脚本所在目录；若脚本在 dandan 则填 ../multi-agent-template
TEMPLATE_DIR=../multi-agent-template
