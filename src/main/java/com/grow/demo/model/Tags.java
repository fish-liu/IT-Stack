package com.grow.demo.model;

import lombok.Builder;
import lombok.Data;

import java.util.Date;

/**
 * @author liuxw
 * @since 1.0
 */
@Data
@Builder
public class Tags {

    /**
     * 主键
     */
    private Integer id;

    /**
     * 标签名
     */
    private String tagName;

    /**
     * 标签所属的分类
     */
    private Integer cateId;

    /**
     * 用户id
     */
    private Integer uid;

    /**
     * 状态 0=正常，1=禁用，2=删除
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
