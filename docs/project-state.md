# LeanMate Project State

Last updated: 2026-06-06

## Current Focus

LeanMate V1.1 后端基础设施已经初始化，Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本和后端基础设施已完成，Flyway V1-V6 已通过本地 Docker PostgreSQL 空库迁移验证。认证、当前用户和用户档案第一批业务接口已实现并通过离线测试。

iOS 基础设施阶段已完成：SwiftUI 工程、MVVM + feature-first 目录、API DTO、Live/Mock API Client、Token 存储、本地草稿存储边界、设计系统和可复用组件已初始化并通过本地 xcodebuild 构建。iOS 业务开发尚未开始，等待用户确认后再启动。

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
- iOS V1.1 UI 以 `design/app/LeanMateV1.0-shikaka.pen` 为唯一准稿；`design/app/LeanMateV1.0.pen` 忽略。
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
- `server/src/main/java/com/leanmate/user/controller/AuthController.java`
- `server/src/main/java/com/leanmate/user/controller/MeController.java`
- `server/src/main/java/com/leanmate/user/controller/ProfileController.java`
- `server/src/main/java/com/leanmate/user/application/`
- `server/src/main/java/com/leanmate/user/domain/`
- `server/src/main/java/com/leanmate/user/dto/`
- `server/src/main/java/com/leanmate/user/repository/`
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
- `server/src/test/java/com/leanmate/user/application/OAuthIdentityVerifierTests.java`
- `server/src/test/java/com/leanmate/user/domain/ProfileCalculatorTests.java`
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
- `ios/docs/infrastructure-status.md`
- `ios/.swiftlint.yml`
- `ios/LeanMate.xcodeproj`
- `ios/LeanMate/App/`
- `ios/LeanMate/Core/API/`
- `ios/LeanMate/Core/Auth/`
- `ios/LeanMate/Core/DesignSystem/`
- `ios/LeanMate/Core/Mock/`
- `ios/LeanMate/Core/Persistence/`
- `ios/LeanMate/Core/Security/`
- `ios/LeanMate/Core/Utilities/`
- `ios/LeanMate/Components/`
- `ios/LeanMate/Features/`
- `ios/LeanMate/PreviewSupport/`
- `.codex/skills/leanmate-prd-workflow/`
- `.codex/skills/leanmate-git-commit/`

## Known Gaps

- 后端通用响应、错误码、异常处理、参数校验错误响应、CORS、JWT 鉴权、当前用户上下文、认证接口、当前用户接口和用户档案接口已实现。
- 体重、首页、饮食、AI 日报和连续打卡业务 API 尚未实现。
- CI 尚未加入 Flyway 集成验证；当前 `mvn test` 不会启动 PostgreSQL 或执行迁移。
- AI Provider 具体供应商和模型尚未确认。
- Apple 登录真实 verifier 已实现；真实 client id、Team ID、Key ID、私钥等生产配置尚未确认。
- 对象存储真实配置尚未确认。
- 图片保存期限和隐私策略尚未确认。
- iOS 业务页面和业务 ViewModel 尚未开始实现。
- iOS Bundle ID、Apple Developer Team、真实登录能力尚未确认。
- iOS 当前本地持久化使用 `FileLocalStore`；如业务阶段确需 SwiftData，可替换 `LocalStore` 实现。

## Recommended Next Steps

1. 后端新对话：读取 `server/docs/development-readiness.md`、`docs/api/openapi.yaml` 和 `server/docs/technical-design/v1.1/01-account-profile-goal.md`，从体重记录和首页空状态接口继续实现业务 API。
2. iOS 业务开发需等待用户确认；确认后读取 `ios/docs/infrastructure-status.md`，从 Onboarding / 登录占位和用户档案填写开始。
3. 后端下一步优先实现 `POST /v1/weights`、`GET /v1/weights`、`GET /v1/home/today`。
4. iOS 业务开发必须复用现有 `APIClient`、`MockAPIClient`、设计系统和 `Components/`，不要在页面中重复实现基础样式。
5. 确认 AI Provider、模型名、Apple 登录、对象存储和 iOS Bundle ID 后更新相关文档。

## Resume Prompt

后端编码提示：

```text
请读取 AGENTS.md、server/AGENTS.md、docs/project-state.md、server/docs/development-readiness.md 和 docs/api/openapi.yaml，继续 LeanMate V1.1 后端编码阶段。后端 Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本、基础设施、认证接口、当前用户接口和用户档案接口已完成并通过离线测试，下一步从体重记录和首页空状态接口继续实现业务 API，不要实现超出 V1.1 文档范围的功能。
```

iOS 编码提示：

```text
请读取 AGENTS.md、ios/AGENTS.md、docs/project-state.md、ios/docs/development-readiness.md 和 ios/docs/infrastructure-status.md，继续 LeanMate V1.1 iOS。iOS 基础设施已完成并通过 xcodebuild 构建验证；业务开发尚未开始。除非我明确确认进入业务开发阶段，否则不要实现业务页面。进入业务开发后，必须复用现有 APIClient、MockAPIClient、设计系统和 Components，并且只以 design/app/LeanMateV1.0-shikaka.pen 为设计准稿，不要实现超出 V1.1 PRD 和 OpenAPI 的功能。
```
