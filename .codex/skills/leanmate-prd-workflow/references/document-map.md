# LeanMate 文档地图

处理 PRD 或版本规划时，用这份文档判断产物应该写到哪里。

## 长期上下文

- `docs/project-state.md`：当前项目状态、关键决策、遗留问题、下一步和恢复说明。
- `AGENTS.md`：全局 AI 协作规范。
- `.cursor/rules/project.mdc`：Cursor 入口。
- `CLAUDE.md`：Claude 兼容入口。

## 产品文档

- `docs/product/prd-v1.1.md`：当前 V1.1 PRD。
- `docs/product/roadmap.md`：长期产品规划。
- 后续 PRD 使用稳定文件名，例如 `docs/product/prd-v1.2.md`。

## 架构文档

- `docs/architecture/overview.md`：总体架构。
- `docs/architecture/backend.md`：后端定位、模块、跨端职责。
- `docs/architecture/domain-model.md`：领域实体和关系。
- `docs/architecture/decisions/`：ADR，用于记录长期技术决策。

## 接口文档

- `docs/api/openapi.yaml`：唯一接口契约。
- 如果后续增加人类友好的 Markdown 接口说明，也放在 `docs/api/`，但 OpenAPI 仍是唯一标准。

## 后端文档

- `server/docs/technology-selection.md`：后端技术选型。
- `server/docs/database-design.md`：数据库表结构、索引、约束和建表示例。
- `server/docs/ai-provider.md`：AI Provider、prompt、失败降级和成本控制方案。
- `server/docs/env-config.md`：后端环境变量和 local/dev/prod 配置。
- `server/.env.example`：环境变量示例，不包含真实密钥。
- `server/docs/development-readiness.md`：进入后端编码阶段的就绪说明和开发顺序。
- `server/docs/technical-design/README.md`：后端技术方案设计规范。
- `server/docs/technical-design/checklist.md`：后端技术方案进入编码前的检查清单。
- `server/docs/technical-design/template.md`：单需求技术方案模板。
- `server/docs/technical-design/v1.1/`：V1.1 后端技术方案。
- `server/docs/technical-design/v1.1/api-design.md`：V1.1 人类可读 API 设计说明。
- 后续版本使用类似 `server/docs/technical-design/v1.2/` 的目录。

## iOS 文档

- `ios/README.md`：iOS 文档入口。
- `ios/docs/development-readiness.md`：iOS 编码阶段就绪说明。
- `ios/docs/architecture.md`：iOS 架构设计。
- `ios/docs/coding-style.md`：iOS 编码规范。
- `ios/docs/api-mock-strategy.md`：iOS API 与 Mock 并行开发策略。
- `ios/.swiftlint.yml`：SwiftLint 基础规则。

## 数据与指标

- `docs/data/events.md`：埋点事件定义。
- `docs/data/metrics.md`：指标口径和计算规则。

当用户要求定义留存、埋点、数据分析、AI 质量评估或版本成功标准时，创建或更新这些文件。
