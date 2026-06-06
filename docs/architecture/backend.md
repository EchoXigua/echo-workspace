# LeanMate 后端架构设计

## 定位

LeanMate 从 V1.1 开始接入后端。后端不是简单的数据同步层，而是跨 iOS、Android、未来 Web 的统一业务入口。

后端负责：

- 用户账号、档案和目标。
- 饮食记录、体重记录和每日统计。
- AI 图片识别、文本解析和日报生成。
- 连续记录、成就、留存指标。
- 后续 AI 周报、月报、AI 教练、行为洞察和风险预警。

CloudKit/iCloud 不作为主后端。它可以在后续作为 iOS 端本地备份或体验增强，但不能成为业务真相来源。

## 技术选型

V1.1 推荐：

- 语言：Java 17。
- 框架：Spring Boot 3.x。
- 架构：模块化单体。
- 构建：Maven，除非后续 Android/后端团队强依赖 Gradle 统一生态。
- 数据库：PostgreSQL。
- 缓存：V1.1 可不引入 Redis，等日报生成、限流、会话或排行榜有明确需求后再加。
- 对象存储：用于保存饮食图片，数据库只保存 URL 和元数据。
- AI 接入：服务端统一代理模型调用，App 不直接持有 AI API Key。
- API 契约：OpenAPI，路径为 `docs/api/openapi.yaml`。

详细后端技术选型见 `server/docs/technology-selection.md`。

## 为什么 V1.1 就上后端

V1.1 已包含拍照识别、文本解析和 AI 日报。如果只靠 iPhone 本地存储和 iCloud，会遇到几个问题：

- AI Key 暴露在 App 内，成本和安全不可控。
- 后续 Android 无法复用 iCloud 数据。
- 留存、日报查看率、建议采纳率等指标难以统一统计。
- AI 周报、月报、风险预警、行为洞察需要统一的历史数据。
- 未来 Web 端需要同一套账号和 API。

所以 V1.1 开始就建立后端，但保持简单，不做微服务和复杂平台化。

## 模块划分

```text
com.leanmate
├── common
│   ├── api
│   ├── security
│   ├── exception
│   ├── validation
│   └── time
├── user
│   ├── auth
│   ├── profile
│   └── goal
├── diet
│   ├── entry
│   ├── recognition
│   └── nutrition
├── weight
├── stats
├── report
│   ├── daily
│   └── prompt
├── retention
│   ├── streak
│   └── achievement
└── ai
    ├── client
    ├── prompt
    └── task
```

每个业务模块内部可以再按 `controller`、`application`、`domain`、`repository`、`dto` 拆分。不要在根目录下建立一个巨大的全局 `service/`。

推荐模块内结构：

```text
diet/
├── controller
├── application
├── domain
├── repository
└── dto
```

## 分层职责

- controller：HTTP 入参、鉴权上下文、返回 DTO。
- application：用例编排，例如“确认饮食记录并刷新今日统计”。
- domain：业务规则，例如饮食记录状态、连续记录判定、热量目标计算。
- repository：数据库读写。
- dto：请求和响应对象。
- common：跨模块基础设施，不放业务规则。

## 数据库边界

V1.1 核心表建议：

- users
- user_profiles
- weight_goals
- food_entries
- food_items
- ai_recognition_tasks
- weight_entries
- daily_nutrition_snapshots
- daily_ai_reports
- streaks
- achievements

后续扩展表：

- behavior_events
- weekly_ai_reports
- monthly_ai_reports
- user_insights
- coach_conversations
- coach_messages

## AI 接入方式

App 不直接调用 AI 模型。所有 AI 请求经过后端：

```text
iOS/Android/Web -> LeanMate API -> AI Provider
```

服务端需要保存 AI 任务记录：

- 输入：图片 URL、用户文本、业务日期、餐次。
- 输出：AI 原始结果、结构化候选食物、错误信息。
- 状态：pending、running、succeeded、failed。

用户确认后的饮食记录才进入正式统计。AI 原始输出只用于溯源和质量分析。

## 同步和离线

V1.1 优先保证在线体验。客户端可以做本地草稿和失败重试：

- 手动记录失败时保留本地草稿。
- 拍照识别失败时允许改为手动录入。
- 体重记录失败时进入待同步队列。

不要在 V1.1 同时做复杂离线同步冲突解决。跨端一致性以后端数据为准。

## 定时任务

V1.1 至少需要：

- 每日 AI 日报生成。
- 连续记录状态刷新。

早期可以放在同一个 Spring Boot 应用中，用调度任务实现。等 AI 任务耗时明显影响主 API，再拆成 worker。

## 安全要求

- 密码使用 BCrypt 或采用第三方登录，不保存明文密码。
- AI API Key 只保存在后端环境变量或密钥管理服务。
- 用户只能访问自己的饮食、体重、日报和统计数据。
- 图片上传需要限制文件大小、类型和访问权限。
- 日志不能输出 Token、AI Key、手机号等敏感信息。

## 与端侧的关系

iOS 和 Android 不各自实现一套业务规则。端侧只负责：

- 表单校验和交互状态。
- 本地草稿。
- 数据展示。
- 调用后端 API。

核心规则放在后端：

- BMI/BMR/每日推荐热量计算。
- 饮食记录确认后如何更新统计。
- 连续记录如何判定。
- AI 日报如何生成和保存。
- 成就和里程碑如何触发。

## 后续演进

当以下情况出现时，再考虑拆分 worker 或独立服务：

- 图片识别和日报生成任务量明显增加。
- 定时任务影响 API 响应。
- AI 教练需要长对话和记忆检索。
- 行为事件量快速增长，需要独立分析链路。
- Web 管理端需要更复杂的运营和数据看板。
