# LeanMate V1.1 指标口径

## 目标

V1.1 指标用于验证两个核心假设：

- 用户是否愿意持续记录饮食和体重。
- AI 日报是否能提升留存和反馈价值。

## 核心指标

### 首次饮食记录完成率

定义：

```text
完成第一条 confirmed 饮食记录的注册用户数 / 注册用户数
```

推荐事件：

- 分子：`first_diet_entry_completed`
- 分母：`auth_login_succeeded` 且 `isNewUser = true`

### 首次体重记录完成率

定义：

```text
完成第一条体重记录的注册用户数 / 注册用户数
```

推荐事件：

- 分子：`first_weight_entry_completed`
- 分母：`auth_login_succeeded` 且 `isNewUser = true`

### AI 日报查看率

定义：

```text
查看 AI 日报的用户数 / 成功生成 AI 日报的用户数
```

推荐事件：

- 分子：`daily_report_viewed`
- 分母：`daily_report_generated`

### 3 日连续记录完成率

定义：

```text
达成连续记录 3 天的用户数 / 注册用户数
```

推荐事件：

- 分子：`streak_milestone_unlocked` 且 `days = 3`
- 分母：`auth_login_succeeded` 且 `isNewUser = true`

### 7 日连续记录完成率

定义：

```text
达成连续记录 7 天的用户数 / 注册用户数
```

推荐事件：

- 分子：`streak_milestone_unlocked` 且 `days = 7`
- 分母：`auth_login_succeeded` 且 `isNewUser = true`

### 7 日留存率

定义：

```text
注册后第 7 天有有效记录或打开 App 的用户数 / 注册用户数
```

V1.1 可以先用有效记录作为主要口径：

- 有 confirmed 饮食记录；
- 或有体重记录；
- 或查看 AI 日报。

目标：

```text
7 日留存率 >= 20%
```

### 日均饮食记录次数

定义：

```text
confirmed 饮食记录数 / 活跃用户数
```

活跃用户：

- 当日有饮食记录；
- 或有体重记录；
- 或查看 AI 日报。

## AI 质量指标

### AI 识别成功率

```text
diet_recognition_succeeded / diet_recognition_started
```

### AI 识别失败率

```text
diet_recognition_failed / diet_recognition_started
```

### AI 结果编辑率

```text
hasUserEdited = true 的 diet_entry_confirmed 数 / AI 来源的 diet_entry_confirmed 数
```

编辑率高说明 AI 估算可能不准，或者确认页交互需要优化。

## 业务日期口径

- 业务日期按用户 `timezone` 计算。
- 服务端存储时间使用 UTC。
- 指标按业务日期聚合，不按纯 UTC 日期聚合。

## V1.1 报表建议

第一阶段只需要日级报表：

- 新增用户数。
- 首次饮食记录完成率。
- 首次体重记录完成率。
- AI 日报生成数和查看率。
- 3 日/7 日连续记录完成率。
- 7 日留存率。
- AI 识别成功率和失败率。

## 待确认问题

- 是否需要把“打开 App”作为留存口径。
- 是否需要第三方分析平台。
- 事件数据保留期限。
