package com.leanmate.common.error;

public enum ErrorCode {
    SUCCESS(0, "success"),
    BAD_REQUEST(40001, "参数错误"),
    VALIDATION_FAILED(40001, "参数错误"),
    UNAUTHORIZED(40101, "未登录或登录已过期"),
    INVALID_TOKEN(40101, "未登录或登录已过期"),
    FORBIDDEN(40301, "无权限访问该资源"),
    NOT_FOUND(40401, "资源不存在"),
    CONFLICT(40901, "当前状态不允许执行该操作"),
    METHOD_NOT_ALLOWED(40501, "请求方法不支持"),
    UNSUPPORTED_MEDIA_TYPE(41501, "请求内容类型不支持"),
    INTERNAL_SERVER_ERROR(50001, "服务端错误"),
    AI_SERVICE_ERROR(50010, "AI 服务暂时不可用");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int code() {
        return code;
    }

    public String message() {
        return message;
    }
}
