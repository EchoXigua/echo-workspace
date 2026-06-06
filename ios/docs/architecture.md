# LeanMate V1.1 iOS 架构设计

## 架构目标

iOS 架构要支持：

- 按设计稿快速实现 V1.1。
- 在后端未完成时用 Mock 并行开发。
- 后端完成后平滑切换真实 API。
- 保持页面、业务状态、网络、存储边界清晰。

## 技术栈

- Swift。
- SwiftUI。
- Swift Concurrency。
- SwiftData 用于本地草稿和待同步记录。
- Keychain 用于 Token。
- URLSession 封装网络层。
- Swift Package Manager 管理依赖。

## 目录结构

```text
ios/LeanMate/
├── App/
│   ├── LeanMateApp.swift
│   ├── AppEnvironment.swift
│   └── AppRouter.swift
├── Core/
│   ├── API/
│   ├── Auth/
│   ├── DesignSystem/
│   ├── Persistence/
│   ├── Security/
│   ├── Utilities/
│   └── Mock/
├── Features/
│   ├── Onboarding/
│   ├── Profile/
│   ├── Home/
│   ├── Diet/
│   ├── Weight/
│   └── Report/
├── Components/
├── Resources/
└── PreviewSupport/
```

## 分层职责

### View

- 只负责 UI 和用户交互。
- 不直接调用 URLSession。
- 不直接读写 Keychain。
- 不写业务计算。

### ViewModel

- 管理页面状态。
- 调用 UseCase 或 API Client。
- 处理 Loading/Empty/Error。
- 使用 `@Observable`，iOS 17 起优先使用 Observation。

### API Client

- 封装 HTTP 请求。
- 负责 request/response DTO。
- 处理 token 注入。
- 将服务端错误转换为 App 错误。

### Repository

V1.1 可以轻量使用，不强行引入复杂 Clean Architecture。

适合 Repository 的场景：

- 需要在真实 API 和 Mock API 之间切换。
- 需要组合本地草稿和远端数据。
- 需要统一处理缓存或待同步队列。

### Local Store

- 保存本地草稿。
- 保存待同步体重或饮食记录。
- 不作为跨端数据真相来源。

## Feature 拆分

### Onboarding

- 登录入口。
- 登录状态判断。
- 首次进入引导到用户档案。

### Profile

- 性别、年龄、身高、当前体重、目标体重、活动水平。
- 提交后展示后端计算的 BMI、BMR、推荐热量。

### Home

- 今日目标热量。
- 已摄入热量。
- 剩余热量。
- 当前体重。
- 连续打卡。
- 今日饮食记录。
- AI 日报摘要。

### Diet

- 拍照记录。
- 文本记录。
- 手动记录。
- AI 识别任务状态。
- 食物项确认和编辑。

### Weight

- 体重记录。
- 7 天和 30 天趋势。

### Report

- AI 日报详情。
- 查看状态上报。

## 状态管理

页面状态统一使用类似结构：

```swift
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)
}
```

表单状态放在 ViewModel 中，View 只绑定字段。

## 错误处理

统一错误类型：

- 网络不可用。
- 未登录。
- 参数错误。
- 无权限。
- 资源不存在。
- AI 服务失败。
- 服务端错误。

UI 呈现：

- 表单校验错误显示在字段附近。
- 网络和服务端错误使用 banner/toast 或页面错误状态。
- AI 识别失败时允许切换手动录入。

## 本地草稿和离线

V1.1 不做复杂离线同步。

需要支持：

- 手动饮食草稿。
- 体重记录提交失败后的待同步。
- AI 识别失败后保留用户输入。

后端仍是主数据源。重新进入页面时优先拉后端数据，再合并本地草稿。

## 依赖注入

V1.1 使用轻量环境对象：

```swift
struct AppEnvironment {
    var apiClient: APIClient
    var authStore: AuthStore
    var localStore: LocalStore
}
```

不要一开始引入复杂 DI 框架。

## 预览和 Mock

每个主要页面应提供 SwiftUI Preview。

Preview 使用：

- Mock API Client。
- 固定样例数据。
- Loading/Empty/Error 多状态。

## 不做范围

- V1.1 不接 Apple Health。
- V1.1 不做复杂离线同步冲突解决。
- V1.1 不直接接 AI Provider。
- V1.1 不做 iPad 专门适配。
