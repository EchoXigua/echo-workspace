# iOS — AI 规范

> 继承顶层 `../AGENTS.md` 的全局规范，本文件为 iOS 专属补充。

## 技术栈

- 语言：Swift
- UI 框架：SwiftUI 优先，复杂交互场景可使用 UIKit
- 依赖管理：Swift Package Manager
- 最低系统版本：iOS 17
- 本地持久化：SwiftData 优先，用于本地草稿和待同步记录
- 网络：URLSession 封装
- 安全存储：Keychain

## 目录结构约定

```text
ios/
└── LeanMate/
    ├── App/
    ├── Features/
    │   └── FeatureName/
    │       ├── View/
    │       ├── ViewModel/
    │       └── Model/
    ├── Core/
    ├── Components/
    └── Resources/
```

## 架构规范

- 采用 MVVM。
- View 只负责 UI，不包含业务逻辑。
- iOS 17 优先使用 `@Observable`。
- 异步逻辑优先使用 `async/await`。
- App 端可以保存本地草稿，但跨端数据以后端为准。
- App 不直接调用 AI Provider。
- API 契约以仓库根目录下的 `docs/api/openapi.yaml` 为准。
- 编码规范见 `docs/coding-style.md`。
- 开发就绪说明见 `docs/development-readiness.md`。

## 安全

- Token、密码等敏感数据存储在 Keychain。
- 不用 UserDefaults 保存敏感数据。
- 网络请求使用 HTTPS。
- 日志中不输出用户隐私和认证信息。

## 常用命令

```bash
# 待 iOS 工程初始化后补充
xcodebuild -scheme LeanMate -destination 'platform=iOS Simulator' build
xcodebuild test -scheme LeanMate
```
