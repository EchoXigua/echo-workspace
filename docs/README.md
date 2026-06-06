# LeanMate 文档中心

本目录存放跨端共享文档。Web、后端、iOS、Android 都应以这里的产品、架构、接口文档作为共同输入。

## 文档结构

```text
docs/
├── product/        # 产品需求、版本规划
├── architecture/   # 架构设计、领域模型、ADR
├── api/            # OpenAPI 接口契约
└── data/           # 数据字典与指标口径
```

## 当前核心文档

- [项目当前状态](project-state.md)
- [V1.1 PRD](product/prd-v1.1.md)
- [V1.1 验收标准与业务边界](product/v1.1-acceptance-criteria.md)
- [产品规划](product/roadmap.md)
- [总体架构设计](architecture/overview.md)
- [后端架构设计](architecture/backend.md)
- [领域模型设计](architecture/domain-model.md)
- [OpenAPI 契约](api/openapi.yaml)
- [后端技术选型](../server/docs/technology-selection.md)
- [后端数据库设计](../server/docs/database-design.md)
- [AI Provider 方案](../server/docs/ai-provider.md)
- [后端环境配置](../server/docs/env-config.md)
- [后端开发就绪说明](../server/docs/development-readiness.md)
- [后端技术方案规范](../server/docs/technical-design/README.md)
- [后端技术方案检查清单](../server/docs/technical-design/checklist.md)
- [V1.1 后端技术方案索引](../server/docs/technical-design/v1.1/README.md)
- [V1.1 API 设计说明](../server/docs/technical-design/v1.1/api-design.md)
- [埋点事件](data/events.md)
- [指标口径](data/metrics.md)
- [iOS 开发就绪说明](../ios/docs/development-readiness.md)
- [iOS 架构设计](../ios/docs/architecture.md)
- [iOS 编码规范](../ios/docs/coding-style.md)
- [iOS API 与 Mock 策略](../ios/docs/api-mock-strategy.md)
- [V1.1 iOS 状态矩阵](../ios/docs/v1.1-state-matrix.md)

## 维护原则

- 产品需求变化先更新 `product/`，再同步影响到架构与接口。
- 接口变更以 `api/openapi.yaml` 为准，客户端和服务端都从这里对齐。
- 重要技术取舍写入 `architecture/decisions/`，避免后续反复争论同一个问题。
