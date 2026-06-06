# LeanMate Project State

Last updated: 2026-06-06

## Current Focus

LeanMate V1.1 已进入后端编码阶段，Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本和后端基础设施已经初始化。iOS 仍可另起对话进入编码阶段。

## Product Inputs

- V1.1 PRD: `docs/product/prd-v1.1.md`
- Product roadmap: `docs/product/roadmap.md`

## Accepted Decisions

- V1.1 starts with a backend. iCloud/CloudKit is not the primary backend.
- Backend uses Spring Boot modular monolith first.
- PostgreSQL is the primary database.
- V1.1 does not introduce Redis or MQ.
- App clients do not call AI providers directly; AI calls go through the backend.
- `AGENTS.md` is the main AI collaboration rule file; `CLAUDE.md` and Cursor rules point to it.
- `docs/api/openapi.yaml` is the canonical API contract.
- 人看的项目文档默认使用中文；代码标识符、API 字段名和文件路径按工程惯例使用英文。

## Completed Artifacts

- `docs/README.md`
- `.gitignore`
- `docs/architecture/overview.md`
- `docs/architecture/backend.md`
- `docs/architecture/domain-model.md`
- `docs/architecture/decisions/0001-modular-monolith.md`
- `docs/architecture/decisions/0002-backend-from-v1.md`
- `docs/architecture/decisions/0003-defer-redis-and-mq.md`
- `docs/api/openapi.yaml`
- `docs/data/events.md`
- `docs/data/metrics.md`
- `server/docs/technology-selection.md`
- `server/docs/database-design.md`
- `server/docs/ai-provider.md`
- `server/docs/env-config.md`
- `server/docs/development-readiness.md`
- `server/.env.local.example`
- `server/.env.dev.example`
- `server/.env.prod.example`
- `server/pom.xml`
- `server/src/main/java/com/leanmate/LeanMateApplication.java`
- `server/src/main/java/com/leanmate/common/response/ApiResponse.java`
- `server/src/main/java/com/leanmate/common/error/ErrorCode.java`
- `server/src/main/java/com/leanmate/common/exception/BusinessException.java`
- `server/src/main/java/com/leanmate/common/exception/GlobalExceptionHandler.java`
- `server/src/main/java/com/leanmate/common/security/`
- `server/src/main/resources/application.yml`
- `server/src/main/resources/db/migration/V1__enable_extensions.sql`
- `server/src/main/resources/db/migration/V2__create_user_tables.sql`
- `server/src/main/resources/db/migration/V3__create_profile_goal_tables.sql`
- `server/src/main/resources/db/migration/V4__create_diet_tables.sql`
- `server/src/main/resources/db/migration/V5__create_weight_stats_tables.sql`
- `server/src/main/resources/db/migration/V6__create_report_retention_tables.sql`
- `server/src/test/java/com/leanmate/LeanMateApplicationTests.java`
- `server/src/test/java/com/leanmate/common/security/JwtTokenServiceTests.java`
- `server/src/test/java/com/leanmate/common/web/SecurityInfrastructureTests.java`
- `server/docker-compose.yml`
- `server/docs/technical-design/README.md`
- `server/docs/technical-design/checklist.md`
- `server/docs/technical-design/template.md`
- `server/docs/technical-design/v1.1/`
- `server/docs/technical-design/v1.1/api-design.md`
- `ios/README.md`
- `ios/docs/development-readiness.md`
- `ios/docs/architecture.md`
- `ios/docs/coding-style.md`
- `ios/docs/api-mock-strategy.md`
- `ios/.swiftlint.yml`
- `.codex/skills/leanmate-prd-workflow/`
- `.codex/skills/leanmate-git-commit/`

## Known Gaps

- Flyway 迁移脚本已初步落成，Java/Maven 测试已通过；本地 PostgreSQL Docker 实跑验证待补。
- 后端通用响应、错误码、异常处理、参数校验错误响应、CORS、JWT 鉴权和当前用户上下文已实现；业务 API 尚未实现。
- AI Provider 具体供应商和模型尚未确认。
- Apple 登录真实配置尚未确认。
- 对象存储真实配置尚未确认。
- 图片保存期限和隐私策略尚未确认。
- iOS 工程还未初始化。
- iOS Bundle ID、Apple Developer Team、真实登录能力尚未确认。

## Recommended Next Steps

1. 后端新对话：读取 `server/docs/development-readiness.md` 和 `docs/api/openapi.yaml`，从认证和用户档案接口开始实现业务 API。
2. iOS 新对话：读取 `ios/docs/development-readiness.md`，初始化 iOS 17 + SwiftUI 工程。
3. 后端优先实现 `POST /v1/auth/oauth-login`、`POST /v1/auth/refresh`、`POST /v1/auth/logout`、`GET /v1/me`、`GET /v1/profile`、`PUT /v1/profile`。
4. iOS 按 `docs/api/openapi.yaml` 先实现 DTO、Mock API Client 和首批页面。
5. 确认 AI Provider、模型名、Apple 登录、对象存储和 iOS Bundle ID 后更新相关文档。

## Resume Prompt

后端编码提示：

```text
请读取 AGENTS.md、server/AGENTS.md、docs/project-state.md 和 server/docs/development-readiness.md，继续 LeanMate V1.1 后端编码阶段。后端 Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本和基础设施已初始化，下一步从认证和用户档案接口开始实现业务 API，不要实现超出 V1.1 文档范围的功能。
```

iOS 编码提示：

```text
请读取 AGENTS.md、ios/AGENTS.md、docs/project-state.md 和 ios/docs/development-readiness.md，开始 LeanMate V1.1 iOS 编码阶段。最低兼容 iOS 17，先初始化 SwiftUI 工程、搭建 MVVM + feature-first 目录、网络层和 Mock API Client，不要实现超出 V1.1 PRD 和 OpenAPI 的功能。
```
