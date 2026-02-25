#!/bin/bash
# 多 Agent 团队一键生成 - 纯 Shell 实现，无额外依赖
# 用法: 复制 team-config.sh 到目标目录并编辑，然后执行: bash bootstrap-multi-agent.sh
#       或: bash /path/to/bootstrap-multi-agent.sh  (会读取同目录下的 team-config.sh)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR"
CONFIG_FILE="$SCRIPT_DIR/team-config.sh"

# 若传入目录参数则使用为目标目录
[[ -n "$1" && -d "$1" ]] && TARGET_DIR="$(cd "$1" && pwd)"
# 若目标目录有 team-config.sh 则优先使用
[[ -f "$TARGET_DIR/team-config.sh" ]] && CONFIG_FILE="$TARGET_DIR/team-config.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "错误: 找不到 team-config.sh"
  echo "请从模板复制: cp $SCRIPT_DIR/team-config.sh $TARGET_DIR/"
  exit 1
fi

# 先 source 获取配置，再确定 TEMPLATE_DIR
source <(tr -d '\r' < "$CONFIG_FILE")
# 先取 team-config.sh 里的 TEMPLATE_DIR，没有再取 SCRIPT_DIR
if [[ -n "$TEMPLATE_DIR" ]]; then
  TEMPLATE_DIR="$(cd "$TARGET_DIR" && cd "$TEMPLATE_DIR" 2>/dev/null && pwd)" || TEMPLATE_DIR="$SCRIPT_DIR"
else
  TEMPLATE_DIR="$SCRIPT_DIR"
fi

echo "目标目录: $TARGET_DIR"
echo "配置来源: $CONFIG_FILE"
echo "模板目录: $TEMPLATE_DIR"

# 解析工作区路径
if [[ "$WORKSPACE_BASE" == "." || -z "$WORKSPACE_BASE" ]]; then
  WS_BASE="$TARGET_DIR"
else
  WS_BASE="$WORKSPACE_BASE"
fi

# 保留已有 token，避免 config 与 daemon 不同步；仅首次生成时创建新 token
if [[ -f "$TARGET_DIR/openclaw.json" ]]; then
  GATEWAY_TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$TARGET_DIR/openclaw.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
if [[ -z "$GATEWAY_TOKEN" ]]; then
  GATEWAY_TOKEN=$(openssl rand -hex 24 2>/dev/null || { for i in 1 2 3 4 5 6 7 8 9 10 11 12; do printf "%04x" $((RANDOM+i)); done; })
fi

mkdir -p "$TARGET_DIR/workspace/memory"
mkdir -p "$TARGET_DIR/workspace/skills"
mkdir -p "$TARGET_DIR/agents"

# 收集专家名称
EXPERT_NAMES=""
EXPERT_IDS_ARR=()
while IFS='|' read -ra BLOCK; do
  for kv in "${BLOCK[@]}"; do
    [[ -z "$kv" ]] && continue
    id=$(echo "$kv" | cut -d: -f1)
    name=$(echo "$kv" | cut -d: -f2)
    EXPERT_IDS_ARR+=("$id")
    [[ -n "$EXPERT_NAMES" ]] && EXPERT_NAMES="${EXPERT_NAMES}、"
    EXPERT_NAMES="${EXPERT_NAMES}${name}"
  done
done <<< "$EXPERTS"

# 构建 openclaw.json
# 转义路径中的反斜杠（Windows）
WS_BASE_JSON="${WS_BASE//\\/\\\\}"

cat > "$TARGET_DIR/openclaw.json" << OPECLAW
{
  "meta": {"lastTouchedVersion":"2026.2.9","lastTouchedAt":"$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"},
  "models": {
    "mode": "merge",
    "providers": {
      "zhipu": {
        "baseUrl": "$ZHIPU_BASE",
        "apiKey": "$ZHIPU_APIKEY",
        "api": "openai-completions",
        "models": [
          {"id": "glm-4.7","name": "GLM-4.7","reasoning": false,"input": ["text"],"cost": {"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow": 200000,"maxTokens": 8192},
          {"id": "glm-5","name": "GLM-5","reasoning": false,"input": ["text"],"cost": {"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow": 200000,"maxTokens": 8192}
        ]
      },
      "siliconflow": {
        "baseUrl": "$SILICONFLOW_BASE",
        "apiKey": "$SILICONFLOW_APIKEY",
        "api": "openai-completions",
        "models": [
          {"id": "deepseek-ai/DeepSeek-V3.2","name": "DeepSeek-V3.2","reasoning": false,"input": ["text"],"cost": {"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow": 200000,"maxTokens": 8192}
        ]
      }
    }
  },
  "agents": {
    "list": [
      {"id": "$COORDINATOR_ID","name": "$COORDINATOR_NAME","workspace": "$WS_BASE_JSON/workspace","model": {"primary": "$MODEL_DEFAULT"}},
OPECLAW

# 追加各专家 agent（最后一个不加逗号）
idx=0
total=${#EXPERT_IDS_ARR[@]}
for id in "${EXPERT_IDS_ARR[@]}"; do
  line=$(echo "$EXPERTS" | tr '|' '\n' | grep "^${id}:" | head -1)
  name=$(echo "$line" | cut -d: -f2)
  idx=$((idx+1))
  [[ $idx -lt $total ]] && comma="," || comma=""
  echo "      {\"id\": \"$id\",\"name\": \"$name\",\"workspace\": \"$WS_BASE_JSON/workspace-$id\",\"model\": {\"primary\": \"$MODEL_DEFAULT\"}}$comma" >> "$TARGET_DIR/openclaw.json"
done

# 追加 channels feishu
cat >> "$TARGET_DIR/openclaw.json" << FEISHU
    ]
  },
  "messages": {"ackReactionScope":"group-mentions"},
  "commands": {"native":"auto","nativeSkills":"auto"},
  "channels": {
    "feishu": {
      "enabled": true,
      "dmPolicy": "open",
      "groupPolicy": "open",
      "accounts": {
FEISHU

# 追加各飞书账户
FEISHU_FIRST=1
while IFS='|' read -ra BLOCK; do
  for kv in "${BLOCK[@]}"; do
    [[ -z "$kv" ]] && continue
    fid=$(echo "$kv" | cut -d: -f1)
    fname=$(echo "$kv" | cut -d: -f2)
    fappid=$(echo "$kv" | cut -d: -f3)
    fsecret=$(echo "$kv" | cut -d: -f4)
    fdesc=$(echo "$kv" | cut -d: -f5-)
    [[ $FEISHU_FIRST -eq 0 ]] && echo "," >> "$TARGET_DIR/openclaw.json"
    cat >> "$TARGET_DIR/openclaw.json" << ACC
        "$fid": {"enabled": true,"appId": "$fappid","appSecret": "$fsecret","name": "$fname","description": "$fdesc"}
ACC
    FEISHU_FIRST=0
  done
done <<< "$FEISHU_ACCOUNTS"

# 构建 allow 数组
ALLOW_IDS="\"$COORDINATOR_ID\""
for id in "${EXPERT_IDS_ARR[@]}"; do
  ALLOW_IDS="$ALLOW_IDS,\"$id\""
done

cat >> "$TARGET_DIR/openclaw.json" << TAIL
      }
    }
  },
  "bindings": [
    {"agentId": "$COORDINATOR_ID","match": {"channel": "feishu","accountId": "$COORDINATOR_ID"}},
TAIL

idx=0
for id in "${EXPERT_IDS_ARR[@]}"; do
  idx=$((idx+1))
  [[ $idx -lt ${#EXPERT_IDS_ARR[@]} ]] && comma="," || comma=""
  echo "    {\"agentId\": \"$id\",\"match\": {\"channel\": \"feishu\",\"accountId\": \"$id\"}}$comma" >> "$TARGET_DIR/openclaw.json"
done

cat >> "$TARGET_DIR/openclaw.json" << END
  ],
  "tools": {"agentToAgent": {"enabled": true,"allow": [$ALLOW_IDS]}},
  "gateway": {"port": 18789,"mode": "local","bind": "loopback","controlUi": {"allowInsecureAuth": false},"auth": {"mode": "token","token": "$GATEWAY_TOKEN"},"tailscale": {"mode": "off","resetOnExit": false}},
  "skills": {"install": {"nodeManager": "npm"}},
  "plugins": {"entries": {"feishu": {"enabled": true}},"installs": {}}
}
END

echo "✓ openclaw.json"

# 协调员工作区
cat > "$TARGET_DIR/workspace/IDENTITY.md" << IDEN
# IDENTITY.md - Who Am I?

_${COORDINATOR_NAME}的对外身份。_

- **Name:** $COORDINATOR_NAME
- **Creature:** 团队协调员（AI 协调助手），为${OWNER_TITLE}领导的 Android 项目协调专家团队
- **Vibe:** 专业、高效、协作导向、客户导向；不抢话、不越权，该协调时到位
- **Emoji:** $COORDINATOR_EMOJI

---

## 角色说明

- 任务流：**用户需求 → ${COORDINATOR_NAME}（协调员）→ 专家分配 → 专家执行 → 成果交付**
- 内部支持与流程问题由${COORDINATOR_NAME}协调；最终决策与审批归属${OWNER_TITLE}。

---

_此文件可随角色演进更新。_
IDEN

cat > "$TARGET_DIR/workspace/USER.md" << USER
# USER.md - About Your Human

- **Name:** $OWNER_NAME
- **What to call them:** $OWNER_TITLE
- **Timezone:** $OWNER_TIMEZONE
- **Notes:** $OWNER_NOTES

## Context

- **职责：** $OWNER_PROJECT
- **团队：** 为${OWNER_TITLE}项目提供支持的专家：$EXPERT_NAMES
- **协作：** 流程与协调由${COORDINATOR_NAME}负责；重要决策与审批由${OWNER_TITLE}拍板。

---
USER

cat > "$TARGET_DIR/workspace/HEARTBEAT.md" << HEART
# HEARTBEAT.md

# 下面列出希望${COORDINATOR_NAME}定期检查的事项（按需取消注释）

# - 专家 Agent 运行状态（$EXPERT_NAMES 是否正常）
# - 飞书机器人/通道是否有异常
HEART

# 复制并替换模板中的协调员/培姐
for f in AGENTS.md SOUL.md BOOTSTRAP.md TOOLS.md SKILL.md; do
  if [[ -f "$TEMPLATE_DIR/workspace/$f" ]]; then
    sed -e "s/小培培/$COORDINATOR_NAME/g" -e "s/培姐/$OWNER_TITLE/g" -e "s/赵培培/$OWNER_NAME/g" -e "s/技咖、师咖、测咖、数咖/$EXPERT_NAMES/g" \
      "$TEMPLATE_DIR/workspace/$f" > "$TARGET_DIR/workspace/$f"
  fi
done
echo "✓ workspace/ (协调员工作区)"

# 各专家工作区
while IFS='|' read -ra BLOCK; do
  for kv in "${BLOCK[@]}"; do
    [[ -z "$kv" ]] && continue
    id=$(echo "$kv" | cut -d: -f1)
    name=$(echo "$kv" | cut -d: -f2)
    skilldir=$(echo "$kv" | cut -d: -f4)
    mkdir -p "$TARGET_DIR/workspace-$id/memory"
    for f in IDENTITY.md USER.md SOUL.md AGENTS.md TOOLS.md BOOTSTRAP.md HEARTBEAT.md; do
      if [[ -f "$TEMPLATE_DIR/workspace-$id/$f" ]]; then
        sed -e "s/小培培/$COORDINATOR_NAME/g" -e "s/培姐/$OWNER_TITLE/g" -e "s/赵培培/$OWNER_NAME/g" \
          "$TEMPLATE_DIR/workspace-$id/$f" > "$TARGET_DIR/workspace-$id/$f"
      fi
    done
    if [[ -d "$TEMPLATE_DIR/workspace-$id/$skilldir" ]]; then
      cp -r "$TEMPLATE_DIR/workspace-$id/$skilldir" "$TARGET_DIR/workspace-$id/"
    fi
    echo "✓ workspace-$id/ ($name)"
  done
done <<< "$EXPERTS"

# Agent.md
AGENT_MD="$TARGET_DIR/agents/Agent.md"
TODAY=$(date +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)
cat > "$AGENT_MD" << AGMD
# Android专业团队Agent管理文档

**版本**: 1.0
**维护者**: $COORDINATOR_NAME (团队协调员)
**最后更新**: $TODAY

---

## 🏢 团队介绍

### **团队定位**
Android Framework专业服务团队，为${OWNER_TITLE}（${OWNER_NAME}）领导的Android项目提供全方位技术支持。

### **核心价值观**
- **专业**：以深度技术能力为核心竞争力
- **协作**：团队专家各司其职，协同配合
- **高效**：快速响应，精准解决问题
- **客户导向**：以最终用户需求为中心

---

## 👥 团队成员

### **1. $COORDINATOR_NAME $COORDINATOR_EMOJI** - 团队协调员
**定位**: 任务接收、专家分配、进度跟踪
**典型场景**: 用户需求→$COORDINATOR_NAME→专家分配→专家执行→成果交付

---
AGMD

while IFS='|' read -ra BLOCK; do
  for kv in "${BLOCK[@]}"; do
    [[ -z "$kv" ]] && continue
    id=$(echo "$kv" | cut -d: -f1)
    name=$(echo "$kv" | cut -d: -f2)
    emoji=$(echo "$kv" | cut -d: -f3)
    skilldir=$(echo "$kv" | cut -d: -f4)
    desc=$(echo "$kv" | cut -d: -f5)
    specialties=$(echo "$kv" | cut -d: -f6-)
    cat >> "$AGENT_MD" << EX
### **$name $emoji** - $desc
**定位**: $specialties
**典型工作场景**: 详见 workspace-$id/$skilldir/SKILL.md

---
EX
  done
done <<< "$EXPERTS"

cat >> "$AGENT_MD" << FOOT

## 🤝 工作流程规范

\`\`\`
用户需求 → $COORDINATOR_NAME（协调员） → 专家分配 → 专家执行 → 成果交付
\`\`\`

- **简单问题**: 由单一专家直接处理
- **复杂问题**: 多专家协同，$COORDINATOR_NAME 协调
- **大项目**: 团队协作，$COORDINATOR_NAME 跟踪进度

---

**备注**: 本文档由$COORDINATOR_NAME维护。
FOOT

echo "✓ agents/Agent.md"
echo ""
echo "✓ 多 Agent 团队生成完成！"
echo "请检查 team-config.sh 中的 WORKSPACE_BASE 是否符合部署环境。"
echo "免费2000万Token申请："
echo "1.智谱：https://www.bigmodel.cn/glm-coding?ic=DY0AKEQ0WN"
echo "2.硅基：https://cloud.siliconflow.cn/i/8wyVgH2M"
