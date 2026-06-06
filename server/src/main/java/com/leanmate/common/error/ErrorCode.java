package com.leanmate.common.error;

public enum ErrorCode {
    SUCCESS(0, "success"),
    BAD_REQUEST(40000, "请求参数错误"),
    VALIDATION_FAILED(40001, "请求参数校验失败"),
    UNAUTHORIZED(40100, "认证失败"),
    INVALID_TOKEN(40101, "无效或过期的访问令牌"),
    FORBIDDEN(40300, "权限不足"),
    NOT_FOUND(40400, "资源不存在"),
    METHOD_NOT_ALLOWED(40500, "请求方法不支持"),
    UNSUPPORTED_MEDIA_TYPE(41500, "请求内容类型不支持"),
    INTERNAL_SERVER_ERROR(50000, "服务端错误");

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
