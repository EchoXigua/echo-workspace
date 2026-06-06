# LeanMate V1.1 AI Provider 方案

## 定位

AI Provider 是后端对模型服务的统一适配层。客户端不直接调用模型，不持有 AI API Key。

V1.1 需要支持：

- 拍照饮食识别。
- 文本饮食解析。
- AI 日报生成。

## 架构

```text
iOS/Android/Web
  -> LeanMate API
  -> AI Task / Report Service
  -> AI Provider Adapter
  -> Model Provider
```

后端内部建议模块：

```text
com.leanmate.ai
├── client      # 模型供应商 HTTP Client
├── prompt      # prompt 模板和版本
├── task        # AI 任务编排
└── dto         # 模型输入输出 DTO
```

## V1.1 不做范围

- 不做 AI 聊天。
- 不做长期记忆。
- 不做向量数据库。
- 不做多模型自动路由。
- 不把 AI 输出直接当作业务事实。

## 数据原则

- AI 原始输出保存到 `ai_recognition_tasks.raw_output` 或 `daily_ai_reports.raw_output`。
- AI 结构化结果保存到 `ai_recognition_tasks.structured_result`。
- 用户确认后的饮食记录保存到 `food_entries` 和 `food_items`。
- 只有 confirmed 饮食记录进入统计和日报数据源。

## 拍照饮食识别

### 输入

- 图片 URL 或对象存储 key。
- 餐次：breakfast/lunch/dinner/snack。
- 业务日期。
- 用户可选补充文本。

### 输出结构

模型输出需要转成后端统一结构：

```json
{
  "items": [
    {
      "name": "鸡蛋",
      "quantityText": "2个",
      "weightG": 100,
      "caloriesKcal": 140,
      "proteinG": 12.0,
      "fatG": 10.0,
      "carbsG": 1.0,
      "confidence": 0.82
    }
  ],
  "notes": "图片中可能还有少量酱料，热量未完全计算。"
}
```

## 文本饮食解析

### 输入

用户自然语言，例如：

```text
早餐吃了两个鸡蛋，一杯豆浆，一个包子。
```

### 输出

输出结构和拍照识别保持一致，方便客户端复用确认页。

## AI 日报

### 输入上下文

日报生成只使用结构化业务数据：

- 用户档案。
- 当前目标。
- 当日营养快照。
- 当日饮食记录。
- 当日体重记录。
- 连续打卡状态。

### 输出结构

```json
{
  "score": 84,
  "summary": "今天整体控制不错，蛋白质摄入较好。",
  "problem": "晚餐热量偏高，剩余热量被快速用完。",
  "suggestion": "明天早餐可以继续保证蛋白质，晚餐减少油脂和主食份量。"
}
```

要求：

- 简洁。
- 3 到 5 句话。
- 给出可执行建议。
- 不做医疗诊断。
- 不使用恐吓式表达。

## Prompt 管理

V1.1 prompt 可以先放在代码资源文件中：

```text
server/src/main/resources/prompts/
├── diet-photo-recognition.md
├── diet-text-recognition.md
└── daily-report.md
```

每个 prompt 需要有版本号，调用结果记录 `prompt_version` 或写入 `raw_output` 元数据。后续如果频繁迭代，再迁移到数据库或配置中心。

## 超时和重试

建议默认策略：

- 图片识别超时：30 秒。
- 文本解析超时：20 秒。
- 日报生成超时：30 秒。
- 网络错误可重试 1 次。
- 模型返回结构无法解析时，不自动重试，保存 failed 并记录错误。

V1.1 不需要 MQ。异步状态通过数据库表记录。

## 成本控制

V1.1 先做基础控制：

- 单用户每日识别次数限制。
- 单用户每日手动触发日报次数限制。
- 图片上传大小限制。
- 日志记录模型调用耗时和状态，不记录敏感原文之外的密钥。

后续需要补充：

- 按用户、设备、IP 的频率限制。
- AI 成本统计。
- 异常调用告警。

## 安全和隐私

- AI API Key 只存在后端环境变量或密钥管理服务。
- App 不直接调用模型。
- 日志不能输出 AI API Key、Token、用户隐私信息。
- 饮食图片属于敏感数据，需要对象存储权限控制。
- 图片保存期限需要产品和合规确认。
- AI 提示不应声称医疗诊断或治疗建议。

## 失败降级

拍照识别失败：

- `ai_recognition_tasks.status = failed`。
- 客户端提示用户改为手动录入。
- 不创建 confirmed 饮食记录。

文本解析失败：

- 返回失败状态。
- 客户端保留用户输入，允许手动拆分食物项。

日报生成失败：

- `daily_ai_reports.status = failed`。
- 首页 `reportSummary = null`。
- 用户可以稍后重试。

## 环境变量

建议：

```text
AI_PROVIDER=
AI_API_KEY=
AI_BASE_URL=
AI_DIET_PHOTO_MODEL=
AI_DIET_TEXT_MODEL=
AI_DAILY_REPORT_MODEL=
AI_REQUEST_TIMEOUT_SECONDS=
AI_DAILY_REPORT_RETRY_LIMIT=
```

具体模型名称等到 provider 确认后再写入环境配置。

## 测试要点

- AI Provider Client 超时处理。
- AI 返回结构缺字段时的解析行为。
- AI 返回非法 JSON 时标记 failed。
- 用户确认后才进入正式统计。
- AI 失败不影响手动录入。
- 日报失败不影响饮食和体重记录。

## 待确认问题

- V1.1 使用哪个模型供应商。
- 图片保存期限。
- 单用户每日 AI 调用次数限制。
- 是否需要人工可配置 prompt。
