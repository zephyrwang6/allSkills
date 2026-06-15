---
name: skill-plugin-architect
description: >
  把散落在 ~/.claude/skills/ 的 Skill 升级到 Plugin/Command/Hooks/Skill 2.0 架构。
  当用户说"整理我的 skill"、"把 skill 改成插件"、"做一套 plugin"、"我的 skill 太多了"、
  "skill 升级 2.0"、"给我的 skill 做 command"、"加 hooks"、"skill 架构升级"时触发。
  能力：
    1. 扫描全局 skill 库并按领域聚类
    2. 为每个领域推荐 Plugin 结构（plugin.json + commands/ + skills/ + hooks/）
    3. 推荐高频 Command 工作流（串多个 Skill）
    4. 推荐 Hooks 自动化任务
    5. 输出可视化方案树，等用户确认
    6. 用户确认后真正执行：创建 plugin 目录、生成 plugin.json、迁移 Skill、生成 Command/Hook 骨架
---

# Skill → Plugin 架构升级师

把你散落的几十上百个 Skill，按 Anthropic Skill 2.0 范式（Plugin / Command / Hooks / Skill）重新组织。
分两阶段：先出方案让你确认，再真正动手。绝不在没确认前移动文件。

## 核心理念

Skill 2.0 的四件套：

| 层 | 角色 | 形态 |
|---|---|---|
| Skill | 原子能力 | 一个文件夹 + SKILL.md |
| Command | 工作流入口 | commands/xxx.md，斜杠触发，串多个 Skill |
| Hooks | 强制自动化 | hooks/xxx.sh，挂在生命周期事件上 |
| Plugin | 发行单位 | 包含上面三者的目录 + plugin.json |

## 路径常量

| 变量 | 路径 |
|---|---|
| GLOBAL | `~/.claude/skills/` |
| PLUGIN_ROOT | `~/.claude/plugins/`（输出位置，新建） |
| BACKUP | `~/.claude/skills-backup-YYYYMMDD/` |

## 默认领域分类规则

按 Skill 名字前缀、关键词和 description 聚类。常见聚类：

| 领域 | Plugin 名 | 典型 Skill 关键词 |
|---|---|---|
| 写作 / 内容生产 | write-pack | writer、article、column、rewrite、blog、wechat、x-post |
| 画图 / 视觉设计 | draw-pack | chart、diagram、image、comic、slide、design、brand、illustration |
| 信息获取 / 输入 | info-pack | rss、feed、digest、url-to-markdown、podcast、youtube、tweet |
| 产品 / 原型 / PM | pm-pack | prd、prototype、design-doc、user-story、roadmap |
| 个人复盘 / 计划 | compass-pack | daily、weekly、retro、review、planner、goal |
| 工具 / 格式转换 | toolkit-pack | format、compress、convert、markdown、html |
| 实验 / 危险品 | lab-pack | danger-*、test、experimental |

未命中分类的 Skill 进 `misc-pack`，由用户手动二次分配。

## 工作流程

### 阶段 A：分析与方案输出（只读，不动文件）

1. **扫描**：跑 `scripts/scan_skills.sh`，输出全局 Skill 清单 + 每个的 description 摘要（限 200 字）。
2. **聚类**：按上面的领域规则给每个 Skill 打标签，统计每个 Plugin 候选下有多少 Skill。
3. **推荐 Command**：对每个 Plugin，识别可串联的 Skill 组合，提出 1-3 条 Command。
   - 命名规则：动词开头的斜杠命令，比如 /new-article、/review-draft、/weekly-retro。
   - 每条 Command 写明：触发场景、依次调用哪几个 Skill、每步的输入输出。
4. **推荐 Hooks**：识别"必须每次都做"的事，提出 2-5 个 Hook。常见模式：
   - `session-start` 自动加载风格指南、人设、上下文
   - `post-write` 自动追加索引（articles_index.jsonl 等）
   - `session-end` 自动追加 daily_log.jsonl
   - `pre-commit` 自动跑格式化或检查
   - `pre-tool-use:Write` 保护关键文件不被覆盖
5. **输出方案树**：用下面这种格式打给用户。

```
~/.claude/plugins/
├── write-pack/                          ← 24 个 Skill
│   ├── plugin.json
│   ├── commands/
│   │   ├── new-article.md               ← 选题→草稿→审稿
│   │   ├── review-draft.md              ← 跑审稿标准
│   │   └── weekly-retro.md              ← 周复盘
│   ├── hooks/
│   │   ├── session-start.sh             ← 自动加载 写作风格.md
│   │   └── post-write.sh                ← 追加 articles_index.jsonl
│   └── skills/
│       ├── article-review/
│       ├── blog-post-writer/
│       └── ...(共 24 个)
├── draw-pack/                           ← 18 个 Skill
│   └── ...
└── misc-pack/                           ← 12 个未分类
    └── ...
```

方案树后追加四个数字：总 Skill 数、Plugin 数、Command 数、Hook 数。

### 阶段 B：等用户确认

明确问用户三件事：

1. 分类是否 OK？要不要把某个 Skill 挪到别的 Plugin？
2. 推荐的 Command 要不要全做？要不要改名/合并/拆分？
3. 推荐的 Hook 要不要全装？

**未拿到用户明确"开始执行"指令前，绝对不动文件。**

### 阶段 C：执行（破坏性操作，每步先备份）

1. **备份**：`cp -R ~/.claude/skills ~/.claude/skills-backup-$(date +%Y%m%d-%H%M%S)`
2. **建 plugins 根目录**：`mkdir -p ~/.claude/plugins/<pack-name>/{commands,hooks,skills}`
3. **生成 plugin.json**：每个 Plugin 写一份，含 name、version (0.1.0)、description、author、domain。
4. **迁移 Skill**：用 `mv`（不是 cp）把 Skill 文件夹搬进对应 Plugin 的 skills/ 下。
   - 用 mv 是为了避免双份。原 `~/.claude/skills/<name>` 留一个软链接指回 plugin 里的位置，保持向后兼容。
5. **生成 Command 骨架**：每条 Command 写一份 markdown，结构如下：

```markdown
---
name: new-article
description: 从选题到初稿一条龙
---

# /new-article

## 执行步骤

1. 调用 Skill: content-topic-generator（输入：用户大致方向）
2. 调用 Skill: ai-writing-assistant（输入：上一步选出的选题）
3. 调用 Skill: article-review（输入：草稿）
4. 输出最终文章并提示用户保存路径
```

6. **生成 Hook 骨架**：每个 Hook 写一份 shell 脚本，加上注释说明触发时机。
7. **写一份 README.md** 在每个 Plugin 根目录，说明这个 Plugin 包含什么、怎么用。
8. **最后打印执行摘要**：搬了多少 Skill、新建多少 Command、装了多少 Hook、备份在哪。

## 关键约束

- **永远先方案后动手**。哪怕用户上来就喊"开整"，也要先输出方案树。
- **永远先备份后迁移**。备份目录用时间戳命名，绝不覆盖。
- **不要重命名 Skill 文件夹**，只是搬位置。Skill 的 name frontmatter 保持不变。
- **不要修改 Skill 内部的 SKILL.md**。这次升级只重组架构，不改内容。
- **遇到 `*_副本`、`*.skill`、`* v1` 这种重复 Skill，先列出来让用户决定保留哪个**，不要自动去重。
- 软链接回原位置时用绝对路径，避免移动后断链。

## 触发示例

用户说：
- "把我 ~/.claude/skills 整理成 plugin 架构" → 直接进入阶段 A
- "我 skill 太乱了帮我重新组织一下" → 阶段 A
- "按 pm-skills 那种 plugin 结构改造我的 skill" → 阶段 A
- "执行刚才的方案" / "开干" / "确认" → 进入阶段 C
- "改一下，把 brand-design-md 挪到 draw-pack" → 修改方案，重新输出方案树

## 输出风格

- 阶段 A 的方案用纯文本树状图 + 数字汇总，不用花里胡哨的 emoji。
- 阶段 C 执行时每完成一步打印一行进度。
- 全程第一人称，不用「您」。
