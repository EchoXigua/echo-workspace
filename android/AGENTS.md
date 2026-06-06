# Android — AI 规范

> 继承顶层 `../AGENTS.md` 的全局规范，本文件为 Android 专属补充。

## 技术栈

- 语言：Kotlin
- UI 框架：Jetpack Compose 优先
- 构建：Gradle Kotlin DSL
- 依赖注入：Hilt

## 目录结构约定

```text
android/
└── app/src/main/java/com/leanmate/
    ├── ui/
    │   └── feature/
    ├── data/
    │   ├── repository/
    │   ├── remote/
    │   └── local/
    ├── domain/
    └── core/
```

## 架构规范

- 采用 MVVM + Clean Architecture。
- ViewModel 不持有 View 引用。
- 异步使用 Flow + coroutines。
- App 端可以保存本地草稿，但跨端数据以后端为准。
- App 不直接调用 AI Provider。

## 安全

- 敏感数据使用 EncryptedSharedPreferences 或 Keystore。
- 网络通信强制 HTTPS。
- 关键接口后续可考虑证书固定。
- 生产环境关闭详细日志，不输出敏感信息。

## 常用命令

```bash
# 待 Android 工程初始化后补充
./gradlew assembleDebug
./gradlew test
./gradlew connectedTest
```
