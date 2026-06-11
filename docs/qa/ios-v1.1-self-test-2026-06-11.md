# iOS V1.1 真实后端业务自测记录

日期：2026-06-11

## 测试范围

- iOS Debug 构建，后端指向 `http://127.0.0.1:8080`。
- 后端使用本地 Spring Boot + Docker PostgreSQL，数据库为真实写入。
- 登录使用 Debug 本地登录按钮，身份 token 为 `mock:selftest-20260611131100:selftest2@leanmate.local`。
- mock 仅发生在后端本地环境的 Apple identity 校验；账号、JWT、用户档案、饮食、体重、日报、连续打卡都走真实后端和数据库。
- 设计核对来源：`design/app/LeanMateV1.0-shikaka.pen` 与 `ios/docs/design-screen-map.md`。

## 通过的流程

1. 本地登录
   - 点击 Debug 本地登录后进入档案填写。
   - 数据库已生成真实用户和 `user_auth_identities` 记录。
   - 登录返回真实 access token / refresh token，`profileCompleted=false` 时路由到档案填写。

2. 档案填写
   - 填写：女、30 岁、165 cm、当前体重 60 kg、目标体重 55 kg、轻度活动。
   - `PUT /v1/profile` 保存成功。
   - 后端返回并落库：BMI 22.04、BMR 1320、每日目标 1520 kcal。
   - 保存后可进入首页。

3. 首页
   - 初始首页显示 `已摄入0 / 目标1520`。
   - 手动饮食保存后首页刷新为 `已摄入89 / 目标1520`，剩余 1431 kcal，营养素同步刷新。
   - 删除一条饮食记录后首页刷新，已删除记录不再展示。

4. 饮食记录
   - 记录页三种入口存在：拍照识别、文本识别、手动记录。
   - 手动记录 `banana`，100 g，89 kcal，蛋白 1.1 g，脂肪 0.3 g，碳水 23 g。
   - `POST /v1/diet/entries` 保存成功，数据库 `food_entries` 和 `food_items` 均有真实数据。

5. 删除回算
   - 通过真实 `DELETE /v1/diet/entries/{id}` 删除文本识别生成的 0 kcal 记录。
   - 删除后数据库记录状态为 `deleted`。
   - `daily_nutrition_snapshots` 回算为 1 餐、89 kcal、体重 59.50 kg。
   - App 返回首页后也只展示剩余有效午餐 `banana`。

6. 体重记录
   - 记录页切换到体重 Sheet，输入 59.5 kg。
   - `POST /v1/weights` 保存成功。
   - 数据库 `weight_entries` 与 `daily_nutrition_snapshots.weight_kg` 均写入 59.50。

7. AI 日报
   - 日报空态可进入生成。
   - `POST /v1/reports/daily` 生成成功，页面显示 89 分、2 餐、89 kcal、关键问题和建议。
   - 数据库 `daily_ai_reports.status=viewed`，`viewed_at` 已写入。

8. 我的页
   - 重试后加载成功。
   - 显示：LeanMate 用户、30 岁女、轻度活动、连续打卡 1 天、当前体重 59.5 kg、目标 55 kg、每日目标 1520 kcal、BMI 22.0、BMR 1320。

## 发现的问题

### P1：文本识别确认页容易保存 0 kcal 记录

复现：

1. 进入记录页，选择文本识别。
2. 使用常用表达追加：一碗米饭、一个鸡蛋、一杯豆浆。
3. 点击识别并确认。
4. 不手动改营养字段，直接保存。

实际表现：

- 确认页看起来有重量、热量、蛋白、脂肪、碳水的数字，但这些数字实际是 placeholder。
- 保存后数据库中 `food_items.calories_kcal/protein_g/fat_g/carbs_g` 为 null，`food_entries.total_calories_kcal=0`。
- 首页显示午餐 0 kcal，不符合“确认后更新首页统计”的预期。
- AI placeholder 还会把整段输入聚合成单个食物名称，没有拆分食物项。

期望：

- AI 识别如果没有可用营养估算，不应展示像真实值一样的 placeholder。
- 保存前应要求用户补齐热量，或后端 placeholder 返回真实估算值。
- 确认页需要明确提示“估算值/待补充”，避免用户误以为已经识别完成。

### P1：access token 过期后“我的”页首次加载可能失败

复现：

1. 登录后持续测试超过 access token 1 小时有效期。
2. 进入“我的”页。

实际表现：

- 页面显示“我的页加载失败 / 发生未知错误”。
- 直接点击“重试”后加载成功。
- 后端 `/v1/me`、`/v1/profile`、`/v1/retention/streak`、`/v1/weights` 均可用。

初步判断：

- “我的”页并发调用 3 个鉴权接口，access token 过期时可能同时触发 refresh。
- 多个 refresh/token store 操作存在竞争，导致首次加载进入未知错误。

期望：

- access token 过期时应串行化 refresh，所有并发请求复用同一次刷新结果。
- 失败时应明确提示登录状态失效或自动恢复，而不是“发生未知错误”。

### P2：体重 Sheet 默认值没有使用用户当前体重或最近体重

复现：

1. 档案当前体重为 60 kg。
2. 首次打开体重记录 Sheet。

实际表现：

- 默认值显示 55.8 kg。

期望：

- 首次记录默认值应使用 profile 的当前体重 60 kg。
- 已有体重记录后应使用最近一次体重。

### P2：饮食保存结果页同时出现“暂无内容”和保存成功

复现：

1. 文本识别或手动记录保存成功。

实际表现：

- 结果页显示“暂无内容”，同时显示“记录已保存 / 已更新到首页”。

期望：

- 保存成功页不应出现空态文案。
- 可以展示已保存条目摘要、总热量、回首页和删除入口。

### P2：首页饮食摘要缺少历史/详情/编辑入口

复现：

1. 首页展示已保存午餐摘要。
2. 尝试点击午餐摘要进入详情或编辑。

实际表现：

- 首页摘要不可进入详情。
- 当前 App 交互没有明显入口触发 `GET /v1/diet/entries` 或 `PUT /v1/diet/entries/{id}`。
- 删除入口主要存在于保存结果页；离开结果页后不容易删除或编辑历史记录。

期望：

- 如果 V1.1 范围包含编辑/删除历史记录，需要提供饮食历史或详情入口。
- 如果暂不包含，需要在产品范围中明确。

### P3：本地联调健康检查接口被鉴权拦截

复现：

1. 请求 `GET /actuator/health`。

实际表现：

- 返回 `40101 未登录或登录已过期`。

期望：

- 本地联调和部署探活通常需要匿名可访问的 health endpoint，至少本地环境应可用于快速判断后端是否启动。

### P3：使用 `CODE_SIGNING_ALLOWED=NO` 跑模拟器会导致登录后 Keychain 写入失败

复现：

1. 用 `CODE_SIGNING_ALLOWED=NO` build/run。
2. 点击本地调试登录。

实际表现：

- 后端已创建真实账号，但 App 显示“发生未知错误”，重启仍未登录。

处理：

- 改用正常 Debug 模拟器签名构建后，本地登录正常进入档案流程。

性质：

- 这是本地测试环境问题，不是后端登录链路问题。

## 设计核对

- 欢迎页、首页、记录页、日报页、体重 Sheet 与 Pencil 的主结构一致：状态栏/导航、主体内容、底部 Tab 或 Sheet 层级均对齐。
- “我的 / 数据与计划”在重试成功后与设计映射一致，能展示体重目标、数据与计划和连续打卡。
- Debug 本地登录按钮、Debug 本地数据区不在设计稿中；当前只用于 Debug/本地联调，应确认 Release 不展示。
- 文本识别确认页与设计稿“文字解析确认 / 食卡卡风”结构接近，但 placeholder 被当成实际值的体验有风险。
- 体重 Sheet 视觉结构接近设计稿，但默认体重值不符合真实数据。

## 截图留存

以下为本次模拟器截图的临时本机路径：

- 欢迎页：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_540886e1-25d0-48a5-8e10-504fce5bf3ca.jpg`
- 档案确认页：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_c71b2369-47e5-465d-8c38-039660b50645.jpg`
- 首页初始：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_8a958504-aa1c-4da7-94db-55d21c0e352d.jpg`
- 文本识别确认页：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_33b6bdc6-b3b1-4189-a97d-2e2de04cd630.jpg`
- 手动记录表单：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_0ceaa53b-aeb2-4c12-a4ad-cf60d7198ce2.jpg`
- 首页刷新后：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_9fd23f54-bcb0-4f2e-8052-65acf98344b9.jpg`
- 体重 Sheet：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_d9f90269-1b1f-4b89-bdab-583ebad78fbc.jpg`
- 体重保存成功：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_56a1f0b3-9b8c-4de0-9541-80bcea95721a.jpg`
- 日报空态：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_404d0813-8764-4ba9-a2c5-fa1840360137.jpg`
- 日报生成后：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_65b4da05-6447-4fd8-99e3-161ab064e06e.jpg`
- 我的页失败态：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_663f4db6-6b23-4515-b87d-3e7648ef9a1f.jpg`
- 我的页成功态：`/var/folders/mc/p73cs5s109z_h5cbsf_jzbqr0000gr/T/screenshot_optimized_0cba54a5-3665-46dd-8387-52228ed7e61b.jpg`

## 测试结论

- Debug 本地登录方案满足“只 mock 登录身份校验，其他流程走真实后端和真实数据库”的目标。
- 除文本识别营养值、token refresh 稳定性、体重默认值和饮食历史入口外，V1.1 主链路可以通过真实后端跑通。
- 真实 AI Provider、真实图片存储和饮食历史编辑入口仍需按产品范围继续确认。
