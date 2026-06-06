# LeanMate V1.1 埋点事件定义

## 目标

V1.1 埋点用于验证：

- 用户是否完成首次饮食记录。
- 用户是否完成首次体重记录。
- 用户是否查看 AI 日报。
- 用户是否连续记录 3 天和 7 天。
- AI 识别是否稳定、是否被用户大量编辑。

## 通用字段

所有事件建议包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `eventId` | string | 事件唯一 ID |
| `eventType` | string | 事件名 |
| `userId` | string | 用户 ID，匿名事件可为空 |
| `anonymousId` | string | 匿名设备 ID |
| `occurredAt` | string | ISO 8601 时间 |
| `platform` | string | ios/android/web/server |
| `appVersion` | string | App 版本 |
| `properties` | object | 事件扩展属性 |

V1.1 可以先写入后端日志或数据库事件表，后续再接入专门分析平台。

## 核心事件

### auth_login_succeeded

登录成功。

属性：

- `provider`：apple/google/phone/email
- `isNewUser`：是否新用户

### profile_completed

用户完成档案填写。

属性：

- `gender`
- `age`
- `activityLevel`
- `dailyCalorieTargetKcal`

### goal_generated

后端生成减脂目标。

属性：

- `currentWeightKg`
- `targetWeightKg`
- `dailyCalorieTargetKcal`

### diet_recognition_started

用户开始 AI 饮食识别。

属性：

- `sourceType`：photo/text
- `mealType`
- `mealDate`

### diet_recognition_succeeded

AI 饮食识别成功。

属性：

- `taskId`
- `sourceType`
- `itemCount`
- `durationMs`
- `modelName`

### diet_recognition_failed

AI 饮食识别失败。

属性：

- `taskId`
- `sourceType`
- `errorCode`
- `durationMs`

### diet_entry_confirmed

用户确认并保存饮食记录。

属性：

- `entryId`
- `sourceType`：photo/text/manual
- `mealType`
- `mealDate`
- `itemCount`
- `totalCaloriesKcal`
- `hasUserEdited`

### first_diet_entry_completed

用户完成第一条饮食记录。

属性：

- `entryId`
- `sourceType`

### diet_entry_edited

用户编辑饮食记录。

属性：

- `entryId`
- `changedFields`

### weight_entry_created

用户保存体重记录。

属性：

- `entryId`
- `recordDate`
- `weightKg`
- `isFirstWeightEntry`

### first_weight_entry_completed

用户完成第一条体重记录。

属性：

- `entryId`

### daily_report_generated

AI 日报生成成功。

属性：

- `reportId`
- `reportDate`
- `score`
- `durationMs`
- `modelName`

### daily_report_failed

AI 日报生成失败。

属性：

- `reportDate`
- `errorCode`
- `durationMs`

### daily_report_viewed

用户查看 AI 日报。

属性：

- `reportId`
- `reportDate`
- `score`

### streak_updated

连续记录状态更新。

属性：

- `currentDays`
- `longestDays`
- `lastActiveDate`

### streak_milestone_unlocked

用户达成连续记录里程碑。

属性：

- `days`：3/7/30/100

## 事件采集策略

- 客户端负责采集页面行为和用户主动操作。
- 后端负责采集服务端确认事件，例如饮食保存成功、日报生成成功、连续记录更新。
- 关键成功指标优先以后端事件为准，避免客户端上报失败造成偏差。

## V1.1 暂不做

- 不接复杂实时数仓。
- 不做用户行为实时推荐。
- 不做跨渠道广告归因。

## 待确认问题

- 是否需要选择第三方分析平台。
- 客户端匿名 ID 生成规则。
- 用户删除账号后事件数据如何处理。
