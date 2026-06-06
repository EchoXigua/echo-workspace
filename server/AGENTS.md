# Server 后端 — AI 规范

> 继承顶层 `../AGENTS.md` 的全局规范，本文件为后端专属补充。

## 技术栈

- 语言：Java 17
- 框架：Spring Boot 3.x
- 构建：Maven
- 数据库：PostgreSQL
- 架构：模块化单体
- API 契约：OpenAPI，见 `../docs/api/openapi.yaml`

详细技术选型见 `docs/technology-selection.md`。V1.1 暂不引入 Redis 和 MQ，除非对应 ADR 被更新。

进入编码阶段前先读 `docs/development-readiness.md`。

## 开发前置流程

每个后端需求进入实现前，先确认对应技术方案：

```text
PRD -> server/docs/technical-design/ -> docs/api/openapi.yaml -> 实现
```

- 技术方案规范：`docs/technical-design/README.md`
- 技术方案模板：`docs/technical-design/template.md`
- V1.1 方案索引：`docs/technical-design/v1.1/README.md`

如果需求会影响客户端调用，必须先更新 OpenAPI，再开始联调。

## 目录结构约定

```text
server/
└── src/main/java/com/leanmate/
    ├── common/
    ├── user/
    ├── diet/
    ├── weight/
    ├── stats/
    ├── report/
    ├── retention/
    └── ai/
```

每个业务模块内部按需拆分：

```text
module/
├── controller
├── application
├── domain
├── repository
└── dto
```

不要在根目录建立巨大的全局 `service/`、`model/`、`utils/` 包。

## 分层职责

- `controller`：HTTP 入参、鉴权上下文、返回 DTO。
- `application`：用例编排和事务边界。
- `domain`：业务规则、状态流、核心计算。
- `repository`：数据库读写。
- `dto`：请求和响应对象。
- `common`：跨模块基础设施，不放业务规则。

## 编码规范

- Controller 类以 `Controller` 结尾。
- 应用服务以 `ApplicationService` 或具体用例命名，避免空泛的 `XxxServiceImpl`。
- DTO 以 `Request`、`Response`、`DTO` 结尾。
- 业务异常通过全局异常处理器转换为统一响应。
- 参数校验使用 `@Valid` / `@Validated`。
- 数据库查询使用参数化，禁止字符串拼接 SQL。

## 安全

- 密码必须哈希存储，优先使用 BCrypt。
- AI API Key 只能保存在后端环境变量或密钥管理服务。
- 用户只能访问自己的饮食、体重、日报和统计数据。
- 图片上传必须限制大小、类型和访问权限。

## 常用命令

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
mvn spring-boot:run
mvn test
mvn package
```
