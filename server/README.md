# LeanMate Server

LeanMate 后端 API 服务。V1.1 从一开始接入后端，作为 iOS、Android 和未来 Web 的统一业务入口。

## 文档

- 技术选型：[docs/technology-selection.md](docs/technology-selection.md)
- 数据库设计：[docs/database-design.md](docs/database-design.md)
- AI Provider 方案：[docs/ai-provider.md](docs/ai-provider.md)
- 环境配置：[docs/env-config.md](docs/env-config.md)
- 开发就绪说明：[docs/development-readiness.md](docs/development-readiness.md)
- V1.1 后端接口文档：[docs/v1.1-api-reference.md](docs/v1.1-api-reference.md)
- 本地环境变量示例：[.env.local.example](.env.local.example)
- 联调环境变量示例：[.env.dev.example](.env.dev.example)
- 生产环境变量示例：[.env.prod.example](.env.prod.example)
- 后端技术方案规范：[docs/technical-design/README.md](docs/technical-design/README.md)
- 后端技术方案检查清单：[docs/technical-design/checklist.md](docs/technical-design/checklist.md)
- V1.1 后端技术方案索引：[docs/technical-design/v1.1/README.md](docs/technical-design/v1.1/README.md)
- V1.1 API 设计说明：[docs/technical-design/v1.1/api-design.md](docs/technical-design/v1.1/api-design.md)
- 跨端后端架构：[../docs/architecture/backend.md](../docs/architecture/backend.md)
- 领域模型：[../docs/architecture/domain-model.md](../docs/architecture/domain-model.md)
- API 契约：[../docs/api/openapi.yaml](../docs/api/openapi.yaml)
- 后端 AI 规范：[AGENTS.md](AGENTS.md)

## 常用命令

要求本地安装 JDK 17 和 Maven 3.9+。

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
cp .env.local.example .env.local
set -a
source .env.local
set +a
mvn spring-boot:run
mvn test
mvn package
```

## 本地数据库

```bash
docker compose --env-file .env.local.example up -d postgres
```

本地 Postgres 默认使用独立的 `leanmate` Compose 项目、`leanmate-postgres` 容器、`leanmate_postgres_data` 数据卷，并映射到宿主机 `5433` 端口，避免和其他项目的 `5432` 数据库冲突。

应用启动时会通过 Flyway 执行 `src/main/resources/db/migration/` 下的数据库迁移脚本。
