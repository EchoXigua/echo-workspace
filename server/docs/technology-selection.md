# LeanMate 后端技术选型

## 结论

V1.1 后端采用一套轻量但可扩展的 Spring Boot 模块化单体：

| 类别 | V1.1 选择 | 结论 |
|------|-----------|------|
| 语言 | Java 17 | 使用 LTS 版本，生态稳定，满足 Spring Boot 3.x 基线要求 |
| 框架 | Spring Boot 3.x | 主流、成熟、适合 API 服务 |
| 构建工具 | Maven | 简单稳定，后端优先 |
| 数据库 | PostgreSQL | 作为核心业务数据源 |
| 数据迁移 | Flyway | 强制管理 schema 变更 |
| ORM/数据访问 | Spring Data JPA + 必要时 JdbcClient | MVP 提速，复杂查询保留直接 SQL 能力 |
| 缓存 | V1.1 不引入 Redis | 等明确需要再加 |
| 消息队列 | V1.1 不引入 MQ | 先用数据库任务表 + 后台任务 |
| 定时任务 | Spring Scheduler | 用于日报生成、连续记录刷新 |
| 对象存储 | S3 兼容对象存储 | 保存饮食图片 |
| AI 调用 | 后端 AI Provider Adapter | App 不直接调用 AI |
| API 契约 | OpenAPI | iOS、Android、Web、后端统一对齐 |
| 鉴权 | Spring Security + JWT | 支持跨端账号体系 |
| 测试 | JUnit 5 + Spring Boot Test | 后续可加 Testcontainers |

## 为什么不在 V1.1 引入 Redis

V1.1 暂时不需要 Redis。

当前业务主要是：

- 用户档案。
- 饮食记录。
- 体重记录。
- 今日统计。
- AI 日报。
- 连续打卡。

这些数据都需要持久化，PostgreSQL 可以直接承担。过早引入 Redis 会增加部署、监控、数据一致性和排障成本。

### 暂不使用 Redis 的场景

- 首页今日统计：优先读取 `daily_nutrition_snapshots` 表。
- 连续打卡：保存在 `streaks` 表。
- AI 日报：保存在 `daily_ai_reports` 表。
- AI 任务状态：保存在 `ai_recognition_tasks` 表。
- 登录态：使用 JWT，不依赖服务端 session。

### 后续引入 Redis 的触发条件

满足以下任一条件再引入：

- 首页或统计接口 QPS 明显增加，数据库读压力高。
- 需要短信验证码、邮箱验证码、频率限制。
- 需要分布式锁控制日报生成、AI 任务去重。
- 需要临时会话、短期 token 黑名单。
- 需要热点排行榜、实时计数或高频行为缓存。

## 为什么不在 V1.1 引入 MQ

V1.1 暂时不需要 RabbitMQ、Kafka、RocketMQ 等消息队列。

AI 识别和 AI 日报确实是异步任务，但早期任务量可控，可以用数据库任务表加后台 worker 处理：

```text
App -> API 创建任务 -> 写入 ai_recognition_tasks/daily_report_jobs
                      -> 后台线程或定时任务扫描 pending
                      -> 调用 AI Provider
                      -> 更新任务状态和业务结果
```

这套方案的好处：

- 少一个基础设施依赖。
- 任务状态天然可追踪。
- 失败重试可以通过数据库字段控制。
- 本地开发和部署简单。

### 后续引入 MQ 的触发条件

满足以下任一条件再引入：

- AI 图片识别、日报生成任务量明显增加。
- 后台任务影响主 API 响应。
- 需要多个 worker 横向扩容处理任务。
- 任务需要更严格的延迟、重试、死信队列。
- 行为事件采集量大，需要异步写入分析链路。
- 推送提醒、风险预警、周报/月报生成开始变复杂。

### 如果后续需要 MQ，优先选择

- 轻量异步任务：先考虑 PostgreSQL 任务表 + worker。
- 中等规模业务异步：RabbitMQ。
- 高吞吐行为事件流：Kafka。

V1.1 不直接上 Kafka。Kafka 更适合大规模事件流，不适合当前阶段。

## 数据库选择

选择 PostgreSQL。

原因：

- 关系模型适合用户、饮食、体重、日报、连续打卡等核心业务。
- 支持 JSONB，后续可保存 AI 原始输出、行为事件扩展属性。
- 支持事务、索引、约束，适合保证核心数据一致性。
- 未来可以通过只读副本、分区、归档策略演进。

V1.1 不建议使用 MongoDB 作为主库。当前核心数据强结构化，关系型数据库更合适。

## 数据迁移

使用 Flyway。

要求：

- 所有表结构变更必须写迁移脚本。
- 禁止手工在线上数据库直接改 schema。
- 迁移脚本随代码提交。

建议目录：

```text
server/src/main/resources/db/migration/
├── V1__create_users.sql
├── V2__create_food_entries.sql
└── V3__create_daily_reports.sql
```

## 数据访问

V1.1 使用 Spring Data JPA 提升开发效率。

复杂统计查询可以使用 JdbcClient 或 native SQL，不强行用 JPA 表达所有查询。

原则：

- 简单 CRUD 用 JPA。
- 明确复杂聚合查询用 SQL。
- 不把 Entity 直接返回给 Controller。
- 对外响应使用 DTO。

## AI Provider 接入

App 不直接调用 AI Provider。服务端提供统一 AI 适配层：

```text
ai/
├── client
├── prompt
└── task
```

V1.1 需要支持：

- 图片饮食识别。
- 文本饮食解析。
- AI 日报生成。

要求：

- AI API Key 只能放后端。
- 保存 AI 调用任务状态。
- 保存原始输出，便于排查和后续质量优化。
- 用户确认后的结构化饮食记录才进入正式统计。
- AI 调用失败时，用户仍可手动录入。

## 对象存储

饮食图片不进入数据库，使用 S3 兼容对象存储。

V1.1 可以由后端接收 `multipart/form-data` 后上传对象存储。后续如果上传量增大，再改成客户端直传预签名 URL。

数据库只保存：

- image_url
- object_key
- file_size
- content_type
- recognition_task_id

## 鉴权方案

V1.1 使用 Spring Security + JWT。

建议：

- Access Token 短有效期。
- Refresh Token 长有效期，并支持服务端撤销。
- iOS 第一阶段可以支持 Sign in with Apple。
- 后续 Android/Web 需要补充手机号、邮箱或第三方登录。

不要把账号体系绑定死在 Apple 生态上。

## 部署策略

V1.1 推荐最小部署：

```text
Spring Boot API
PostgreSQL
S3 compatible object storage
AI Provider
```

暂不部署：

- Redis
- MQ
- Elasticsearch
- 独立任务服务
- 大数据分析链路

## 后续演进路线

### 阶段一：V1.1

- Spring Boot 单体。
- PostgreSQL。
- 对象存储。
- AI Provider Adapter。
- 数据库任务表。

### 阶段二：留存优化

- 根据指标需求补行为事件表。
- 如果验证码、限流或热点接口出现，再引入 Redis。
- 周报/月报仍可先用后台任务。

### 阶段三：AI 教练

- 引入更完整的 AI 任务队列。
- 根据任务量决定是否上 RabbitMQ。
- 根据行为事件量决定是否上 Kafka。
- 评估向量数据库或 PostgreSQL pgvector，用于用户长期记忆和个性化模型。

## 当前明确不做

- V1.1 不做微服务。
- V1.1 不引入 Redis。
- V1.1 不引入 MQ。
- V1.1 不引入 Kafka。
- V1.1 不把 CloudKit/iCloud 作为主后端。
- V1.1 不让 App 直接调用 AI Provider。
