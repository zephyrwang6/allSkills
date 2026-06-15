#!/usr/bin/env bash
# 扫描 ~/.claude/skills/ 下所有 Skill，输出 name + description 摘要
# 用法：bash scan_skills.sh [skill_dir]
set -eo pipefail

SKILL_DIR="${1:-$HOME/.claude/skills}"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Skill 目录不存在: $SKILL_DIR" >&2
  exit 1
fi

total=0
echo "=== Skill 清单（$SKILL_DIR） ==="
echo ""

for d in "$SKILL_DIR"/*/; do
  [[ -d "$d" ]] || continue
  name=$(basename "$d")
  skill_md=""
  for cand in "SKILL.md" "skill.md" "Skill.md"; do
    if [[ -f "$d$cand" ]]; then
      skill_md="$d$cand"
      break
    fi
  done

  if [[ -z "$skill_md" ]]; then
    echo "[$name]"
    echo "  (无 SKILL.md，可能是嵌套目录或非标准 Skill)"
    echo ""
    total=$((total+1))
    continue
  fi

  # 提取 frontmatter description（多行 yaml 也兼容）
  desc=$(awk '
    /^---/{f++; next}
    f==1 && /^description:/{capture=1; sub(/^description: */,""); print; next}
    f==1 && capture && /^[a-zA-Z_]+:/{capture=0}
    f==1 && capture{print}
  ' "$skill_md" | tr '\n' ' ' | sed 's/  */ /g' | cut -c 1-200)

  echo "[$name]"
  echo "  $desc"
  echo ""
  total=$((total+1))
done

echo "=== 共 $total 个 Skill ==="
