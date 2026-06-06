---
name: leanmate-git-commit
description: 当用户要求为 LeanMate/瘦搭项目创建、整理、检查、改写 Git commit，或提到提交规范、commit message、git 提交、分批提交、拆分提交、push 前检查时使用。该 skill 定义项目统一的中文 Conventional Commits 提交格式、按功能分组分批提交规则、提交前检查流程和禁止事项。
---

# LeanMate Git 提交规范

## 适用场景

用户要求提交代码、生成 commit message、检查提交是否规范、整理 staged changes、推送前检查时，必须使用本规范。

## 提交前检查

1. 确认 Git 根目录是项目根目录：
   - `git rev-parse --show-toplevel`
2. 查看工作区状态：
   - `git status --short`
3. 如果工作区包含多个功能、多个任务或跨阶段变更，先按功能边界拆分为多个提交批次。
4. 只提交与当前批次相关的文件，不顺手纳入无关变更。
5. 提交前查看 staged diff：
   - `git diff --cached --stat`
   - 需要确认细节时读 `git diff --cached`
6. 如果涉及代码变更，优先运行对应测试或说明未运行原因。
7. 禁止提交真实密钥、真实 `.env`、构建产物、依赖缓存和 IDE 临时文件。

## 变更分组与分批提交

当用户说“提交一下”但工作区存在多类变更时，默认自动分批提交，不要把所有文件一次性提交。

分组判断顺序：

1. 先按用户明确提到的批次分组，例如“上一轮 skill”和“这一轮基础设施”。
2. 再按功能边界分组，例如后端基础设施、iOS 页面、文档、构建配置、测试。
3. 再按目录和职责分组，但同一功能的代码、配置、测试和必要文档可以放在同一提交里。
4. 如果单个文件同时包含多个批次内容，优先用部分暂存拆分；如果拆分风险高，先向用户说明并选择最小混合范围。

每个批次都要单独执行：

```bash
git add <本批次文件>
git diff --cached --stat
git diff --cached
git commit -m "<type>(<scope>): <中文摘要>"
```

典型拆分示例：

- 新增或优化提交规范 skill：`chore(git): 添加 LeanMate 提交规范 skill`
- 后端通用基础设施：`feat(server): 添加后端通用基础设施`
- 纯项目状态更新：`docs(docs): 更新项目状态`

## Commit Message 格式

使用中文 Conventional Commits：

```text
<type>(<scope>): <summary>
```

- `type` 必须小写英文。
- `scope` 使用小写英文目录或模块名，可省略。
- `summary` 使用中文，简洁说明本次变更，末尾不加句号。
- 单行不超过 72 个字符。

示例：

```text
feat(server): 初始化 Spring Boot 后端工程
docs(product): 更新 V1.1 项目状态
chore(git): 添加 LeanMate 提交规范 skill
fix(server): 修正 Flyway 迁移约束
test(server): 补充应用上下文测试
```

## Type 取值

- `feat`：新增用户可见功能、业务能力或主要工程能力。
- `fix`：修复缺陷、错误配置或不符合预期的行为。
- `docs`：只改文档、说明、ADR、PRD、OpenAPI 文档文本。
- `style`：格式、排版、代码风格，不改变行为。
- `refactor`：重构，不新增功能也不修复缺陷。
- `test`：新增或修改测试。
- `chore`：构建、依赖、脚手架、工具、仓库维护。
- `ci`：CI/CD 配置。
- `perf`：性能优化。
- `revert`：回滚提交。

## Scope 建议

优先使用顶层目录或明确模块：

- `server`
- `ios`
- `android`
- `web`
- `docs`
- `design`
- `api`
- `git`
- `workflow`

跨多个范围且难以归一时可以省略 scope：

```text
chore: 初始化 LeanMate 工作区
```

## 正文和破坏性变更

普通提交只写标题即可。需要解释背景时添加正文：

```text
feat(server): 初始化后端数据库迁移

拆分 V1.1 数据库设计为 Flyway V1-V6 脚本，支持从空库创建 schema。
```

破坏性变更必须在正文标明：

```text
BREAKING CHANGE: 说明不兼容影响和迁移方式。
```

## 禁止事项

- 禁止使用无语义提交：`update`、`fix bug`、`wip`、`修改`、`提交代码`。
- 禁止把多个无关任务塞进一个提交。
- 禁止提交真实 `.env.local`、`.env.dev`、`.env.prod`。
- 禁止提交 `target/`、`.m2/`、`DerivedData/`、`node_modules/`。
- 禁止在 commit message 中写密钥、Token、内部账号或隐私数据。

## 推荐提交流程

```bash
git status --short
git add <files>
git diff --cached --stat
git diff --cached
git commit -m "<type>(<scope>): <中文摘要>"
```

如果用户只说“提交一下”，先根据 staged diff 生成符合规范的 commit message；若没有 staged 内容，再根据当前任务选择应提交文件。
