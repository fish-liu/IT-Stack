package com.grow.demo.model.vo;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

/**
 * @author liuxw
 * @date 2020/7/7
 * @since 1.0
 */
@ApiModel
@Data
public class TagsVo {

    /**
     * 主键
     */
    @ApiModelProperty(value = "分类id",dataType = "Integer")
    private Integer tagId;

    /**
     * 标签名
     */
    @ApiModelProperty(value = "标签名",dataType = "String")
    private String tagName;

    /**
     * 标签所属的分类
     */
    @ApiModelProperty(value = "分类id",dataType = "Integer")
    private Integer cateId;

    /**
     * 用户id
     */
    @ApiModelProperty(value = "用户id",dataType = "Integer")
    private Integer uid;


}
