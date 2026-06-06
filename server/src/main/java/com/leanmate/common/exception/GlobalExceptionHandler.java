package com.leanmate.common.exception;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.response.ApiResponse;
import jakarta.validation.ConstraintViolationException;
import java.util.Objects;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(BusinessException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        return buildResponse(errorCode, exception.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodArgumentNotValid(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> error.getField() + ": " + defaultMessage(error.getDefaultMessage()))
                .distinct()
                .collect(Collectors.joining("; "));
        return buildResponse(ErrorCode.VALIDATION_FAILED, fallback(message, ErrorCode.VALIDATION_FAILED.message()));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleConstraintViolation(ConstraintViolationException exception) {
        String message = exception.getConstraintViolations()
                .stream()
                .map(violation -> violation.getPropertyPath() + ": "
                        + defaultMessage(violation.getMessage()))
                .distinct()
                .collect(Collectors.joining("; "));
        return buildResponse(ErrorCode.VALIDATION_FAILED, fallback(message, ErrorCode.VALIDATION_FAILED.message()));
    }

    @ExceptionHandler({
            MissingServletRequestParameterException.class,
            MissingServletRequestPartException.class,
            MaxUploadSizeExceededException.class,
            MethodArgumentTypeMismatchException.class,
            HttpMessageNotReadableException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleBadRequest(Exception exception) {
        return buildResponse(ErrorCode.BAD_REQUEST, ErrorCode.BAD_REQUEST.message());
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNoResourceFound(NoResourceFoundException exception) {
        return buildResponse(ErrorCode.NOT_FOUND, ErrorCode.NOT_FOUND.message());
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotSupported(HttpRequestMethodNotSupportedException exception) {
        return buildResponse(ErrorCode.METHOD_NOT_ALLOWED, ErrorCode.METHOD_NOT_ALLOWED.message());
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMediaTypeNotSupported(HttpMediaTypeNotSupportedException exception) {
        return buildResponse(ErrorCode.UNSUPPORTED_MEDIA_TYPE, ErrorCode.UNSUPPORTED_MEDIA_TYPE.message());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException exception) {
        return buildResponse(ErrorCode.FORBIDDEN, ErrorCode.FORBIDDEN.message());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception exception) {
        log.error("未处理的服务端异常: {}", exception.getClass().getName(), exception);
        return buildResponse(ErrorCode.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_SERVER_ERROR.message());
    }

    private ResponseEntity<ApiResponse<Void>> buildResponse(ErrorCode errorCode, String message) {
        return ResponseEntity.status(httpStatus(errorCode))
                .body(ApiResponse.failure(errorCode, message));
    }

    private HttpStatus httpStatus(ErrorCode errorCode) {
        if (errorCode == ErrorCode.SUCCESS) {
            return HttpStatus.OK;
        }
        int rawStatus = errorCode.code() / 100;
        return Objects.requireNonNullElse(HttpStatus.resolve(rawStatus), HttpStatus.INTERNAL_SERVER_ERROR);
    }

    private String defaultMessage(String message) {
        return fallback(message, "参数无效");
    }

    private String fallback(String value, String fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        return value;
    }
}
