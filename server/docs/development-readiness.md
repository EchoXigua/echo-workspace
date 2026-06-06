# LeanMate V1.1 后端开发就绪说明

## 结论

V1.1 后端已经具备进入编码阶段的文档基础。下一次新对话可以开始初始化 Spring Boot 工程。

可以开始的范围：

- 后端工程脚手架。
- PostgreSQL + Flyway。
- 通用响应、错误码、异常处理。
- JWT 鉴权基础设施。
- 用户、档案、目标、体重、饮食、首页统计、日报、连续打卡模块。
- AI Provider Adapter 的接口和占位实现。

需要在编码中或编码前确认的范围：

- 具体 AI Provider 和模型名称。
- Apple 登录真实配置。
- 对象存储真实配置。
- 图片保存期限和隐私策略。

## 编码入口

新对话进入编码阶段时，先读：

1. `AGENTS.md`
2. `server/AGENTS.md`
3. `docs/project-state.md`
4. `server/docs/development-readiness.md`
5. `server/docs/technology-selection.md`
6. `server/docs/database-design.md`
7. `docs/api/openapi.yaml`

## 建议开发顺序

### 第 1 步：初始化工程

- Spring Boot 3.x。
- Java 17。
- Maven。
- package：`com.leanmate`。
- 添加基础依赖：
  - Spring Web
  - Spring Validation
  - Spring Security
  - Spring Data JPA
  - PostgreSQL Driver
  - Flyway
  - Lombok 可选
  - Test

### 第 2 步：基础设施

- 统一响应 `ApiResponse`。
- 错误码枚举。
- 全局异常处理。
- 请求参数校验。
- 当前用户上下文。
- JWT 解析和鉴权过滤器。
- CORS 配置。

### 第 3 步：数据库迁移

将 `server/docs/database-design.md` 拆为 Flyway 脚本：

```text
server/src/main/resources/db/migration/
├── V1__enable_extensions.sql
├── V2__create_user_tables.sql
├── V3__create_profile_goal_tables.sql
├── V4__create_diet_tables.sql
├── V5__create_weight_stats_tables.sql
├── V6__create_report_retention_tables.sql
```

### 第 4 步：认证和用户档案

优先实现：

- `POST /v1/auth/oauth-login`
- `POST /v1/auth/refresh`
- `POST /v1/auth/logout`
- `GET /v1/me`
- `GET /v1/profile`
- `PUT /v1/profile`

### 第 5 步：体重和首页空状态

优先实现：

- `POST /v1/weights`
- `GET /v1/weights`
- `GET /v1/home/today`

这样 iOS 可以较早联调首页、档案、体重流程。

### 第 6 步：饮食记录

先实现手动记录：

- `POST /v1/diet/entries`
- `GET /v1/diet/entries`
- `PUT /v1/diet/entries/{entryId}`
- `DELETE /v1/diet/entries/{entryId}`

再接 AI 识别任务：

- `POST /v1/diet/recognitions/photo`
- `POST /v1/diet/recognitions/text`
- `GET /v1/diet/recognitions/{taskId}`

### 第 7 步：AI 日报和连续打卡

- `POST /v1/reports/daily`
- `GET /v1/reports/daily`
- `POST /v1/reports/daily/{reportId}/view`
- `GET /v1/retention/streak`

### 第 8 步：测试和联调

- Controller 层参数校验测试。
- Application 层业务规则测试。
- Repository 层关键查询测试。
- 统计快照重算测试。
- 权限隔离测试。

## Definition of Done

后端 V1.1 MVP 完成标准：

- OpenAPI 中的 V1.1 接口全部实现。
- Flyway 可以从空库创建完整 schema。
- 本地可以通过 `.env.local.example` 复制出的 `.env.local` 配置启动。
- 饮食、体重、首页统计、AI 日报、连续打卡主流程可联调。
- 用户只能访问自己的数据。
- AI 失败不影响手动记录。
- 单元测试覆盖核心计算和状态流。

## 新对话推荐提示

```text
请读取 AGENTS.md、server/AGENTS.md、docs/project-state.md 和 server/docs/development-readiness.md，开始 LeanMate V1.1 后端编码阶段。先初始化 Spring Boot 3.x + Java 17 + Maven 工程，不要实现超出 V1.1 文档范围的功能。
```
