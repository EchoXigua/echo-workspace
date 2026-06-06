# V1.1 API 设计说明

## 定位

本文是 V1.1 接口的人类可读设计说明，用于后端技术方案评审和客户端理解接口边界。

唯一机器可读接口契约仍然是：

- `../../../../docs/api/openapi.yaml`

如果本文和 OpenAPI 冲突，以 OpenAPI 为准。

## 接口分组

V1.1 接口按业务域分组：

- Auth：登录、刷新令牌、退出。
- Profile：用户档案和目标。
- Home：首页今日状态。
- Diet：饮食识别任务、饮食记录。
- Weight：体重记录。
- Report：AI 日报。
- Retention：连续打卡和里程碑。

## Auth

### POST /v1/auth/oauth-login

用于 Apple、Google 等第三方登录。V1.1 iOS 可先接 Apple，但接口模型不要绑定死 Apple。

请求重点字段：

- `provider`：`apple`、`google`
- `identityToken`
- `authorizationCode`
- `deviceId`

响应：

- `accessToken`
- `refreshToken`
- `expiresIn`
- `user`
- `profileCompleted`

### POST /v1/auth/refresh

刷新 access token。

### POST /v1/auth/logout

撤销当前 refresh token。

### GET /v1/me

获取当前登录用户基础信息。

## Profile

### GET /v1/profile

获取当前用户档案。未完成档案时，返回 `data = null` 或 `profileCompleted = false`，具体以 OpenAPI 最终定义为准。

### PUT /v1/profile

创建或更新用户档案，并由后端计算：

- BMI
- BMR
- 每日推荐热量目标

## Home

### GET /v1/home/today

获取首页今日聚合数据。

响应包含：

- 业务日期；
- 今日目标热量；
- 已摄入热量；
- 剩余热量；
- 当前体重；
- 连续打卡天数；
- AI 日报摘要；
- 今日饮食记录简表；
- 档案是否已完成。

## Diet

### POST /v1/diet/recognitions/photo

创建拍照识别任务。

V1.1 可以同步返回已完成结果，也可以返回任务状态。为了兼容耗时识别，客户端必须支持 task 查询。

### POST /v1/diet/recognitions/text

创建文本解析任务。

### GET /v1/diet/recognitions/{taskId}

查询识别任务状态。

状态：

- `pending`
- `running`
- `succeeded`
- `failed`

识别成功后返回草稿饮食记录，用户确认后才保存为正式记录。

### GET /v1/diet/entries

按日期查询饮食记录。

### POST /v1/diet/entries

保存饮食记录。

规则：

- 手动记录可以直接 confirmed。
- AI 识别结果需要用户确认后保存。
- 保存后刷新今日统计。

### PUT /v1/diet/entries/{entryId}

编辑饮食记录，并重新计算营养总量和今日快照。

### DELETE /v1/diet/entries/{entryId}

软删除饮食记录，并重新计算今日快照。

## Weight

### GET /v1/weights

按日期范围查询体重记录。

### POST /v1/weights

保存体重记录。

V1.1 建议同一天同一用户只保留一条体重记录，重复提交则覆盖。

## Report

### GET /v1/reports/daily

按日期获取 AI 日报。

### POST /v1/reports/daily

手动触发生成或重试生成 AI 日报。

### POST /v1/reports/daily/{reportId}/view

标记日报已查看，用于计算 AI 日报查看率。

## Retention

### GET /v1/retention/streak

获取连续打卡状态。

返回：

- 当前连续天数；
- 历史最长天数；
- 最近有效记录日；
- 已达成里程碑。

## 错误响应

统一响应：

```json
{
  "code": 40001,
  "message": "参数错误",
  "data": null
}
```

V1.1 建议错误码：

- `40001`：参数错误。
- `40101`：未登录或 token 无效。
- `40301`：无权限访问资源。
- `40401`：资源不存在。
- `40901`：状态冲突。
- `50001`：服务端错误。
- `50010`：AI 服务调用失败。

## OpenAPI 同步状态

当前 `docs/api/openapi.yaml` 已同步 V1.1 主要接口契约，包括：

- Auth 接口。
- `GET /v1/me`。
- `GET /v1/diet/recognitions/{taskId}`。
- `POST /v1/reports/daily/{reportId}/view`。
- 统一错误响应 schema。
- `profileCompleted` 字段。
- 更明确的 nullable、required、enum。

后端编码和客户端 Mock 都以 `docs/api/openapi.yaml` 为准。若实现过程中发现接口字段需要调整，先更新 OpenAPI，再改后端和客户端。
