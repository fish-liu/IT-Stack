package com.grow.demo.restful;

import com.grow.demo.common.ConResult;
import com.grow.demo.common.enums.StatusEnum;
import com.grow.demo.model.Category;
import com.grow.demo.model.vo.ArticleVo;
import com.grow.demo.service.ArticleService;
import io.swagger.annotations.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * @author liuxw
 * @date 2020/7/7
 * @since 1.0
 */
@Api(tags = "article 接口API")
@RestController
@RequestMapping("/api/article")
public class ApiArticleController {

    @Autowired
    private ArticleService articleService;

    @ApiOperation(value = "添加article",notes = "用户id，category名称不能为空")
    @ApiImplicitParams({
            @ApiImplicitParam(paramType="query", name = "uid", value = "用户id", required = true, dataType = "Integer"),
            @ApiImplicitParam(paramType="query", name = "categoryName", value = "category名称", required = true, dataType = "String")
    })
    @RequestMapping(value = "/add",method = RequestMethod.POST)
    public ConResult addArticle(@RequestParam("uid") Integer uid,
                                 @RequestParam("categoryName") String categoryName){

        if(uid == null || uid == 0){
            return ConResult.fail("用户id不正确");
        }

        if(StringUtils.isEmpty(categoryName)){
            return ConResult.fail("分类名称不能为空");
        }

        Category category = Category.builder()
                .uid(uid)
                .categoryName(categoryName)
                .status(StatusEnum.NORMAL.getCode())
                .build();

        //if(articleService.save(category) > 0){
        //    return ConResult.success(category.getId());
        //}else {
            return ConResult.fail("添加分类失败");
        //}
    }

    @ApiOperation(value = "删除article",notes = "根据Id禁用Category")
    @RequestMapping(value = "/delete/{id}",method = RequestMethod.GET)
    public ConResult deleteArticle(@ApiParam(name = "id",value = "分类id") @PathVariable("id")Integer id){

        if(articleService.updateStatusById(id,StatusEnum.DISABLE.getCode()) > 0){
            return ConResult.success("操作成功",null);
        }else {
            return ConResult.fail("操作失败");
        }
    }

    @ApiOperation(value = "获取articleList",notes = "根据用户id获取该用户的article列表")
    @RequestMapping(value = "/list/{uid}",method = RequestMethod.GET)
    public ConResult<List<ArticleVo>> getArticleList(@ApiParam(name = "uid",value = "用户id") @PathVariable("uid")Integer uid){
        //articleService.getCategoryList(uid)
        return ConResult.success();
    }

}
