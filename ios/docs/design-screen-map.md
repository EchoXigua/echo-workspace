# LeanMate V1.1 iOS 设计稿画面映射

Last updated: 2026-06-06

## 设计来源

唯一准稿：

- `design/app/LeanMateV1.0-shikaka.pen`

忽略：

- `design/app/LeanMateV1.0.pen`

## 使用原则

- 业务页面只按 V1.1 PRD 和 `docs/api/openapi.yaml` 实现。
- 页面样式优先复用 `ios/LeanMate/Components/` 和 `ios/LeanMate/Core/DesignSystem/`。
- 准稿中的画面用于定义 UI 结构、状态和交互入口，不新增 PRD 或 OpenAPI 之外的业务能力。
- 首页、记录、日报、我的四个主入口共用 `LMBottomTabs`。
- Loading、Empty、Error、游客态优先作为页面状态处理，不单独拆成新业务模块。

## 顶层画面映射

| 设计稿画面 | iOS Feature | 页面/状态 | 业务开发阶段 |
| --- | --- | --- | --- |
| `欢迎启动页 / 食卡卡风` | `Onboarding` | 欢迎 / 登录占位入口 | 第 1 批 |
| `Onboarding - 唯一问题 / 食卡卡风` | `Profile` | 用户档案填写 / 目标生成 | 第 1 批 |
| `首页 / 今日热量` | `Home` | 首页 loaded 状态 | 第 2 批 |
| `首页 Empty State / 食卡卡风` | `Home` | 首页 empty 状态 | 第 2 批 |
| `首页（游客模式）/ 食卡卡风` | `Home` / `Onboarding` | 游客态首页提示 | 第 2 批 |
| `记录饮食 / 生活化入口` | `Diet` | 饮食记录入口 | 第 3 批 |
| `文字解析确认 / 食卡卡风` | `Diet` | 文本记录确认 | 第 3 批 |
| `拍照识别确认 / 食卡卡风` | `Diet` | 拍照识别确认 | 第 4 批 |
| `删除确认弹窗 / 食卡卡风` | `Diet` | 删除饮食记录确认 | 第 4 批 |
| `体重记录 Sheet / 食卡卡风` | `Weight` | 体重记录 Sheet | 第 3 批 |
| `AI日报 / 条目化分析` | `Report` | AI 日报 loaded 状态 | 第 4 批 |
| `AI日报 Loading State / 食卡卡风` | `Report` | AI 日报 loading 状态 | 第 4 批 |
| `我的 / 数据与计划` | `Profile` | 我的 / 数据与计划 | 第 5 批 |
| `里程碑弹窗 / 食卡卡风` | `Home` / `Retention` | 连续打卡里程碑弹窗 | 第 5 批 |
| `Component / Status Bar` | 基础组件 | 系统状态栏参考，不在 App 内复刻 | 已覆盖 |
| `Component / Bottom Tabs` | 基础组件 | `LMBottomTabs` | 已覆盖 |
| `Component / Nutrient Chip` | 基础组件 | `LMNutrientChip` | 已覆盖 |

## Feature 拆分建议

### Onboarding

- `OnboardingView`
- `OnboardingViewModel`
- 登录占位入口。
- 根据 `AuthToken.profileCompleted` 或 `ProfilePayload.profileCompleted` 决定是否进入档案填写。

### Profile

- `ProfileSetupView`
- `ProfileSetupViewModel`
- `ProfileSummaryView`
- 对应 OpenAPI：
  - `GET /v1/profile`
  - `PUT /v1/profile`
  - `GET /v1/me`

### Home

- `HomeView`
- `HomeViewModel`
- `HomeEmptyView`
- `VisitorHomeBanner`
- 对应 OpenAPI：
  - `GET /v1/home/today`
  - `GET /v1/retention/streak`

### Diet

- `DietEntryView`
- `TextDietRecognitionView`
- `DietConfirmationView`
- `PhotoRecognitionConfirmationView`
- `DeleteDietEntryDialog`
- 对应 OpenAPI：
  - `POST /v1/diet/recognitions/photo`
  - `POST /v1/diet/recognitions/text`
  - `GET /v1/diet/recognitions/{taskId}`
  - `GET /v1/diet/entries`
  - `POST /v1/diet/entries`
  - `PUT /v1/diet/entries/{entryId}`
  - `DELETE /v1/diet/entries/{entryId}`

### Weight

- `WeightEntrySheet`
- `WeightViewModel`
- 对应 OpenAPI：
  - `GET /v1/weights`
  - `POST /v1/weights`

### Report

- `DailyReportView`
- `DailyReportViewModel`
- 对应 OpenAPI：
  - `GET /v1/reports/daily`
  - `POST /v1/reports/daily`
  - `POST /v1/reports/daily/{reportId}/view`

## 首批业务开发建议

第 1 批只做：

1. `OnboardingView`
2. `ProfileSetupView`
3. `ProfileSetupViewModel`
4. Profile Mock 流程

第 1 批不做：

- 首页完整统计。
- 饮食记录。
- 拍照识别。
- AI 日报。
- 真实 Apple 登录。

这样可以先验证 App 启动、Mock 登录态、档案填写、保存档案和页面跳转边界。
