# LeanMate 后端环境配置

## 目标

本文定义后端本地开发、联调、生产所需环境变量。后端编码阶段应同步维护不同环境的示例文件：

- `server/.env.local.example`：本地开发。
- `server/.env.dev.example`：联调环境。
- `server/.env.prod.example`：生产环境占位示例。

真实环境文件不提交 git。本地可以复制为 `.env.local` 使用；联调和生产优先由部署平台或密钥管理服务注入环境变量。

## 环境划分

- `local`：本地开发。
- `dev`：联调环境。
- `prod`：生产环境。

## 基础配置

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `APP_ENV` | 是 | `local` | 运行环境 |
| `SERVER_PORT` | 是 | `8080` | 服务端口 |
| `APP_PUBLIC_BASE_URL` | 否 | `http://localhost:8080` | 后端公开访问地址 |

## 数据库

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `DB_URL` | 是 | `jdbc:postgresql://localhost:5432/leanmate` | PostgreSQL JDBC URL |
| `DB_USERNAME` | 是 | `leanmate` | 数据库用户名 |
| `DB_PASSWORD` | 是 | `leanmate_dev_password` | 数据库密码 |
| `FLYWAY_ENABLED` | 是 | `true` | 是否启用迁移 |

## JWT 和安全

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `JWT_ISSUER` | 是 | `leanmate` | JWT 签发方 |
| `JWT_SECRET` | 是 | `change-me` | 本地开发密钥，生产必须使用强密钥 |
| `JWT_ACCESS_TOKEN_TTL_SECONDS` | 是 | `3600` | Access Token 有效期 |
| `JWT_REFRESH_TOKEN_TTL_DAYS` | 是 | `30` | Refresh Token 有效期 |

## 第三方登录

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `APPLE_CLIENT_ID` | iOS 登录需要 | `app.leanmate.ios` | Apple 登录 client id |
| `APPLE_TEAM_ID` | iOS 登录需要 | `TEAMID` | Apple Team ID |
| `APPLE_KEY_ID` | iOS 登录需要 | `KEYID` | Apple Key ID |
| `APPLE_PRIVATE_KEY` | iOS 登录需要 | `-----BEGIN PRIVATE KEY-----...` | Apple 私钥，生产使用密钥管理 |

## 对象存储

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `STORAGE_PROVIDER` | 是 | `s3` | 对象存储类型 |
| `STORAGE_ENDPOINT` | 是 | `http://localhost:9000` | S3 兼容 endpoint |
| `STORAGE_BUCKET` | 是 | `leanmate-dev` | bucket 名称 |
| `STORAGE_ACCESS_KEY` | 是 | `minio` | access key |
| `STORAGE_SECRET_KEY` | 是 | `minio_password` | secret key |
| `STORAGE_PUBLIC_BASE_URL` | 否 | `http://localhost:9000/leanmate-dev` | 图片访问基础 URL |

## AI Provider

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `AI_PROVIDER` | 否 | `placeholder` | 兼容旧配置的默认 Provider，不作为长期全局模型选择 |
| `AI_API_KEY` | 否 | `sk-...` | 兼容旧配置的默认 AI API Key |
| `AI_BASE_URL` | 否 | `https://api.example.com` | 兼容旧配置的默认 base URL |
| `AI_DIET_PHOTO_PROVIDER` | 是 | `placeholder` | 饮食图片识别 Provider，DeepSeek 当前不用于图片识别 |
| `AI_DIET_TEXT_PROVIDER` | 是 | `deepseek` | 饮食文本解析 Provider |
| `AI_DAILY_REPORT_PROVIDER` | 是 | `deepseek` | AI 日报 Provider |
| `DEEPSEEK_API_KEY` | 文本/日报启用时必填 | `sk-...` | DeepSeek API Key |
| `DEEPSEEK_BASE_URL` | 否 | `https://api.deepseek.com` | DeepSeek API base URL |
| `AI_DIET_PHOTO_MODEL` | 是 | `change-me` | 饮食图片识别模型，待确认 |
| `AI_DIET_TEXT_MODEL` | 是 | `deepseek-v4-flash` | 饮食文本解析模型 |
| `AI_DAILY_REPORT_MODEL` | 是 | `deepseek-v4-flash` | AI 日报模型 |
| `AI_REQUEST_TIMEOUT_SECONDS` | 是 | `30` | AI 请求超时 |
| `AI_DAILY_REPORT_RETRY_LIMIT` | 是 | `1` | 日报生成重试次数 |

## 限制配置

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `MAX_UPLOAD_IMAGE_SIZE_MB` | 是 | `8` | 饮食图片最大大小 |
| `DAILY_AI_RECOGNITION_LIMIT` | 是 | `30` | 单用户每日识别次数 |
| `DAILY_REPORT_GENERATE_LIMIT` | 是 | `3` | 单用户每日手动生成日报次数 |

## 日志

| 变量 | 必需 | 示例 | 说明 |
|------|------|------|------|
| `LOG_LEVEL` | 是 | `INFO` | 日志级别 |
| `LOG_SQL` | 否 | `false` | 是否输出 SQL |
| `ACCESS_LOG_ENABLED` | 是 | `true` | 是否输出接口访问日志 |
| `ACCESS_LOG_INCLUDE_QUERY_KEYS` | 是 | `true` | 接口访问日志是否记录 query 参数名，不记录参数值 |
| `ACCESS_LOG_SLOW_THRESHOLD_MS` | 是 | `1000` | 慢请求阈值，访问日志输出 `slow=true` |
| `AI_CALL_LOG_ENABLED` | 是 | `true` | 是否写入 AI 模型调用审计表 |
| `AI_CALL_LOG_SAVE_DEBUG_PAYLOAD` | 是 | `false` | 是否保存脱敏 debug payload；当前实现不保存正文，生产禁止默认开启 |

## 安全要求

- `.env`、`.env.local`、`.env.dev`、`.env.prod` 不提交 git。
- `server/.env.*.example` 只放占位值。
- 生产密钥使用环境变量或密钥管理服务。
- 日志中禁止输出 Token、AI API Key、手机号、Apple 私钥。
