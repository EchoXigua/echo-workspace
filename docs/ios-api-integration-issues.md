# iOS API 联调问题记录

## 2026-06-10

### 接口

`POST /v1/auth/oauth-login`

### 复现步骤

1. 启动 iOS App。
2. 在欢迎页点击“开始记录”。
3. 观察是否调用后端登录接口。

### 实际表现

iOS 欢迎页两个入口都调用 `startGuestSession()`，只进入游客模式，不会发起 OAuth 登录。`OnboardingViewModel` 内保留的登录方法使用 `mock-apple-identity-token`，但后端本地 mock verifier 只接受 `mock:` 前缀的 token。

### 期望表现

联调模式下“开始记录”应调用 `POST /v1/auth/oauth-login`，本地 mock 登录应使用后端支持的受控 token 格式；“随便看看”继续进入游客模式。

### 初步判断

iOS 问题 / 契约不一致。

### 处理状态

已修复，已验证。模拟器点击“开始记录”后进入目标校准流程；后端本地 mock token 登录成功，未再进入游客模式。

### 关联代码或提交

- `ios/LeanMate/Features/Onboarding/OnboardingView.swift`
- `ios/LeanMate/Features/Onboarding/OnboardingViewModel.swift`
- `server/src/main/java/com/leanmate/user/application/OAuthIdentityVerifier.java`

## 2026-06-10

### 接口

全部 live API。

### 复现步骤

1. 启动 iOS App。
2. 观察 AppEnvironment 当前注入的 APIClient。

### 实际表现

`LeanMateApp` 固定使用 `MockAPIClient(scenario: .profileIncomplete)`，没有本地 live baseURL 切换入口。

### 期望表现

Debug 联调时可通过环境变量或 launch argument 切换到 `AppEnvironment.live(baseURL:)`，未显式指定时保留 Mock 默认值，避免无后端时启动失败。

### 初步判断

iOS 问题。

### 处理状态

已修复，已验证。通过 launch argument `-LeanMateAPIBaseURL http://127.0.0.1:8080` 启动后，档案保存页显示后端返回的 `1,600 kcal`，确认 App 使用 live API。

### 关联代码或提交

- `ios/LeanMate/App/AppEnvironment.swift`
- `ios/LeanMate/App/LeanMateApp.swift`

## 2026-06-10

### 接口

`PUT /v1/profile`

### 复现步骤

1. 本地 mock 登录成功后，调用 `PUT /v1/profile`。
2. 请求体使用 iOS Mock/测试中常见值：`heightCm=168`、`currentWeightKg=55.8`、`targetWeightKg=52`。

### 实际表现

联调早期后端返回：

```json
{"code":40001,"message":"目标体重低于安全阈值","data":null}
```

原因是后端额外按目标 BMI `18.5` 做下限校验；iOS 后续也曾同步增加该本地校验。但产品侧确认不能用 BMI 18.5 拦截目标体重，当前体重和目标体重都只应按 DTO 范围 `20...300 kg` 校验。

### 期望表现

`heightCm=168`、`currentWeightKg=55.8`、`targetWeightKg=52` 应允许保存；更高当前体重如 `168cm / 100kg` 也不应受目标 BMI 下限逻辑影响。目标体重只保留 `20...300 kg` 范围校验。

### 初步判断

后端问题 / iOS 问题。

### 处理状态

已修复，已验证。后端已移除目标 BMI 18.5 下限校验；iOS 已移除“目标体重不能低于健康下限”本地拦截；Mock 和测试恢复使用 `52 kg` 作为合法目标。HTTP 直连 `targetWeightKg=52` 保存成功，模拟器目标校准输入 `52 kg` 后成功生成目标。

### 关联代码或提交

- `server/src/main/java/com/leanmate/user/domain/ProfileCalculator.java`
- `ios/LeanMate/Features/Profile/ProfileSetupViewModel.swift`
- `ios/LeanMate/Core/Mock/MockData.swift`
- `docs/api/openapi.yaml`

## 2026-06-10

### 接口

`GET /v1/home/today`

### 复现步骤

1. 使用 live API 启动 iOS App。
2. 通过本地 mock OAuth 登录。
3. 完成目标校准并进入首页。

### 实际表现

首页正确展示后端返回的今日数据：目标 `1600 kcal`、已摄入 `0`、早餐/午餐/晚餐为空态且补录入口可点击。

### 期望表现

目标校准完成后，首页应读取 `GET /v1/home/today`，展示后端计算的热量目标和今日餐次动态。

### 初步判断

无问题。

### 处理状态

已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Home/HomeViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/home/controller/HomeController.java`

## 2026-06-10

### 接口

`POST /v1/diet/entries`

### 复现步骤

1. live API 启动 App，进入首页。
2. 点击早餐“补录”。
3. 选择“手动记录”，填写 `Boiled egg`，热量 `140 kcal`。
4. 点击“保存记录”。

### 实际表现

后端创建饮食记录成功，首页刷新为“已摄入140 / 目标1600”，早餐展示 `Boiled egg`。

### 期望表现

手动记录应按当前餐次调用 `POST /v1/diet/entries`，保存成功后首页统计和餐次摘要应刷新。

### 初步判断

无问题。

### 处理状态

已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Features/Diet/DietEntryViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/diet/controller/DietEntryController.java`

## 2026-06-10

### 接口

`POST /v1/diet/recognitions/text`、`GET /v1/diet/recognitions/{id}`

### 复现步骤

1. live API 启动 App，进入记录页。
2. 选择“文本识别”，餐次切到“加餐”。
3. 输入 `banana 1`，点击“识别并确认”。
4. 在确认页点击“保存并更新首页”。

### 实际表现

文本识别创建成功，并进入确认页；iOS 随后获取识别任务详情并展示可编辑草稿。保存后首页出现加餐 `Banana 1`。

本地后端使用 `PlaceholderDietRecognitionClient`，返回的占位候选项只有名称，营养字段为 null；因此保存后该加餐热量为 `0 kcal`，首页总摄入保持 `140 kcal`。

### 期望表现

接口链路应创建识别任务、拉取任务详情、确认后保存饮食记录。未配置真实 AI 时，0 kcal 是本地占位识别限制；接入真实 AI 或手动编辑营养字段后应反映真实热量。

### 初步判断

本地环境限制 / 待确认产品体验。

### 处理状态

接口已验证。占位 AI 无营养值已记录，未作为阻塞问题处理。

### 关联代码或提交

- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Features/Diet/DietEntryViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/diet/controller/DietRecognitionController.java`
- `server/src/main/java/com/leanmate/ai/client/PlaceholderDietRecognitionClient.java`

## 2026-06-10

### 接口

`POST /v1/weights`、`GET /v1/weights`

### 复现步骤

1. live API 启动 App，进入“我的”页。
2. 点击“记录体重”，保存 `55.4 kg`。
3. 关闭 sheet，观察“我的”页和体重趋势页当前体重。
4. 直连 `GET /v1/weights?startDate=2026-06-01&endDate=2026-06-10` 确认后端数据。

### 实际表现

`POST /v1/weights` 保存成功，sheet 显示“体重已保存 55.4 kg”。后端 `GET /v1/weights` 返回今天 `55.40 kg`。但 iOS 原来关闭 sheet 后仍用 `GET /v1/profile` 的 `currentWeightKg=55.8` 展示“当前体重”，趋势页也显示“当前 55.8 kg”。

### 期望表现

体重记录保存后，“我的”页和趋势页展示用当前体重应以最近一条 `/v1/weights` 记录为准；profile 的 `currentWeightKg` 保留为档案初始体重或档案字段，不应覆盖最新称重展示。

### 初步判断

iOS 问题 / 契约不一致。

### 处理状态

已修复，已验证。`ProfileSummaryViewModel` 使用 `/v1/weights` 最新记录作为展示用当前体重；模拟器复验后“我的”页显示 `55.4 kg`、差距 `2.4 kg`，趋势页显示“目标 53 kg · 当前 55.4 kg”。

### 关联代码或提交

- `ios/LeanMate/Features/Profile/ProfileSummaryViewModel.swift`
- `ios/LeanMate/Features/Profile/ProfileSummaryView.swift`
- `ios/LeanMate/Features/Weight/WeightViewModel.swift`
- `server/src/main/java/com/leanmate/weight/controller/WeightController.java`
- `server/src/main/java/com/leanmate/weight/application/WeightApplicationService.java`

## 2026-06-10

### 接口

`GET /v1/me`、`GET /v1/profile`、`GET /v1/retention/streak`、`GET /v1/weights`

### 复现步骤

1. live API 启动 App。
2. 进入“我的”页。
3. 查看用户昵称占位、档案摘要、连续打卡、目标体重、每日目标、体重趋势入口。

### 实际表现

“我的”页展示 `LeanMate 用户`、`30 岁 · 未指定 · 轻度活动`、连续打卡 `1 天`、每日目标 `1,600 kcal`。体重保存修复后，当前体重来自 `/v1/weights` 最新记录，显示 `55.4 kg`。

### 期望表现

“我的”页应聚合当前用户、档案、连续打卡和体重数据；最新称重应覆盖档案初始体重作为展示用当前体重。

### 初步判断

无剩余问题。

### 处理状态

已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Profile/ProfileSummaryViewModel.swift`
- `ios/LeanMate/Features/Profile/ProfileSummaryView.swift`
- `server/src/main/java/com/leanmate/user/controller/UserController.java`
- `server/src/main/java/com/leanmate/user/controller/ProfileController.java`
- `server/src/main/java/com/leanmate/retention/controller/RetentionController.java`
- `server/src/main/java/com/leanmate/weight/controller/WeightController.java`

## 2026-06-10

### 接口

`GET /v1/reports/daily`、`POST /v1/reports/daily`、`POST /v1/reports/daily/{id}/view`

### 复现步骤

1. live API 启动 App 并保持登录。
2. 点击底部“日报”。
3. 首次进入显示空态后点击“生成日报”。
4. 观察生成后的状态。

### 实际表现

`GET /v1/reports/daily` 成功返回空态，页面显示“今天还没有日报”。点击生成后，`POST /v1/reports/daily` 成功生成评分 `89`、摘要、关键发现和建议；视图随后调用 `markViewedIfNeeded()`，页面状态显示“已查看”，覆盖 `POST /v1/reports/daily/{id}/view`。

### 期望表现

登录用户可查看当天日报空态、生成日报，并在打开生成结果后标记为已查看。游客模式不应直接生成日报。

### 初步判断

无问题。

### 处理状态

已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Report/DailyReportView.swift`
- `ios/LeanMate/Features/Report/DailyReportViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/report/controller/DailyReportController.java`

## 2026-06-10

### 接口

游客数据同步：逐个接口同步 vs `POST /v1/sync/local`

### 复现步骤

1. 阅读 iOS `OnboardingViewModel.syncGuestDataIfNeeded()`。
2. 阅读后端 `SyncController` 与 `SyncApplicationService`。

### 实际表现

iOS 登录后游客数据同步仍按本地数据类型逐个调用现有接口：`PUT /v1/profile`、`POST /v1/diet/entries`、`POST /v1/weights`。后端已提供批量 `POST /v1/sync/local`，可一次提交 profile、weights、dietEntries 并返回同步统计和失败项。

### 期望表现

需要明确 v1.1 最终策略：保留逐个同步，还是切到批量 sync 接口。如果切到批量接口，iOS 需要新增 DTO、APIClient 方法、同步结果处理和失败项提示。

### 初步判断

契约策略待确认。

### 处理状态

待处理。本轮未将逐个同步改为批量同步，避免扩大改动范围；现有逐个同步依赖的 profile / diet / weight 接口已分别完成联调。

### 关联代码或提交

- `ios/LeanMate/Features/Onboarding/OnboardingViewModel.swift`
- `server/src/main/java/com/leanmate/sync/controller/SyncController.java`
- `server/src/main/java/com/leanmate/sync/application/SyncApplicationService.java`

## 2026-06-10

### 接口

`POST /v1/diet/recognitions/photo`、`GET /v1/diet/recognitions/{id}`

### 复现步骤

1. 使用 `xcrun simctl addmedia` 将测试 PNG 放入 iOS 模拟器相册。
2. live API 启动 App，进入记录页。
3. 选择“拍照识别”，点击“从相册选”并选择测试图片。
4. 点击“开始识别”，进入照片确认页。
5. 保存后点击“删除这条记录”，清理测试记录。

### 实际表现

相册选择成功，App 通过 multipart 调用图片识别接口并进入照片确认页；保存成功后可删除测试记录。后端本地占位识别返回“拍照饮食待确认”，营养字段为空。

### 期望表现

图片识别应能上传图片、生成识别任务、拉取任务详情、进入确认页，并允许保存或删除确认后的记录。

### 初步判断

无接口阻塞；本地 AI 未配置导致识别结果为占位数据。

### 处理状态

已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Features/Diet/DietEntryViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/diet/controller/DietRecognitionController.java`
- `server/src/main/java/com/leanmate/ai/client/PlaceholderDietRecognitionClient.java`

## 2026-06-10

### 接口

`DELETE /v1/diet/entries/{id}`

### 复现步骤

1. live API 启动 App，进入首页。
2. 点击午餐“补录”，手动新增 `Pasta`，热量 `220 kcal`。
3. 保存成功后点击“删除这条记录”。
4. 在确认弹窗点击“删除”，再回到首页。

### 实际表现

保存成功后原流程立即跳回首页，导致已有的删除能力不可达。调整 iOS 后，保存成功停留在结果页并显示删除入口；删除确认后服务端删除成功，首页回到“已摄入140 / 目标1600”，午餐恢复空态。

### 期望表现

保存成功后应提供删除入口，用户确认删除后调用 `DELETE /v1/diet/entries/{id}` 并刷新首页统计。

### 初步判断

iOS 问题。

### 处理状态

已修复，已验证。

### 关联代码或提交

- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Features/Diet/DietEntryViewModel.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/diet/controller/DietEntryController.java`

## 2026-06-10

### 接口

`GET /v1/diet/entries`、`PUT /v1/diet/entries/{id}`

### 复现步骤

1. live API 启动 App。
2. 完成饮食记录新增后，在首页和记录页查找历史记录、详情、编辑入口。

### 实际表现

`LiveAPIClient` 已实现 `dietEntries(date:)` 和 `updateDietEntry(id:request:)`，但当前 iOS 交互没有饮食历史/详情入口，也没有编辑已有 entry 的入口。首页只展示 `GET /v1/home/today` 返回的摘要，不能触发 `GET /v1/diet/entries` 或 `PUT /v1/diet/entries/{id}`。

### 期望表现

如果 v1.1 需要联调饮食详情和编辑，应提供可点击流程：按日期加载饮食 entries、进入某条记录详情、编辑后调用 PUT 并刷新首页。

### 初步判断

iOS 问题 / 待确认产品范围。

### 处理状态

待处理。未将 HTTP 直连结果计为 App 联调通过。

### 关联代码或提交

- `ios/LeanMate/Features/Home/HomeView.swift`
- `ios/LeanMate/Features/Diet/DietEntryView.swift`
- `ios/LeanMate/Core/API/LiveAPIClient.swift`
- `server/src/main/java/com/leanmate/diet/controller/DietEntryController.java`

## 2026-06-10

### 接口

本地后端启动依赖 / PostgreSQL。

### 复现步骤

1. 执行 `mvn spring-boot:run` 启动后端。
2. 后端尝试连接 `jdbc:postgresql://localhost:5432/leanmate`。

### 实际表现

Docker daemon 未启动时 `docker compose ps` 返回 `docker.sock` 不存在，Postgres 未运行；后端启动失败并提示 `Connection to localhost:5432 refused`。

### 期望表现

联调前本地 Docker Desktop 已启动，`docker compose --env-file .env.local.example up -d postgres` 后 Postgres healthcheck 为 healthy。

### 初步判断

本地环境问题。

### 处理状态

已修复，已验证。已启动 Docker Desktop，Postgres 容器 healthy，后端启动成功。

### 关联代码或提交

- `server/docker-compose.yml`
- `server/.env.local.example`
