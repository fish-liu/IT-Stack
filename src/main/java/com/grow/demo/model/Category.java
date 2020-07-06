package com.grow.demo.model;

import lombok.Data;

import java.util.Date;

/**
 * @author liuxw
 * @since 1.0
 */
@Data
public class Category {

    /**
     * 主键
     */
    private Integer id;

    /**
     * 分类名
     */
    private String categoryName;

    /**
     * 用户id
     */
    private Integer uid;

    /**
     * 状态，0=正常，1=禁用，2=删除
     */
    private int status;

    /**
     * 记录生产的时间
     */
    private Date createTime;

    /**
     * 记录的最新更新时间
     */
    private Date updateTime;
}
