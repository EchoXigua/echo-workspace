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

## 交互改动自测

- 涉及页面切换、Tab、手势、动画、滚动、Sheet、Loading/Empty/Error 状态的 iOS 交互改动，完成代码后必须优先使用 XcodeBuildMCP 在模拟器上 `build_run_sim`，并通过 UI snapshot、tap、swipe、screenshot 等工具实际验证关键路径。
- 不要只用 `swiftc -parse`、`git diff --check` 或普通构建结果替代交互自测；这些只能作为补充验证。
- 验证范围至少覆盖本次改动直接影响的入口、点击/滑动/返回路径，以及 Loading 到 Loaded/Error/Empty 的关键状态切换。
- 如果 XcodeBuildMCP 不可用、模拟器不可用或构建被环境问题阻塞，最终回复必须明确说明没有完成模拟器交互自测、阻塞原因，以及已完成的替代检查。

## 常用命令

```bash
# 待 iOS 工程初始化后补充
xcodebuild -scheme LeanMate -destination 'platform=iOS Simulator' build
xcodebuild test -scheme LeanMate
```
