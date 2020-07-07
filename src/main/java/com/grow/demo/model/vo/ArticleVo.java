package com.grow.demo.model.vo;

import java.util.Date;
import java.util.List;

/**
 * @author liuxw
 * @date 2020/7/7
 * @since 1.0
 */
public class ArticleVo {

    private Integer id;

    /**
     * 文章内容
     */
    private String content;

    /**
     * 图片ids
     */
    private String imgIds;

    /**
     * 所属分类id
     */
    private Integer cateId;

    /**
     * 用户id
     */
    private Integer uid;

    /**
     * 可见度
     */
    private Integer visibility;

    /**
     * 位置信息
     */
    private String location;

    /**
     * 发布时间（可以发表之前的文章）
     */
    private Date publishTime;

    /**
     * 用到的tag
     */
    private List<TagsVo> tagList;

}
