# 批次线程提示模板

## 主线程拆批检查清单

- 需求是否已经进入编码环节？
- 本批的业务目标是什么？
- 本批必须读取哪些项目文档？
- 本批允许修改哪些目录或模块？
- 本批明确不做什么？
- 当前工作区有哪些未提交改动不能碰？
- 完成后要跑哪些构建、测试或验证命令？
- 是否允许自动提交？

## 子线程启动提示模板

```text
请开始 LeanMate <版本/模块> 第 <N> 批 <批次名称> 编码开发。

开始前请读取：
- AGENTS.md
- <端或模块>/AGENTS.md
- docs/project-state.md
- <当前版本 PRD>
- <验收标准>
- docs/api/openapi.yaml
- <端侧架构/状态/设计映射/状态矩阵文档>

当前状态：
- 上一批已完成并提交：<commit hash> <commit message>
- 已完成范围：<简要列出>
- 当前工作区可能存在以下非本批未提交改动：<列出或说明先检查 git status>
- 这些非本批改动不要修改、暂存或提交。

本批范围：
1. <任务 1>
2. <任务 2>
3. <任务 3>

限制：
- 不要实现 <下一批功能>
- 不要新增 OpenAPI 之外接口
- 必须复用现有基础设施和组件
- 客户端不要自行计算服务端权威数据

完成后：
- 运行 <build command>
- 运行 <test/build-for-testing command>
- 更新必要状态文档：<docs/project-state.md 或状态矩阵>
- 不要自动提交，除非我明确要求提交
```

## 子线程完成回报模板

```text
第 <N> 批已完成。

完成范围：
- <摘要>

关键文件：
- <路径 1>
- <路径 2>

验证：
- <命令>：通过/失败
- <命令>：通过/失败

提交：
- <commit hash> <commit message>

遗留问题：
- <无或列出>

下一批建议：
- <建议>
```

## project-state 更新要点

`docs/project-state.md` 的更新应简洁，但要足以让新线程恢复：

- `Current Focus`：写清当前批次完成到哪里。
- `Completed Artifacts`：新增重要文件或模块。
- `Known Gaps`：删除已完成缺口，补充新发现缺口。
- `Recommended Next Steps`：列出下一批建议。
- `Resume Prompt`：提供下一批可直接复制的启动提示。
