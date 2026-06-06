# LeanMate Workspace

LeanMate（瘦搭）多端产品工作区，包含 iOS、Android、后端、未来 Web、设计稿和跨端文档。

## 项目结构

```text
echo-workspace/
├── ios/        # iOS 客户端
├── android/    # Android 客户端
├── server/     # 后端 API
├── web/        # 未来 Web 端
├── docs/       # 跨端文档：PRD、架构、OpenAPI、数据字典
└── design/     # 产品设计稿
```

## 核心文档

- 项目当前状态：[docs/project-state.md](docs/project-state.md)
- 文档中心：[docs/README.md](docs/README.md)
- V1.1 PRD：[docs/product/prd-v1.1.md](docs/product/prd-v1.1.md)
- 产品规划：[docs/product/roadmap.md](docs/product/roadmap.md)
- 总体架构：[docs/architecture/overview.md](docs/architecture/overview.md)
- 后端架构：[docs/architecture/backend.md](docs/architecture/backend.md)
- 后端技术选型：[server/docs/technology-selection.md](server/docs/technology-selection.md)
- 后端数据库设计：[server/docs/database-design.md](server/docs/database-design.md)
- AI Provider 方案：[server/docs/ai-provider.md](server/docs/ai-provider.md)
- 后端环境配置：[server/docs/env-config.md](server/docs/env-config.md)
- 后端开发就绪说明：[server/docs/development-readiness.md](server/docs/development-readiness.md)
- V1.1 后端技术方案：[server/docs/technical-design/v1.1/README.md](server/docs/technical-design/v1.1/README.md)
- V1.1 API 设计说明：[server/docs/technical-design/v1.1/api-design.md](server/docs/technical-design/v1.1/api-design.md)
- API 契约：[docs/api/openapi.yaml](docs/api/openapi.yaml)
- 埋点事件：[docs/data/events.md](docs/data/events.md)
- 指标口径：[docs/data/metrics.md](docs/data/metrics.md)
- iOS 开发就绪说明：[ios/docs/development-readiness.md](ios/docs/development-readiness.md)
- iOS 架构设计：[ios/docs/architecture.md](ios/docs/architecture.md)
- iOS 编码规范：[ios/docs/coding-style.md](ios/docs/coding-style.md)
- iOS API 与 Mock 策略：[ios/docs/api-mock-strategy.md](ios/docs/api-mock-strategy.md)

## AI 规范

本项目以 `AGENTS.md` 作为所有 AI 工具的主规范入口：

- `AGENTS.md`：全局规范，Claude、Codex、Cursor 都应遵守。
- `CLAUDE.md`：Claude 兼容入口，只导入 `AGENTS.md`。
- `.cursor/rules/project.mdc`：Cursor 入口，指向 `AGENTS.md` 和关键文档。
- 各端 `AGENTS.md`：端内专属规范。

各端规范：

- [server/AGENTS.md](server/AGENTS.md)
- [ios/AGENTS.md](ios/AGENTS.md)
- [android/AGENTS.md](android/AGENTS.md)
- [web/AGENTS.md](web/AGENTS.md)

## 当前后端决策

V1.1 从一开始接入后端。后端采用 Spring Boot 模块化单体，核心数据存 PostgreSQL。

当前明确暂不引入：

- Redis
- MQ
- Kafka
- 微服务

相关说明见：

- [ADR 0002：V1.1 开始接入后端](docs/architecture/decisions/0002-backend-from-v1.md)
- [ADR 0003：V1.1 暂不引入 Redis 和 MQ](docs/architecture/decisions/0003-defer-redis-and-mq.md)

## 启动方式

各端工程初始化后补充。
