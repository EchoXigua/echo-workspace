# LeanMate iOS 编码规范

## 参考来源

本规范参考：

- Swift 官方 API Design Guidelines。
- Airbnb Swift Style Guide。
- SwiftLint 常用规则。

本项目不逐条照搬外部规范，而是提炼适合 LeanMate V1.1 的可执行规则。

## 基本原则

- 代码优先清晰，不追求炫技。
- 类型、方法、属性命名遵循 Swift 官方 API 设计习惯。
- UI 代码和业务逻辑分离。
- 异步代码使用 Swift Concurrency。
- 不直接在 View 中写网络请求、Keychain、复杂计算。
- 最低兼容 iOS 17，优先使用 iOS 17 原生能力。

## 命名

### 类型

类型使用 PascalCase：

```swift
struct TodayHomeView: View {}
final class LiveAPIClient {}
enum AppError: Error {}
```

### 方法和属性

方法、属性使用 lowerCamelCase：

```swift
let dailyCalorieTargetKcal: Int
func fetchTodayHome() async throws -> TodayHome
```

### 布尔值

布尔属性优先使用 `is`、`has`、`can`、`should`：

```swift
let isLoading: Bool
let hasUserEdited: Bool
let canSubmit: Bool
```

### 缩写

只使用通用缩写，例如：

- `id`
- `url`
- `api`
- `dto`

不要使用只有自己懂的缩写。

## 文件组织

每个文件优先只放一个主要类型。

推荐顺序：

```swift
import SwiftUI

struct ExampleView: View {
    // body
}

private extension ExampleView {
    // 私有子视图或计算属性
}

#Preview {
    ExampleView()
}
```

ViewModel 文件：

```swift
import Foundation

@Observable
final class ExampleViewModel {
    // State
    // Dependencies
    // Init
    // Actions
    // Private helpers
}
```

## SwiftUI

- View 保持轻量。
- 超过 150 行的 View 优先拆子 View。
- 复杂条件渲染拆成私有 computed View。
- 不在 View 的 `body` 中直接创建复杂业务对象。
- Preview 必须使用 Mock 数据。
- 页面需要覆盖 Loading、Empty、Error、Loaded 状态。

示例：

```swift
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    var body: some View {
        content
            .task {
                await viewModel.load()
            }
    }
}
```

## ViewModel

- iOS 17 优先使用 `@Observable`。
- ViewModel 负责页面状态和用户动作。
- ViewModel 不直接持有 SwiftUI View。
- ViewModel 不直接读写 Keychain。
- ViewModel 不直接使用 URLSession。
- 依赖通过初始化传入。

示例：

```swift
@Observable
final class HomeViewModel {
    private let apiClient: APIClient
    private(set) var state: Loadable<TodayHome> = .idle

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await apiClient.todayHome(date: nil))
        } catch {
            state = .failed(AppError(error))
        }
    }
}
```

## 并发

- 使用 `async/await`。
- UI 状态更新在 MainActor。
- 长任务不要阻塞主线程。
- 不使用 callback pyramid。
- V1.1 不引入 RxSwift。

建议：

```swift
@MainActor
@Observable
final class ProfileViewModel {
    // ...
}
```

## 错误处理

- 不吞错误。
- 不直接展示底层错误文案给用户。
- 网络层将服务端错误码转换为 `AppError`。
- UI 根据 `AppError` 展示可理解文案。

```swift
enum AppError: Error {
    case unauthorized
    case validation(message: String)
    case aiServiceUnavailable
    case networkUnavailable
    case unknown
}
```

## API DTO

- DTO 字段和 OpenAPI 保持一致。
- DTO 不放 UI 逻辑。
- 需要 UI 展示转换时，使用 ViewModel 或专门 mapper。
- 日期解析统一在网络层处理。

## 安全

- Token 只放 Keychain。
- 不用 UserDefaults 存敏感数据。
- 不在日志中输出 Token、手机号、AI 相关敏感内容。
- App 不直接调用 AI Provider。

## 本地持久化

- V1.1 只保存本地草稿和待同步记录。
- 后端是主数据源。
- 不做复杂多端冲突解决。

## 代码格式

建议使用 SwiftLint。基础规则：

- 4 空格缩进。
- 行宽建议 120，超过时主动换行。
- 避免强制解包。
- 避免隐式展开可选值。
- 避免过长函数和过大类型。
- 不保留未使用代码。

## 禁止事项

- 禁止在 View 中直接发网络请求。
- 禁止硬编码 Token、API Key、AI Key。
- 禁止把 Mock 数据写死在生产代码路径。
- 禁止为了未来功能引入复杂抽象。
- 禁止绕过 OpenAPI 自定义接口字段。

## 参考链接

- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/
- Airbnb Swift Style Guide: https://github.com/airbnb/swift
- SwiftLint: https://github.com/realm/SwiftLint
