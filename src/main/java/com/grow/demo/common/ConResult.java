package com.grow.demo.common;


import org.springframework.util.StringUtils;

import java.io.Serializable;

/**
 * @author liuxw
 * @date 16/1/11
 */
public class ConResult implements Serializable {

    public static final String DEFAULT_ERROR_MESSAGE = "系统操作过程中出现错误,请重试";

    private boolean success;
    private String message;
    private Object data;

    public static ConResult success() {
        return success(null);
    }

    public static ConResult success(Object data) {
        return new ConResult(true, null, data);
    }

    public static ConResult success(String message, Object data) {
        return new ConResult(true,message,data);
    }

    public static ConResult fail() {
        return fail("操作失败请重试!");
    }

    public static ConResult fail(String message) {

        if (StringUtils.isEmpty(message) || message.indexOf("Exception") > 0) {
            message = DEFAULT_ERROR_MESSAGE;
        }
        return new ConResult(false,message,null);
    }


    public ConResult(boolean success, String message, Object data) {
        this.success = success;
        this.message = message;
        this.data = data;
    }

    public boolean isSuccess() {
        return success;
    }

    public String getMessage() {
        return message;
    }

    public Object getData() {
        return data;
    }
}
