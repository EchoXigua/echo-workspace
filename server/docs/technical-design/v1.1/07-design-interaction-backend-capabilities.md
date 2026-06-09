# 设计稿新增交互后端能力补齐方案

## 背景

当前设计稿新增和强化了这些页面与交互：

- 我的 / 数据与计划 v2
- 我的 / 数据与计划详情
- 我的 / 身体档案编辑
- 我的 / 体重趋势
- 目标校准 / 完成确认
- 数据同步
- 里程碑弹窗
- 设置页中的提醒、数据同步、隐私与本地数据

现有后端已经覆盖账号、档案、饮食记录、食物库、体重记录、首页、AI 日报和连续打卡的基础链路。但设计稿里的部分信息是“聚合状态”或“交互状态”，不适合完全让客户端用多个基础接口拼。

本方案用于把设计稿新增交互拆成后端接口和数据模型改动，后续再同步更新 OpenAPI。

## 设计原则

- 聚合页面由后端提供聚合接口，客户端少做跨接口计算。
- 用户交互状态由后端记录，避免换设备后重复弹窗或状态丢失。
- 游客同步统一处理饮食、体重和档案，避免多个同步入口之间状态不一致。
- 目标计划支持减重、增重和维持，不把增重用户误算成维持热量。
- 现有 V1.1 接口尽量保持兼容，新增字段优先做可选字段。

## 能力清单

| 优先级 | 设计稿能力 | 后端能力 | 建议接口 |
| --- | --- | --- | --- |
| P0 | 数据与计划首页、详情页 | 计划聚合视图 | `GET /v1/profile/plan-overview` |
| P0 | 体重增加态 | 增重目标计算 | 扩展 `PUT /v1/profile` |
| P0 | 体重趋势页 | 趋势聚合和图表数据 | `GET /v1/weights/trend` |
| P0 | 数据同步页 | 游客数据统一同步 | `POST /v1/sync/local` |
| P1 | 里程碑弹窗 | 弹窗生成和关闭状态 | `GET /v1/retention/milestone-notices`、`POST /v1/retention/milestone-notices/{noticeId}/dismiss` |
| P1 | 设置页 | 用户设置和提醒偏好 | `GET /v1/settings`、`PUT /v1/settings` |
| P2 | 手动记录备注 | 食物项或整餐备注 | 视产品口径扩展 `food_items.note` 或复用 `food_entries.raw_text` |

## 计划聚合接口

### GET /v1/profile/plan-overview

用于支撑：

- 我的 / 数据与计划 v2
- 我的 / 数据与计划详情
- 体重增加态
- 目标校准完成页中的计划摘要

该接口聚合用户档案、当前目标、最近体重和计算指标。客户端不需要自己拼 `GET /v1/profile`、`GET /v1/weights`、`GET /v1/profile/calorie-target-suggestion`。

### 响应示例

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "profileCompleted": true,
    "displayName": "小叶",
    "profile": {
      "gender": "female",
      "age": 25,
      "heightCm": 181.0,
      "currentWeightKg": 75.0,
      "targetWeightKg": 66.0,
      "activityLevel": "light",
      "activityLevelLabel": "轻度活动",
      "bmi": 22.9,
      "bmrKcal": 1761
    },
    "goal": {
      "goalType": "lose_weight",
      "startWeightKg": 75.0,
      "targetWeightKg": 66.0,
      "remainingWeightKg": 9.0,
      "targetDate": null,
      "dailyCalorieTargetKcal": 2021,
      "estimatedActivityEnergyKcal": 260,
      "weeklyTargetWeightChangeKg": -0.4,
      "status": "active"
    },
    "weightTrend": {
      "windowDays": 30,
      "startWeightKg": 75.4,
      "latestWeightKg": 75.0,
      "changeKg": -0.4,
      "direction": "decreasing"
    },
    "calorieAdjustment": {
      "action": "suggest_lower",
      "suggestedDailyCalorieTargetKcal": 1921,
      "message": "过去 14 天体重下降慢于预期，建议小幅下调每日目标热量"
    }
  }
}
```

### 字段说明

| 字段 | 说明 |
| --- | --- |
| `goal.goalType` | `lose_weight`、`gain_weight`、`maintain` |
| `remainingWeightKg` | 目标差值，减重和增重都返回正数，方便 UI 展示“剩余 9kg” |
| `estimatedActivityEnergyKcal` | 活动消耗估算值，可由 `TDEE - BMR` 计算 |
| `weeklyTargetWeightChangeKg` | 减重为负数，增重为正数，维持为 0 |
| `weightTrend.direction` | `decreasing`、`increasing`、`flat` |

### 实现要点

- `profile` 来自 `user_profiles`。
- `goal` 来自当前 active `weight_goals`。
- `weightTrend` 基于最近 30 天 `weight_entries` 计算。
- `calorieAdjustment` 可复用现有 `getCalorieTargetSuggestion` 逻辑。
- 没有档案时返回 `profileCompleted=false`，其他字段可为空。

## 增重目标计算

### 扩展 PUT /v1/profile

当前后端的目标热量计算只真正覆盖减重场景。设计稿出现“体重增加态”，需要支持增重目标。

### 请求扩展

```json
{
  "gender": "female",
  "age": 25,
  "heightCm": 181,
  "currentWeightKg": 66,
  "targetWeightKg": 75,
  "goalType": "gain_weight",
  "activityLevel": "light",
  "timezone": "Asia/Shanghai",
  "targetDate": null
}
```

`goalType` 可以允许不传。后端默认推断：

| 条件 | 推断值 |
| --- | --- |
| `targetWeightKg < currentWeightKg` | `lose_weight` |
| `targetWeightKg > currentWeightKg` | `gain_weight` |
| `targetWeightKg == currentWeightKg` | `maintain` |

### 计算规则

```text
BMR = Mifflin-St Jeor
TDEE = BMR * activityLevel.multiplier
```

减重：

```text
dailyTarget = TDEE - dailyDeficit
dailyDeficit 默认 TDEE * 15%
dailyDeficit 范围 300-750 kcal
```

增重：

```text
dailyTarget = TDEE + dailySurplus
dailySurplus 默认 TDEE * 10%
dailySurplus 范围 150-500 kcal
```

维持：

```text
dailyTarget = TDEE
```

安全边界：

- 减重不能低于性别安全下限。
- 增重也需要设置上限，避免目标日期过近导致异常高热量。
- 目标体重仍需校验 BMI 安全范围。

### 数据库调整

建议给 `weight_goals` 增加字段：

```sql
alter table weight_goals
    add column goal_type varchar(32) not null default 'lose_weight',
    add column weekly_target_weight_change_kg numeric(5,2);

alter table weight_goals
    add constraint chk_weight_goals_goal_type
        check (goal_type in ('lose_weight', 'gain_weight', 'maintain'));
```

`user_profiles` 可以不存 `goal_type`，避免档案和目标状态重复。展示时从 active `weight_goals` 返回。

## 体重趋势接口

### GET /v1/weights/trend

用于支撑：

- 我的 / 体重趋势
- 数据与计划首页的近 30 天变化
- 体重保存后“保存并更新趋势”

### 请求

```json
{
  "query": {
    "days": 30
  }
}
```

`days` 默认 30，建议范围 7-180。

### 响应示例

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "windowDays": 30,
    "targetWeightKg": 66.0,
    "startWeightKg": 75.4,
    "latestWeightKg": 75.0,
    "changeKg": -0.4,
    "direction": "decreasing",
    "points": [
      {
        "date": "2026-06-03",
        "weightKg": 75.6,
        "isToday": false
      },
      {
        "date": "2026-06-09",
        "weightKg": 75.0,
        "isToday": true
      }
    ]
  }
}
```

### 实现要点

- 查询 `weight_entries` 最近 N 天记录。
- `startWeightKg` 使用窗口内最早一条记录。
- `latestWeightKg` 使用窗口内最新一条记录。
- `changeKg = latest - start`。
- `direction` 根据变化值计算。
- `targetWeightKg` 来自 active `weight_goals`。
- 不需要新表。

## 游客数据统一同步

### POST /v1/sync/local

设计稿“数据同步”页展示同步范围：

- 饮食记录
- 体重记录
- 身体档案

现在后端只有 `POST /v1/diet/entries/sync-local`，无法覆盖体重和档案。建议新增统一同步接口，旧接口保留兼容。

### 请求示例

```json
{
  "profile": {
    "clientLocalId": "profile-local-uuid",
    "updatedAt": "2026-06-09T09:00:00Z",
    "data": {
      "gender": "female",
      "age": 25,
      "heightCm": 181,
      "currentWeightKg": 75,
      "targetWeightKg": 66,
      "goalType": "lose_weight",
      "activityLevel": "light",
      "timezone": "Asia/Shanghai",
      "targetDate": null
    }
  },
  "weightEntries": [
    {
      "clientLocalId": "weight-local-uuid",
      "recordDate": "2026-06-09",
      "weightKg": 75,
      "note": "早晨空腹",
      "createdAt": "2026-06-09T00:30:00Z",
      "updatedAt": "2026-06-09T00:30:00Z"
    }
  ],
  "dietEntries": [
    {
      "clientLocalId": "diet-local-uuid",
      "entry": {
        "mealDate": "2026-06-09",
        "mealType": "breakfast",
        "sourceType": "manual",
        "items": []
      },
      "createdAt": "2026-06-09T01:00:00Z",
      "updatedAt": "2026-06-09T01:00:00Z"
    }
  ]
}
```

### 响应示例

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "profile": {
      "status": "imported",
      "message": null
    },
    "dietEntries": {
      "importedCount": 3,
      "skippedCount": 1,
      "failedItems": []
    },
    "weightEntries": {
      "importedCount": 2,
      "skippedCount": 0,
      "failedItems": []
    },
    "refreshedDates": [
      "2026-06-09"
    ]
  }
}
```

### 幂等策略

| 数据 | 幂等依据 |
| --- | --- |
| 饮食记录 | 已有 `food_entries.client_local_id` |
| 体重记录 | 新增 `weight_entries.client_local_id`，同时保留 `user_id + record_date` 唯一约束 |
| 身体档案 | 当前用户只有一份档案，按 `updatedAt` 做冲突判断 |

### 数据库调整

```sql
alter table weight_entries
    add column client_local_id uuid;

create unique index uq_weight_entries_user_client_local
    on weight_entries(user_id, client_local_id)
    where client_local_id is not null;
```

### 冲突处理

- 饮食记录：沿用当前 sync-local 逻辑，重复 `clientLocalId` 跳过。
- 体重记录：同一天已有远端记录时，使用 `updatedAt` 较新的记录覆盖；如果没有 `updatedAt`，远端优先。
- 身体档案：用户远端已完成档案且远端更新时间更新时，返回 `skipped`；否则导入本地档案。
- 部分失败不影响其他类别导入。

## 里程碑弹窗状态

### 为什么需要两个接口

`GET /v1/retention/streak` 只描述连续打卡状态，例如当前连续 12 天。它不能回答“连续 12 天弹窗是否已经给用户看过”。

里程碑弹窗是交互状态，需要单独存储：

- 达到里程碑时生成 notice。
- 客户端获取 pending notice 后展示弹窗。
- 用户点“知道了”后关闭 notice。
- 换设备登录后不会重复弹。

### GET /v1/retention/milestone-notices

获取当前待展示的里程碑弹窗。

```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "notice-uuid",
      "type": "streak",
      "title": "连续记录 12 天",
      "message": "今天也完成记录，继续保持现在的节奏。",
      "currentValue": 12,
      "previousValue": 7,
      "nextValue": 14,
      "triggeredAt": "2026-06-09T10:00:00Z"
    }
  ]
}
```

### POST /v1/retention/milestone-notices/{noticeId}/dismiss

标记里程碑弹窗已关闭。

```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

### 数据库调整

```sql
create table retention_notices (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    type varchar(64) not null,
    milestone_value integer not null,
    title varchar(128) not null,
    message text,
    status varchar(32) not null default 'pending',
    triggered_at timestamptz not null default now(),
    dismissed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_retention_notices_user_type_value unique (user_id, type, milestone_value),
    constraint chk_retention_notices_status check (status in ('pending', 'dismissed'))
);

create index idx_retention_notices_user_status
    on retention_notices(user_id, status, triggered_at desc);
```

### 生成规则

V1.1 可先支持 streak notice：

| 条件 | notice |
| --- | --- |
| 连续记录达到 3 天 | 连续记录 3 天 |
| 连续记录达到 7 天 | 连续记录 7 天 |
| 连续记录达到 12 天 | 连续记录 12 天 |
| 连续记录达到 30 天 | 连续记录 30 天 |
| 连续记录达到 100 天 | 连续记录 100 天 |

生成时机：

- 保存饮食记录成功后刷新 streak 时检查。
- 同步游客饮食记录后刷新 streak 时检查。
- 可做幂等 upsert，避免重复 notice。

## 用户设置和提醒

### GET /v1/settings

用于设置页展示：

- 记餐提醒
- 里程碑提示
- 数据同步偏好
- 本地数据和隐私开关

V1.1 如果提醒只依赖 iOS 本地通知，可以暂不做服务端设置。但如果要支持跨设备一致和重新登录恢复，建议补接口。

### 响应示例

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "mealReminderEnabled": true,
    "mealReminderTimes": [
      "08:30",
      "12:30",
      "18:30"
    ],
    "milestoneNoticeEnabled": true,
    "autoSyncEnabled": true
  }
}
```

### PUT /v1/settings

```json
{
  "mealReminderEnabled": true,
  "mealReminderTimes": [
    "08:30",
    "12:30",
    "18:30"
  ],
  "milestoneNoticeEnabled": true,
  "autoSyncEnabled": true
}
```

### 数据库调整

```sql
create table user_settings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    meal_reminder_enabled boolean not null default false,
    meal_reminder_times jsonb not null default '[]'::jsonb,
    milestone_notice_enabled boolean not null default true,
    auto_sync_enabled boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_user_settings_user unique (user_id)
);
```

## 手动记录备注

设计稿手动记录里有备注输入。这里需要产品确认是整餐备注还是食物项备注。

### 如果是整餐备注

复用现有：

```text
food_entries.raw_text
```

保存接口无需新增字段，只需要客户端把备注写入 `rawText`。

### 如果是食物项备注

需要扩展：

```sql
alter table food_items
    add column note varchar(500);
```

并在 `SaveFoodItemRequest` / `FoodItemResponse` 增加 `note` 字段。

建议 V1.1 先按整餐备注处理，减少表结构变化。

## 和现有接口的关系

| 现有接口 | 是否保留 | 调整 |
| --- | --- | --- |
| `GET /v1/profile` | 保留 | 继续提供基础档案 |
| `PUT /v1/profile` | 保留 | 增加可选 `goalType`，支持增重计算 |
| `GET /v1/profile/calorie-target-suggestion` | 保留 | 可被 plan-overview 聚合 |
| `GET /v1/weights` | 保留 | 继续提供原始记录 |
| `POST /v1/weights` | 保留 | 保存后可返回 trend 摘要，或由客户端再调 trend |
| `POST /v1/diet/entries/sync-local` | 保留 | 兼容旧客户端；新客户端优先用 `POST /v1/sync/local` |
| `GET /v1/retention/streak` | 保留 | 只返回连续打卡状态，不负责弹窗已读 |

## 实施顺序

### 第一阶段：计划和趋势

1. 扩展目标计算支持 `goalType`。
2. 新增 `weight_goals.goal_type`。
3. 新增 `GET /v1/profile/plan-overview`。
4. 新增 `GET /v1/weights/trend`。

这一阶段直接支撑“我的 / 数据与计划”“体重趋势”“体重增加态”。

### 第二阶段：统一同步

1. 新增 `weight_entries.client_local_id`。
2. 新增 `POST /v1/sync/local`。
3. 复用已有饮食记录同步逻辑。
4. 同步成功后刷新受影响日期的统计和 streak。

这一阶段支撑“数据同步”页。

### 第三阶段：里程碑弹窗

1. 新增 `retention_notices`。
2. streak 更新时生成 notice。
3. 新增 notice 查询和 dismiss 接口。

这一阶段支撑“里程碑弹窗 / 食卡卡风”。

### 第四阶段：设置

1. 新增 `user_settings`。
2. 新增设置查询和保存接口。
3. 明确提醒由 iOS 本地通知执行，后端只保存偏好。

这一阶段支撑设置页。

## 测试要点

- 减重、增重、维持三类目标的热量目标计算正确。
- 目标日期过近时不会产生异常高或异常低热量。
- `plan-overview` 在无档案、有档案无体重、有完整数据三种状态都能返回稳定结构。
- `weights/trend` 在没有记录、只有一条记录、多条记录时都能返回合理趋势。
- `sync/local` 部分失败时不回滚已成功类别，并能返回失败项。
- 同一 `clientLocalId` 重复同步不会重复写入。
- 里程碑 notice 只生成一次，dismiss 后不再返回。
- 用户只能 dismiss 自己的 notice。
- 设置接口默认值稳定，重复保存幂等。

## 待确认问题

- 增重默认周目标采用多少：建议 `+0.25kg/周` 作为温和默认。
- 设计稿中的“活动消耗”是否只展示估算值，还是允许用户手动编辑。
- 数据同步冲突时是否永远远端优先，还是本地更新时间优先。
- 里程碑是否只包括连续记录，还是同时包括体重目标、AI 日报、首次同步等。
- 手动记录备注是整餐备注还是单个食物备注。
