# 用户档案与目标后端技术方案

## 基本信息

- 版本：V1.1
- 对应 PRD：8.1 用户档案、9 首次使用
- 状态：已确认 V1.1 默认策略

## 业务目标

用户首次进入 App 后完成基础身体信息填写，后端计算 BMI、BMR 和每日推荐热量目标，为首页统计、饮食记录和 AI 日报提供基础数据。

## 后端职责

- 提供账号登录后的当前用户上下文。
- 提供 V1.1 第三方登录、刷新令牌和退出登录接口。
- 保存用户档案。
- 计算并保存 BMI、BMR、每日推荐热量目标。
- 保存减脂目标快照。
- 为首页和 AI 日报提供用户目标数据。

## 不做范围

- V1.1 不做复杂个性化减脂计划。
- V1.1 不做 Apple Health 同步。
- V1.1 不把账号体系绑定死在 Apple 登录。
- V1.1 不实现 Google 登录；OpenAPI 保留 `google` 枚举仅用于后续扩展，当前请求返回参数错误。
- V1.1 不实现手机号、邮箱、用户名密码登录。

## 核心流程

```mermaid
sequenceDiagram
    participant App
    participant API
    participant DB

    App->>API: 登录/注册
    API-->>App: 返回 Token
    App->>API: 提交用户档案
    API->>API: 计算 BMI/BMR/推荐热量
    API->>DB: 保存 UserProfile 和 WeightGoal
    API-->>App: 返回档案和目标
```

## 数据模型影响

详细表结构见：

- `../../database-design.md`

核心表：

- `users`
- `user_auth_identities`
- `refresh_tokens`
- `user_profiles`
- `weight_goals`

关键规则：

- `user_profiles.user_id` 唯一。
- `weight_goals` 支持历史目标，当前目标用 `status = active` 标记。
- BMI、BMR、推荐热量保存为快照，避免公式变化影响历史解释。

## API 影响

人类可读 API 设计见：

- `api-design.md`

已有草案：

- `GET /v1/profile`
- `PUT /v1/profile`

需要补充：

- 登录/注册接口。
- Refresh Token 接口。
- 当前用户信息接口。

最终接口契约以 `../../../../docs/api/openapi.yaml` 为准。

## 业务规则

- 年龄、身高、当前体重、目标体重必须有合理范围校验。
- 目标体重不能小于危险阈值。
- 活动水平使用枚举，不接受自由文本。
- 用户更新当前体重时，不直接覆盖历史体重记录，正式体重趋势以 `weight_entries` 为准。

## V1.1 认证策略

- 首发真实登录方式只实现 Sign in with Apple。
- `oauth-login.provider` 保留 `apple`、`google` 两个枚举；V1.1 只接受 `apple`，`google` 返回 `40001` 参数错误。
- `local` 和 `test` 环境允许使用受控 mock verifier，便于本地开发和自动化测试；mock token 必须使用 `mock:<providerUserId>` 或 `mock:<providerUserId>:<email>` 格式，不接受任意字符串。
- `dev` 和 `prod` 环境必须校验 Apple identity token 的签名、issuer、audience、过期时间和 subject。
- Access Token 使用短期 JWT；Refresh Token 使用服务端生成的不透明随机值，数据库只保存 SHA-256 哈希。
- Refresh Token 刷新时执行轮换：旧 token 撤销，返回新 token。

## V1.1 用户档案计算默认公式

- BMI：`currentWeightKg / (heightCm / 100)^2`，保留 2 位小数。
- BMR：采用 Mifflin-St Jeor 公式。
  - 男性：`10 * weightKg + 6.25 * heightCm - 5 * age + 5`。
  - 女性：`10 * weightKg + 6.25 * heightCm - 5 * age - 161`。
  - 未知性别：使用男女常量中位数，`10 * weightKg + 6.25 * heightCm - 5 * age - 78`。
- 活动系数：
  - `sedentary`：1.2
  - `light`：1.375
  - `moderate`：1.55
  - `active`：1.725
  - `very_active`：1.9
- TDEE：`BMR * 活动系数`。
- 每日推荐热量目标：
  - 当 `targetWeightKg < currentWeightKg` 时，默认按 TDEE 的 15% 制造热量缺口。
  - 如果传入未来 `targetDate`，用 `(currentWeightKg - targetWeightKg) * 7700 / 剩余天数` 估算每日缺口。
  - 每日缺口限制在 300-750 kcal；低于 300 按 300，高于 750 按 750。
  - 当 `targetWeightKg >= currentWeightKg` 时，不制造热量缺口，按 TDEE 作为目标。
  - 最终目标四舍五入到 10 kcal，并应用安全下限：男性 1500 kcal，女性 1200 kcal，未知性别 1300 kcal。
- 目标体重安全阈值：按目标 BMI 不低于 18.5 校验，低于阈值返回 `40001` 参数错误。

## 异常和降级

- 档案未完成时，首页接口返回 `profileCompleted = false`，客户端引导补全。
- 推荐热量计算失败时返回明确错误，不生成默认目标。

## 权限和数据归属

- 用户只能读取和更新自己的档案。
- 登录身份通过 `user_auth_identities` 绑定到 `users`。
- Refresh Token 只保存哈希值，不保存明文。

## 异步任务

- 本需求不需要异步任务。
- V1.1 不需要 Redis/MQ。

## 埋点和指标

- `profile_started`
- `profile_completed`
- `goal_generated`

## 测试要点

- BMI/BMR 计算正确。
- 缺失必填字段返回参数错误。
- 重复提交档案时正确更新。
- 档案未完成用户不能生成完整首页统计。

## 已收束问题

- V1.1 首发真实登录只支持 Sign in with Apple；local/test 使用受控 mock verifier。
- 推荐热量目标使用本方案中的 V1.1 默认公式，后续如产品确认新公式，再通过迁移或版本化计算策略调整新快照。
