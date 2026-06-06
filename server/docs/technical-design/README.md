# 后端技术方案设计规范

后端技术方案设计用于承接 PRD，把产品需求翻译成后端可实现、可评审、可拆任务的方案。它位于 PRD 和 OpenAPI 之间。

## 推荐流程

```text
PRD/产品规划
  -> 后端技术方案设计
  -> OpenAPI 接口契约
  -> 后端任务拆分
  -> iOS/Android/Web 基于接口并行开发
```

这个流程的目标是减少串行等待：后端方案和接口稳定后，后端可以实现业务，iOS 可以按接口 Mock 和设计稿并行开发。

## 文档放置规则

```text
server/docs/technical-design/
├── README.md              # 技术方案写作规范
├── template.md            # 单需求技术方案模板
└── v1.1/
    ├── README.md          # V1.1 需求到技术方案映射
    ├── 01-account-profile-goal.md
    ├── 02-diet-recording.md
    ├── 03-weight-recording.md
    ├── 04-home-stats-streak.md
    └── 05-ai-daily-report.md
```

## 每个需求都要说明什么

每份后端技术方案至少包含：

- 对应 PRD 章节。
- 业务目标。
- 后端职责。
- 不做范围。
- 核心流程。
- 数据模型影响。
- API 影响。
- 状态流和边界规则。
- 权限和数据归属。
- 异步任务、失败重试和是否需要 Redis/MQ。
- 异常和降级策略。
- 埋点和指标。
- 测试要点。
- 待确认问题。

## 和 OpenAPI 的关系

后端技术方案先回答“这个需求后端怎么做”，OpenAPI 再回答“客户端怎么调用”。

当技术方案涉及接口变化时，必须同步更新 `../../../docs/api/openapi.yaml`。客户端和服务端都以 OpenAPI 为接口契约，不以口头约定为准。

数据库表结构统一写在 `../database-design.md`。单个需求技术方案只写该需求涉及哪些表、如何使用、事务和一致性要求，不在每份方案里重复完整建表 SQL。

V1.1 人类可读 API 设计写在 `v1.1/api-design.md`。OpenAPI 仍是最终契约。

## 评审通过标准

进入开发前，至少满足：

- 需求范围清楚。
- 数据模型和状态流清楚。
- 主要异常路径清楚。
- API 入参、出参、错误码清楚。
- iOS 可以基于 OpenAPI 和设计稿开始 Mock 开发。
- 后端可以基于方案拆任务和写迁移脚本。
