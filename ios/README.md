# LeanMate iOS

LeanMate iOS 客户端。V1.1 先以 iPhone App 为主，最低兼容 iOS 17。

## 文档

- 开发就绪说明：[docs/development-readiness.md](docs/development-readiness.md)
- iOS 架构设计：[docs/architecture.md](docs/architecture.md)
- iOS 编码规范：[docs/coding-style.md](docs/coding-style.md)
- API 与 Mock 策略：[docs/api-mock-strategy.md](docs/api-mock-strategy.md)
- 设计稿：`design/app/LeanMateV1.0.pen`、`design/app/LeanMateV1.0-shikaka.pen`
- API 契约：`docs/api/openapi.yaml`
- iOS AI 规范：[AGENTS.md](AGENTS.md)

## 常用命令

iOS 工程初始化后补充。

```bash
xcodebuild -scheme LeanMate -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme LeanMate -destination 'platform=iOS Simulator,name=iPhone 15'
```
