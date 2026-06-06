---
name: leanmate-prd-workflow
description: 当用户提供 LeanMate/瘦搭 PRD、产品规划、版本计划、功能需求，或要求继续/恢复 LeanMate 项目规划工作时使用。这个 skill 会把产品文档转成项目文档、架构更新、后端技术方案、OpenAPI 变更和可恢复的项目状态，避免依赖长对话历史。
---

# LeanMate PRD 工作流

## 概述

使用这个工作流处理 LeanMate V1.1、V1.2、V1.3 等版本的产品变化。仓库内文档是长期记忆，当前对话只作为临时沟通上下文。

## 开始前先读

1. 读取项目规则：
   - `AGENTS.md`
   - 如果任务涉及具体端，再读 `server/`、`ios/`、`android/`、`web/` 下对应的 `AGENTS.md`
2. 读取当前项目状态：
   - `docs/project-state.md`
3. 需要确认文档应该写到哪里时，读取：
   - `references/document-map.md`
4. 处理新版本 PRD 或版本规划时，读取：
   - `references/version-workflow.md`

## 输出语言

- 面向人看的项目文档默认使用中文。
- PRD、架构说明、后端技术方案、ADR、项目状态、指标说明、README 都使用中文。
- 代码标识符、API 字段名、目录名、文件名按工程惯例使用英文。
- OpenAPI 的路径、schema、字段名使用英文；`summary`、`description` 可以使用中文。

## 工作原则

- 重要结论必须沉淀到仓库文档，不只留在聊天里。
- 优先更新现有文档，避免创建重复文档。
- 产品需求放在 `docs/product/`。
- 跨端架构、领域模型、接口契约放在 `docs/`。
- 后端实现方案放在 `server/docs/`。
- `docs/api/openapi.yaml` 是唯一接口契约。
- Markdown 接口说明只能作为人类友好版；如果和 OpenAPI 冲突，以 OpenAPI 为准。

## 标准流程

当用户提供新的 PRD、版本规划或功能需求时：

1. 将源文档保存到 `docs/product/`，使用稳定的版本化文件名。
2. 对比现有 PRD、roadmap、架构文档和 `docs/project-state.md`。
3. 提炼产品变化：新增范围、保持不变的范围、明确不做的范围、待确认问题。
4. 如果新版本影响领域边界、数据归属、AI 流程、后端职责或客户端职责，更新架构文档。
5. 对重要技术取舍，在 `docs/architecture/decisions/` 新增或更新 ADR。
6. 在 `server/docs/technical-design/<version>/` 新增或更新后端技术方案。
7. 后端技术方案明确后，更新 `docs/api/openapi.yaml`。
8. 如果涉及留存、指标、埋点、AI 质量评估，更新 `docs/data/` 下相关文档。
9. 更新 `docs/project-state.md`，写清当前状态、已完成内容、关键决策、遗留问题和下一步。

## 恢复流程

当用户在新对话里要求继续：

1. 读取 `docs/project-state.md`。
2. 读取 `docs/README.md`、`server/README.md`，以及当前版本对应的 `server/docs/technical-design/` 目录。
3. 运行或查看 `git status --short`，了解当前工作区状态。
4. 从 `docs/project-state.md` 的“Recommended Next Steps / 推荐下一步”继续。
5. 如果聊天历史和仓库文档冲突，以仓库文档为准，除非用户明确改变方向。

## 版本处理清单

处理每个版本时，按需检查这些产物：

- `docs/product/<version>.md`
- `docs/product/roadmap.md`
- `docs/architecture/overview.md`
- `docs/architecture/domain-model.md`
- `docs/architecture/backend.md`
- `docs/architecture/decisions/<adr>.md`
- `server/docs/technology-selection.md`
- `server/docs/technical-design/<version>/`
- `docs/api/openapi.yaml`
- `docs/data/events.md`
- `docs/data/metrics.md`
- `docs/project-state.md`

不要机械创建所有文件。只创建或更新当前版本实际影响的文件，但每次重要工作结束都要更新 `docs/project-state.md`。

## 交付说明

每次结束时，简要告诉用户：

- 新增或修改了哪些文档；
- 记录了哪些决策；
- 下一步还剩什么；
- OpenAPI 是否已经达到后端和客户端并行开发的状态。
