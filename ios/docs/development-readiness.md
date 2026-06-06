# LeanMate V1.1 iOS 开发就绪说明

## 结论

V1.1 iOS 基础设施阶段已完成。下一步是否进入业务开发阶段，等待用户确认。

基础设施状态见 `ios/docs/infrastructure-status.md`。

## 基础决策

- 最低系统版本：iOS 17。
- 语言：Swift。
- UI：SwiftUI 优先。
- 架构：MVVM + feature-first。
- 并发：Swift Concurrency，使用 `async/await`。
- 本地草稿：当前基础设施阶段使用 `FileLocalStore`；后续如确需 SwiftData，可替换 `LocalStore` 实现。
- 安全存储：Keychain。
- 接口契约：仓库根目录下的 `docs/api/openapi.yaml`。
- 后端是主数据源，iCloud/CloudKit 不作为主后端。

## 编码入口

新对话进入 iOS 编码阶段时，先读：

1. `AGENTS.md`
2. `ios/AGENTS.md`
3. `docs/project-state.md`
4. `ios/docs/development-readiness.md`
5. `ios/docs/architecture.md`
6. `ios/docs/coding-style.md`
7. `ios/docs/api-mock-strategy.md`
8. `docs/api/openapi.yaml`
9. `docs/product/prd-v1.1.md`

## 设计稿入口

当前唯一准稿：

- `design/app/LeanMateV1.0-shikaka.pen`

`design/app/LeanMateV1.0.pen` 不作为 V1.1 iOS UI 实现依据。

进入 UI 编码前，应先根据设计稿确认：

- 首页视觉结构。
- 饮食记录入口。
- 拍照/文本/手动记录确认页。
- 体重记录页。
- AI 日报页。
- 用户档案填写流程。

## 已完成基础设施

- Xcode iOS App 工程：`ios/LeanMate.xcodeproj`
- Product Name：`LeanMate`
- Bundle ID：暂用 `app.leanmate.ios`
- Deployment Target：iOS 17.0
- SwiftUI App 生命周期
- MVVM + feature-first 目录边界

```text
ios/LeanMate/
├── App/
├── Core/
├── Features/
├── Components/
├── Resources/
└── PreviewSupport/
```

- 网络层。
- Token 存储。
- Mock API Client。
- App 路由。
- 设计 token。
- 可复用基础组件。
- 错误提示。
- Loading/Empty/Error 状态。
- 本地草稿和待同步边界。

## 建议业务开发顺序

等待用户确认后再开始业务开发。

优先顺序：

1. Onboarding / 登录占位。
2. 用户档案填写。
3. 首页。
4. 体重记录。
5. 手动饮食记录。
6. 饮食记录确认页。
7. AI 日报。

拍照识别和文本解析可以先用 Mock 数据贯通确认流程。

## 接真实后端

后端接口可用后，将业务页面注入的 Mock API Client 切换为真实 API Client。

优先联调：

1. 登录和用户档案。
2. 首页今日状态。
3. 体重记录。
4. 手动饮食记录。
5. AI 识别任务。
6. AI 日报。

## Definition of Done

iOS V1.1 MVP 完成标准：

- iOS 17 真机或模拟器可运行。
- 用户可完成档案填写。
- 首页可展示目标热量、摄入热量、剩余热量、体重、连续打卡、日报摘要。
- 用户可记录体重。
- 用户可手动保存饮食记录。
- 拍照/文本识别流程可进入确认页。
- 用户可查看 AI 日报。
- Token 存储在 Keychain。
- 后端失败时有明确降级和错误提示。

## 新对话推荐提示

```text
请读取 AGENTS.md、ios/AGENTS.md、docs/project-state.md、ios/docs/development-readiness.md 和 ios/docs/infrastructure-status.md，继续 LeanMate V1.1 iOS。iOS 基础设施已完成并通过 xcodebuild 构建验证；业务开发尚未开始。是否进入业务开发阶段由我确认，不要实现超出 V1.1 PRD、OpenAPI 和 design/app/LeanMateV1.0-shikaka.pen 的功能。
```
