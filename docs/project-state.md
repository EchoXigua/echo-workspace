# LeanMate Project State

Last updated: 2026-06-07

## Current Focus

LeanMate V1.1 后端基础设施已经初始化，Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本和后端基础设施已完成，Flyway V1-V6 已通过本地 Docker PostgreSQL 空库迁移验证。认证、当前用户、用户档案、体重记录、首页今日状态、手动饮食记录、饮食 AI 识别任务、AI 日报接口和连续打卡接口已实现并通过离线测试，当前 `mvn -o -Dmaven.repo.local=.m2/repository test` 为 37 tests 全绿。饮食 AI 识别和 AI 日报当前使用后端占位 AI Provider Adapter，不接真实模型供应商；饮食图片不落地真实对象存储。

iOS 基础设施阶段已完成，V1.1 业务第 1、2、3、4、5 批已完成。第 1 批完成 Onboarding / 登录占位、ProfileSetup、Mock 登录、档案保存和保存后路由，提交为 `dd3f3f1 feat(ios): 实现 V1.1 首批登录档案流程`。第 2 批完成 Home 首页今日状态、游客态、档案未完成、empty、loaded、error 状态和 HomeViewModel 测试，提交为 `65261ac feat(ios): 实现 V1.1 首页业务流程`。第 3 批完成 Diet / Weight 状态矩阵、记录入口、文本饮食识别确认、手动饮食保存、体重记录 Sheet、record tab 接入和 ViewModel 测试编译验证，提交为 `3bc6216 feat(ios): 实现 V1.1 饮食和体重记录入口`。第 4 批完成拍照识别确认、删除确认、AI 日报页面、DailyReportViewModel、Report tab 接入和 ViewModel 测试编译验证。第 5 批完成 Profile Summary / 我的页、连续打卡展示、里程碑弹窗、ProfileSummaryViewModel 和 ViewModel 测试编译验证。

2026-06-07 已追加 iOS 设计还原与模拟器验收收口批次：重新对照 `design/app/LeanMateV1.0-shikaka.pen`，统一主 Tab 页面壳，调整 ProfileSetup 为三步单问题风格，修正 Home 游客态卡片，补齐 Diet 游客入口预览、拍照识别全屏确认和自定义删除弹窗，收敛 AI 日报关键发现卡片，并修复 Mock 档案保存后仍停留 `profileIncomplete` 的流程问题。当前主线程只做批次调度和状态落盘，后续建议优先按用户在模拟器看到的具体截图做逐屏视觉回归，或进入真实后端联调前检查。

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
- 编码阶段采用主线程调度、子线程分批开发、关键进度落盘和每批 commit 恢复点的工作方式；流程见 `.codex/skills/leanmate-batch-coding-workflow/`。

## Completed Artifacts

- `docs/README.md`
- `.gitignore`
- `docs/product/v1.1-acceptance-criteria.md`
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
- `server/src/main/java/com/leanmate/common/config/LimitProperties.java`
- `server/src/main/java/com/leanmate/common/security/`
- `server/src/main/java/com/leanmate/ai/AiProviderProperties.java`
- `server/src/main/java/com/leanmate/ai/client/`
- `server/src/main/java/com/leanmate/ai/dto/`
- `server/src/main/java/com/leanmate/user/controller/AuthController.java`
- `server/src/main/java/com/leanmate/user/controller/MeController.java`
- `server/src/main/java/com/leanmate/user/controller/ProfileController.java`
- `server/src/main/java/com/leanmate/user/application/`
- `server/src/main/java/com/leanmate/user/domain/`
- `server/src/main/java/com/leanmate/user/dto/`
- `server/src/main/java/com/leanmate/user/repository/`
- `server/src/main/java/com/leanmate/weight/controller/WeightController.java`
- `server/src/main/java/com/leanmate/weight/application/`
- `server/src/main/java/com/leanmate/weight/dto/`
- `server/src/main/java/com/leanmate/weight/repository/`
- `server/src/main/java/com/leanmate/stats/controller/HomeController.java`
- `server/src/main/java/com/leanmate/stats/application/`
- `server/src/main/java/com/leanmate/stats/dto/`
- `server/src/main/java/com/leanmate/stats/repository/`
- `server/src/main/java/com/leanmate/diet/controller/DietEntryController.java`
- `server/src/main/java/com/leanmate/diet/controller/DietRecognitionController.java`
- `server/src/main/java/com/leanmate/diet/application/`
- `server/src/main/java/com/leanmate/diet/domain/`
- `server/src/main/java/com/leanmate/diet/dto/`
- `server/src/main/java/com/leanmate/diet/repository/`
- `server/src/main/java/com/leanmate/report/controller/DailyReportController.java`
- `server/src/main/java/com/leanmate/report/application/`
- `server/src/main/java/com/leanmate/report/domain/`
- `server/src/main/java/com/leanmate/report/dto/`
- `server/src/main/java/com/leanmate/report/repository/`
- `server/src/main/java/com/leanmate/retention/controller/RetentionController.java`
- `server/src/main/java/com/leanmate/retention/application/`
- `server/src/main/java/com/leanmate/retention/dto/`
- `server/src/main/java/com/leanmate/retention/repository/`
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
- `server/src/test/java/com/leanmate/weight/application/WeightApplicationServiceTests.java`
- `server/src/test/java/com/leanmate/stats/application/HomeApplicationServiceTests.java`
- `server/src/test/java/com/leanmate/diet/application/DietEntryApplicationServiceTests.java`
- `server/src/test/java/com/leanmate/diet/application/DietRecognitionApplicationServiceTests.java`
- `server/src/test/java/com/leanmate/report/application/DailyReportApplicationServiceTests.java`
- `server/src/test/java/com/leanmate/retention/application/RetentionApplicationServiceTests.java`
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
- `ios/docs/design-screen-map.md`
- `ios/docs/v1.1-state-matrix.md`
- `ios/.swiftlint.yml`
- `ios/LeanMate.xcodeproj`
- `ios/LeanMateTests/`
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
- `ios/LeanMate/Features/Onboarding/OnboardingView.swift`
- `ios/LeanMate/Features/Onboarding/OnboardingViewModel.swift`
- `ios/LeanMate/Features/Profile/ProfileSetupView.swift`
- `ios/LeanMate/Features/Profile/ProfileSetupViewModel.swift`
- `ios/LeanMate/Features/Profile/ProfileSummaryView.swift`
- `ios/LeanMate/Features/Profile/ProfileSummaryViewModel.swift`
- `ios/LeanMate/Features/Home/HomeView.swift`
- `ios/LeanMate/Features/Home/HomeViewModel.swift`
- `ios/LeanMate/Features/Home/HomeEmptyView.swift`
- `ios/LeanMate/Features/Home/VisitorHomeBanner.swift`
- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Features/Diet/DietEntryViewModel.swift`
- `ios/LeanMate/Features/Report/DailyReportView.swift`
- `ios/LeanMate/Features/Report/DailyReportViewModel.swift`
- `ios/LeanMate/Features/Weight/WeightEntrySheet.swift`
- `ios/LeanMate/Features/Weight/WeightViewModel.swift`
- `ios/LeanMate/PreviewSupport/`
- `ios/LeanMateTests/FirstBatchViewModelTests.swift`
- `ios/LeanMateTests/HomeViewModelTests.swift`
- `ios/LeanMateTests/DietEntryViewModelTests.swift`
- `ios/LeanMateTests/DailyReportViewModelTests.swift`
- `ios/LeanMateTests/ProfileSummaryViewModelTests.swift`
- `ios/LeanMateTests/WeightViewModelTests.swift`
- `.codex/skills/leanmate-prd-workflow/`
- `.codex/skills/leanmate-git-commit/`
- `.codex/skills/leanmate-batch-coding-workflow/`

## Known Gaps

- 后端通用响应、错误码、异常处理、参数校验错误响应、CORS、JWT 鉴权、当前用户上下文、认证接口、当前用户接口、用户档案接口、体重记录接口、首页今日状态接口、手动饮食记录接口、饮食 AI 识别任务接口、AI 日报接口和连续打卡接口已实现。
- `GET /v1/retention/streak` 已按 confirmed 饮食记录或体重记录的业务日期计算 `currentDays`、`longestDays`、`lastActiveDate` 和 3/7/30/100 天里程碑；iOS 首页和我的页只展示后端返回的 streak 或 Mock 数据，不在客户端自行计算连续打卡。
- 饮食 AI 识别已完成任务接口、状态流、占位 AI Provider Adapter、结构化候选项保存和任务归属校验；真实 AI Provider、真实图片对象存储和模型名仍待确认。
- AI 日报已完成生成、查询、查看状态接口和占位 AI Provider Adapter；真实 AI Provider、模型名和日报生成质量仍待确认。
- CI 尚未加入 Flyway 集成验证；当前 `mvn test` 不会启动 PostgreSQL 或执行迁移。
- AI Provider 具体供应商和模型尚未确认。
- Apple 登录真实 verifier 已实现；真实 client id、Team ID、Key ID、私钥等生产配置尚未确认。
- 对象存储真实配置尚未确认。
- 图片保存期限和隐私策略尚未确认。
- iOS Onboarding、ProfileSetup、Home、Diet 文本/手动记录入口、Diet 拍照识别确认、Diet 删除确认、Weight 记录 Sheet、AI 日报入口、Profile Summary / 我的页、连续打卡展示和里程碑弹窗已完成。2026-06-07 已完成一轮基于 Pencil 准稿和 iPhone 17 模拟器主路径的视觉/流程修正，但仍需要用户按真实运行发现的具体屏幕截图继续逐屏收口。AI 日报页和连续打卡需要接已完成的后端接口做真实联调。
- iOS Bundle ID、Apple Developer Team、真实登录能力尚未确认。
- iOS 当前本地持久化使用 `FileLocalStore`；如业务阶段确需 SwiftData，可替换 `LocalStore` 实现。
- 第 1、2、3、4、5 批和 2026-06-07 设计还原收口批次均已通过 generic simulator `xcodebuild build` 和 `build-for-testing`。本轮已用 XcodeBuildMCP 在 iPhone 17 模拟器跑通 Onboarding、ProfileSetup 保存、Home、Diet、Report、Profile 主路径；进入联调前仍建议在本机补跑真实 `xcodebuild test`。

## Recommended Next Steps

1. iOS 视觉问题收口：用户在模拟器发现问题时，按具体屏幕截图和路径逐屏修正，不新增 PRD/OpenAPI/状态矩阵之外功能。
2. 后端联调前补充检查：确认 AI 日报、首页和连续打卡在真实 PostgreSQL 空库迁移后的读写流程。
3. iOS 联调收口批次：接真实后端返回做端到端验收、补跑具名模拟器 `xcodebuild test`。
4. 确认 AI Provider、模型名、Apple 登录、对象存储和 iOS Bundle ID 后更新相关文档，并进入真实后端联调。

## Resume Prompt

后端编码提示：

```text
请读取 AGENTS.md、server/AGENTS.md、docs/project-state.md、server/docs/development-readiness.md 和 docs/api/openapi.yaml，继续 LeanMate V1.1 后端联调前检查。后端 Spring Boot 3.x + Java 17 + Maven 工程骨架、Flyway 迁移脚本、基础设施、认证接口、当前用户接口、用户档案接口、体重记录接口、首页今日状态接口、手动饮食记录接口、饮食 AI 识别任务接口、AI 日报接口和 `GET /v1/retention/streak` 连续打卡接口已完成并通过离线测试。下一步只检查真实 PostgreSQL 空库迁移后的首页、AI 日报和连续打卡读写流程，不要接真实 AI Provider、对象存储、Apple 生产配置或超出 V1.1 文档范围的功能。
```

iOS 编码提示：

```text
请读取 AGENTS.md、ios/AGENTS.md、.codex/skills/leanmate-batch-coding-workflow/SKILL.md、docs/project-state.md、ios/docs/development-readiness.md、ios/docs/infrastructure-status.md、ios/docs/design-screen-map.md、ios/docs/v1.1-state-matrix.md、docs/product/v1.1-acceptance-criteria.md、docs/api/openapi.yaml 和 docs/product/prd-v1.1.md，继续 LeanMate V1.1 iOS 视觉问题收口或联调收口。当前 iOS 第 1-5 批业务页面已完成：Onboarding/ProfileSetup/Home/Diet/Weight/Report/Profile Summary/Retention 展示；2026-06-07 已追加一轮基于 design/app/LeanMateV1.0-shikaka.pen 和 iPhone 17 模拟器主路径的设计还原修正。请先检查 `git status --short`，如处理视觉问题，必须按用户提供的具体截图/路径逐屏修正；如处理联调，只做真实后端联调、状态回归、构建测试和必要的小范围修复。必须复用现有 APIClient、MockAPIClient、AppRouter、设计系统和 Components，只以 design/app/LeanMateV1.0-shikaka.pen 为设计准稿。不要实现真实 Apple 登录，不要在客户端自行计算 streak，不要实现超出 V1.1 PRD、OpenAPI、验收标准和状态矩阵的功能。完成后运行 xcodebuild build、build-for-testing，并在具名模拟器可用时补跑 xcodebuild test；不要自动提交，除非用户明确要求。
```
