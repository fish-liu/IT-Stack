package com.grow.demo.controller;

import com.grow.demo.common.enums.CategoryTypeEnum;
import com.grow.demo.common.enums.StatusEnum;
import com.grow.demo.common.enums.TagGroupEnum;
import com.grow.demo.common.enums.TagsTypeEnum;
import com.grow.demo.model.Category;
import com.grow.demo.model.Tags;
import com.grow.demo.service.CategoryService;
import com.grow.demo.service.TagService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * @author liuxw
 * @date 2020/6/29
 * @since 1.0
 */
@Controller
public class IndexController {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private TagService tagService;

    @RequestMapping("/")
    public String index(){
        return "index";
    }

    @RequestMapping("/test1")
    @ResponseBody
    public String test1(){
        return "test1";
    }


    @RequestMapping("/init")
    @ResponseBody
    public String initSystem(){

        Category category = Category.builder()
                .type(CategoryTypeEnum.DEFAULT.getCode())
                .categoryName("其他")
                .status(StatusEnum.NORMAL.getCode())
                .build();

        categoryService.save(category);



        for(int i =0 ; i < 3; i++){

            Category cate = Category.builder()
                    .type(CategoryTypeEnum.PUBLIC.getCode())
                    .categoryName("分类"+i)
                    .status(StatusEnum.NORMAL.getCode())
                    .build();

            categoryService.save(cate);
        }


        Tags tag = Tags.builder()
                .groupId(TagGroupEnum.INTEREST.getCode())
                .type(TagsTypeEnum.PUBLIC.getCode())
                .tagName("")
                .build();

        tagService.save(tag);

        return "success";

    }





}
