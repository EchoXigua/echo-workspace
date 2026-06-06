# LeanMate Workspace — AI 协作规范

本文件是项目内 AI 协作规范的主入口。Claude、Codex、Cursor 等工具都应以 `AGENTS.md` 为单一事实源。

## 项目概览

LeanMate（瘦搭）是一款专注减脂场景的 AI 陪伴式 App。V1.1 从一开始接入后端，先做 iOS，后续做 Android，产品做大后再考虑 Web 端。

| 目录 | 说明 | 技术栈 |
|------|------|--------|
| `ios/` | iOS 客户端 | Swift + SwiftUI |
| `android/` | Android 客户端 | Kotlin + Jetpack Compose |
| `server/` | 后端 API | Java 17 + Spring Boot 3.x |
| `web/` | 未来 Web 端 | React + TypeScript + Vite |
| `docs/` | 跨端共享文档 | PRD、架构、OpenAPI、数据字典 |
| `design/` | 产品设计稿 | Pencil `.pen` |

## 文档入口

- 产品需求：[docs/product/prd-v1.1.md](docs/product/prd-v1.1.md)
- 产品规划：[docs/product/roadmap.md](docs/product/roadmap.md)
- 总体架构：[docs/architecture/overview.md](docs/architecture/overview.md)
- 后端架构：[docs/architecture/backend.md](docs/architecture/backend.md)
- 领域模型：[docs/architecture/domain-model.md](docs/architecture/domain-model.md)
- API 契约：[docs/api/openapi.yaml](docs/api/openapi.yaml)
- 架构决策：[docs/architecture/decisions/](docs/architecture/decisions/)
- 项目状态：[docs/project-state.md](docs/project-state.md)

## LeanMate PRD 工作流

当用户提供新的 LeanMate PRD、版本规划、功能需求，或要求继续/恢复规划工作时，先读取项目内工作流：

- `.codex/skills/leanmate-prd-workflow/SKILL.md`
- `.codex/skills/leanmate-prd-workflow/references/document-map.md`
- `.codex/skills/leanmate-prd-workflow/references/version-workflow.md`

如果该 skill 已安装为全局 `$leanmate-prd-workflow`，优先使用全局 skill；否则按上述项目内文件执行同样流程。

每次结束重要规划工作前，都要更新 `docs/project-state.md`，让后续新对话可以从仓库状态恢复，而不是依赖聊天历史。

## LeanMate Git 提交规范

当用户要求提交代码、整理提交、检查 commit message、推送前检查，或提到 Git 提交规范时，先读取项目内提交规范 skill：

- `.codex/skills/leanmate-git-commit/SKILL.md`

如果该 skill 已安装为全局 `$leanmate-git-commit`，优先使用全局 skill；否则按上述项目内文件执行同样流程。

## 目录规范

- 跨端共享设计、接口、领域模型、技术决策放在 `docs/`。
- 后端工程运行、数据库、部署、AI Provider 等实现细节放在 `server/` 或 `server/docs/`。
- 各端专属编码规范放在对应目录的 `AGENTS.md`。
- `CLAUDE.md` 只作为 Claude 兼容入口，不维护重复规则。
- Cursor 规则放在 `.cursor/rules/`，只指向本文件和必要文档。

## 通用编码原则

### 语言

- 面向人看的文档一律使用中文，包括 PRD、架构、后端技术方案、ADR、README、项目状态、指标说明。
- 代码注释、commit message 使用中文。
- 代码标识符使用英文，遵循各端语言惯例。
- API 路径、字段名、schema 名使用英文；OpenAPI 的 `summary`、`description` 可以使用中文。

### 命名

- 命名要语义清晰，避免非通用缩写。
- 布尔变量优先使用 `is`、`has`、`can` 开头。
- 常量按各端惯例定义，不为了统一而破坏语言风格。

### 代码质量

- 不写无意义注释。
- 不添加超出当前任务范围的功能。
- 不引入不必要的抽象和过度设计。
- 优先复用已有工具函数和本地模式。
- 涉及跨端接口时，先更新 OpenAPI，再实现客户端和服务端。

### 安全

- 所有用户输入必须在边界处验证。
- 禁止在代码中硬编码密钥、密码、Token、AI API Key。
- 敏感配置通过环境变量或密钥管理服务注入。
- App 不直接调用 AI Provider，必须经过 LeanMate 后端。
- 日志中禁止输出手机号、Token、AI Key、用户隐私数据。

## 跨端接口约定

- REST API 路径使用 `/v1/...` 版本前缀。
- 资源使用复数名词。
- URL 路径全小写，单词用连字符分隔。
- 接口契约以 `docs/api/openapi.yaml` 为准。

统一响应格式：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

错误码约定：

- `0`：成功
- `400xx`：客户端请求错误
- `401xx`：认证失败
- `403xx`：权限不足
- `500xx`：服务端错误

时间约定：

- 接口传输使用 ISO 8601。
- 需要表示业务日期时使用 `YYYY-MM-DD`。
- 服务端存储时间统一使用 UTC。

## 各端规范入口

- `server/AGENTS.md`：后端专属规范
- `ios/AGENTS.md`：iOS 专属规范
- `android/AGENTS.md`：Android 专属规范
- `web/AGENTS.md`：Web 专属规范
