# LeanMate V1.1 iOS API 与 Mock 策略

## 目标

让 iOS 在后端未完全实现时，也可以基于 OpenAPI 和设计稿并行开发。

## 接口契约

唯一接口契约：

- `docs/api/openapi.yaml`

iOS 不以口头约定或临时 JSON 为准。如果接口需要调整，先更新 OpenAPI。

## DTO 命名

DTO 与 OpenAPI schema 对齐：

- `AuthToken`
- `CurrentUser`
- `UserProfile`
- `TodayHome`
- `RecognitionTask`
- `FoodEntry`
- `WeightEntry`
- `DailyReport`
- `Streak`

Swift 类型使用 PascalCase，字段用 camelCase。

## API Client 协议

建议先定义协议：

```swift
protocol APIClient {
    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken
    func currentUser() async throws -> CurrentUser
    func profile() async throws -> ProfilePayload
    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload
    func todayHome(date: Date?) async throws -> TodayHome
    func saveWeight(_ request: SaveWeightEntryRequest) async throws -> WeightEntrySaveResult
    func dietEntries(date: Date) async throws -> [FoodEntry]
    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult
    func dailyReport(date: Date) async throws -> DailyReport?
}
```

后续按页面需要补充接口。

## 实现分类

### MockAPIClient

用于：

- SwiftUI Preview。
- 后端未完成时页面开发。
- UI 状态测试。

要求：

- 覆盖成功、空状态、错误状态。
- 模拟 AI 识别 running/succeeded/failed。
- 模拟未完成档案状态。

### LiveAPIClient

用于真实后端。

职责：

- 拼接 base URL。
- 注入 Bearer Token。
- 编码请求。
- 解码统一响应。
- 处理错误码。
- 遇到 401 时触发刷新 token 或退出登录。

## Mock 数据文件

建议放置：

```text
ios/LeanMate/PreviewSupport/MockData/
├── today-home.json
├── food-entries.json
├── recognition-task-succeeded.json
├── recognition-task-failed.json
├── daily-report.json
└── profile.json
```

Mock JSON 字段必须和 OpenAPI 保持一致。

## 错误码映射

| 服务端 code | iOS 错误 |
|-------------|----------|
| `40001` | 参数错误 |
| `40101` | 未登录或登录过期 |
| `40301` | 无权限 |
| `40401` | 资源不存在 |
| `40901` | 状态冲突 |
| `50001` | 服务端错误 |
| `50010` | AI 服务失败 |

## Token 策略

- Access Token 保存在 Keychain。
- Refresh Token 保存在 Keychain。
- 请求时自动注入 Access Token。
- Access Token 过期时尝试刷新。
- 刷新失败则清理登录态。

## 并行开发方式

1. iOS 根据 OpenAPI 定义 DTO 和 APIClient 协议。
2. iOS 先实现 MockAPIClient。
3. 页面开发使用 MockAPIClient。
4. 后端接口完成后，实现 LiveAPIClient。
5. 用同一套 ViewModel 切换 Mock/Live。

## 待确认问题

- 是否使用 OpenAPI 代码生成工具，还是 V1.1 先手写 DTO。
- Mock JSON 是否由 OpenAPI 示例生成。
- 后端 dev 环境域名。
