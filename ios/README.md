# LeanMate iOS

LeanMate iOS 客户端。V1.1 先以 iPhone App 为主，最低兼容 iOS 17。

## 文档

- 开发就绪说明：[docs/development-readiness.md](docs/development-readiness.md)
- iOS 架构设计：[docs/architecture.md](docs/architecture.md)
- iOS 编码规范：[docs/coding-style.md](docs/coding-style.md)
- API 与 Mock 策略：[docs/api-mock-strategy.md](docs/api-mock-strategy.md)
- 基础设施状态：[docs/infrastructure-status.md](docs/infrastructure-status.md)
- 设计稿画面映射：[docs/design-screen-map.md](docs/design-screen-map.md)
- V1.1 iOS 状态矩阵：[docs/v1.1-state-matrix.md](docs/v1.1-state-matrix.md)
- V1.1 验收标准与业务边界：`docs/product/v1.1-acceptance-criteria.md`
- 设计稿唯一准稿：`design/app/LeanMateV1.0-shikaka.pen`
- API 契约：`docs/api/openapi.yaml`
- iOS AI 规范：[AGENTS.md](AGENTS.md)

## 常用命令

```bash
xcodebuild -project ios/LeanMate.xcodeproj -scheme LeanMate -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/LeanMateDerivedData CODE_SIGNING_ALLOWED=NO build
```

```bash
xcodebuild -project ios/LeanMate.xcodeproj -scheme LeanMate -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/LeanMateTestDerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

```bash
xcodebuild -project ios/LeanMate.xcodeproj -scheme LeanMate -configuration Debug -destination 'platform=iOS Simulator,name=<available simulator>' -derivedDataPath /private/tmp/LeanMateTestDerivedData CODE_SIGNING_ALLOWED=NO test
```
