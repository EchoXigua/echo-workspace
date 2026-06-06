# V1.1 后端技术方案索引

## 目标

V1.1 的后端目标是支撑 iOS 第一版上线，同时保证后续 Android 和 Web 可以复用同一套账号、数据和接口。

本目录将 PRD 的核心需求拆成后端技术方案。方案确认后，再更新 OpenAPI，最后进入后端和 iOS 并行开发。

## 需求映射

| PRD 章节 | 需求 | 后端技术方案 | OpenAPI 状态 |
|----------|------|--------------|--------------|
| 8.1 | 用户档案 | [01-account-profile-goal.md](01-account-profile-goal.md) | 已补齐 V1.1 契约 |
| 8.2 | 首页 | [04-home-stats-streak.md](04-home-stats-streak.md) | 已补齐 V1.1 契约 |
| 8.3 | 饮食记录 | [02-diet-recording.md](02-diet-recording.md) | 已补齐 V1.1 契约 |
| 8.4 | 体重记录 | [03-weight-recording.md](03-weight-recording.md) | 已补齐 V1.1 契约 |
| 8.5 | AI 日报 | [05-ai-daily-report.md](05-ai-daily-report.md) | 已补齐 V1.1 契约 |
| 8.6 | 连续打卡 | [04-home-stats-streak.md](04-home-stats-streak.md) | 已补齐 V1.1 契约 |

## V1.1 后端开发前置文档

- 技术选型：`../../technology-selection.md`
- 数据库设计：`../../database-design.md`
- API 设计说明：`api-design.md`
- API 契约：`../../../../docs/api/openapi.yaml`
- 领域模型：`../../../../docs/architecture/domain-model.md`
- 技术方案检查清单：`../checklist.md`

## 进入编码前必须补齐

- `docs/api/openapi.yaml` 已补齐 V1.1 主要契约，编码时以它为准。
- `server/docs/ai-provider.md` 已定义 AI 接入方式，具体供应商和模型名仍需确认。
- `docs/data/events.md` 和 `docs/data/metrics.md` 已定义 V1.1 埋点和指标口径。
- 后端工程初始化后，需要把 `server/docs/database-design.md` 拆成 Flyway 迁移脚本。

## 并行开发方式

1. 后端技术方案确认。
2. OpenAPI 更新到可联调状态。
3. iOS 根据 OpenAPI 生成/手写 API Client，使用 Mock 数据开发页面。
4. 后端根据技术方案实现接口、迁移脚本和测试。
5. 双方以 OpenAPI 和联调环境对齐，不等待完整后端全部完成才启动 iOS。
