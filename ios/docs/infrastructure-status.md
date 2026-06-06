# LeanMate V1.1 iOS 基础设施状态

Last updated: 2026-06-06

## 结论

iOS 基础设施阶段已完成，可以等待业务开发阶段启动。

本阶段只完成工程、架构边界、网络、Mock、存储和可复用 UI 组件；未实现 Onboarding、Profile、Home、Diet、Weight、Report 等业务页面和业务 ViewModel。

## 已完成

- Xcode iOS App 工程：`ios/LeanMate.xcodeproj`
- App 入口：`ios/LeanMate/App/LeanMateApp.swift`
- 轻量依赖环境：`AppEnvironment`
- App 路由基础：`AppRouter`
- MVVM + feature-first 目录边界：
  - `Features/Onboarding`
  - `Features/Profile`
  - `Features/Home`
  - `Features/Diet`
  - `Features/Weight`
  - `Features/Report`
- API DTO：按 `docs/api/openapi.yaml` 手写 V1.1 DTO
- `APIClient` 协议：覆盖 OpenAPI 内 V1.1 端点
- `LiveAPIClient`：
  - URLSession 封装
  - Bearer Token 注入
  - 统一响应解码
  - 错误码映射
  - 401 refresh token 重试
  - multipart photo recognition 请求封装
- `MockAPIClient`：
  - 成功状态
  - 空状态
  - 错误状态
  - 档案未完成
  - AI 识别中
  - AI 识别失败
- Token 存储：
  - `TokenStore` 协议
  - `KeychainTokenStore`
  - `InMemoryTokenStore`
- 本地草稿和待同步边界：
  - `LocalStore` 协议
  - `InMemoryLocalStore`
  - `FileLocalStore`
- 设计系统：
  - `LMColors`
  - `LMTypography`
  - `LMSpacing`
- 可复用组件：
  - `LMButton`
  - `LMCard`
  - `LMBottomTabs`
  - `LMNutrientChip`
  - `LMStateView`
  - `LMSearchField`
  - `LMSheetHandle`
  - `LMTag`
  - `LMMetricTile`
- 基础设施预览壳：`InfrastructurePreviewView`

## 组件是否属于基础设施

属于。

V1.1 设计稿中反复出现的按钮、卡片、底部导航、搜索框、Sheet handle、胶囊标签、营养 chip、Loading/Empty/Error 状态是后续业务页面的基础 UI 资产。本阶段已将这些控件先行抽出，后续业务开发应优先复用，不在页面里重复手写样式。

## 设计稿来源

唯一准稿：

- `design/app/LeanMateV1.0-shikaka.pen`

忽略：

- `design/app/LeanMateV1.0.pen`

## 当前技术边界

- 最低兼容 iOS 17.0。
- Bundle ID 暂用 `app.leanmate.ios`。
- 不引入第三方依赖。
- 不直接调用 AI Provider。
- 不实现 OpenAPI 之外的接口。
- 不实现业务页面流程。
- 本地持久化当前使用 `FileLocalStore` 作为可构建、可持久化基础设施；后续如确需 SwiftData，可在业务阶段替换 LocalStore 实现，不影响业务层调用。
- 为保证当前沙箱内可构建，SwiftUI Preview 使用旧式 `PreviewProvider`，未使用 `#Preview` 宏。

## 验证

已通过构建：

```bash
xcodebuild -project ios/LeanMate.xcodeproj -scheme LeanMate -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/LeanMateDerivedData CODE_SIGNING_ALLOWED=NO build
```

说明：当前沙箱无法连接 CoreSimulatorService，会输出模拟器服务相关噪声，但 generic simulator 构建成功。

## 业务开发待启动

等待用户确认后再进入业务开发。建议业务开发启动时先从以下模块开始：

1. Onboarding / 登录占位
2. 用户档案填写
3. 首页
4. 体重记录
5. 手动饮食记录
6. 饮食记录确认页
7. AI 日报
