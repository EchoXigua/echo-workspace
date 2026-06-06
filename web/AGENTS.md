# Web 前端 — AI 规范

> 继承顶层 `../AGENTS.md` 的全局规范，本文件为 Web 专属补充。

## 技术栈

- 框架：React 19
- 语言：TypeScript 严格模式
- 构建：Vite
- 包管理：pnpm

## 目录结构约定

```text
web/
├── src/
│   ├── api/
│   ├── assets/
│   ├── components/
│   ├── hooks/
│   ├── pages/
│   ├── stores/
│   ├── types/
│   └── utils/
```

## 编码规范

- 禁止随意使用 `any`，确实需要时用 `unknown` + 类型守卫。
- 优先用 `interface` 定义对象类型，`type` 用于联合/交叉类型。
- 组件 Props 类型名为 `XxxProps`。
- 组件使用函数式组件 + Hooks。
- 文件名与组件名一致，使用 PascalCase。
- 自定义 Hook 以 `use` 开头。
- 避免不必要的 `useEffect`，优先使用事件处理和派生状态。

## 样式

样式方案待 Web 工程初始化时确定。确定前不要同时混用多套方案。

## 常用命令

```bash
# 待 Web 工程初始化后补充
pnpm dev
pnpm build
pnpm preview
pnpm lint
```
