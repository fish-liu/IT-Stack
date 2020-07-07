package com.grow.demo.restful;

import com.grow.demo.common.ConResult;
import com.grow.demo.common.enums.StatusEnum;
import com.grow.demo.model.Category;
import com.grow.demo.model.vo.CategoryVo;
import com.grow.demo.service.CategoryService;
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
@Api(tags = "category 接口API")
@RestController
@RequestMapping("/api/category")
public class ApiCategoryController {

    @Autowired
    private CategoryService categoryService;

    @ApiOperation(value = "添加category",notes = "用户id，category名称不能为空")
    @ApiImplicitParams({
            @ApiImplicitParam(paramType="query", name = "uid", value = "用户id", required = true, dataType = "Integer"),
            @ApiImplicitParam(paramType="query", name = "categoryName", value = "category名称", required = true, dataType = "String")
    })
    @RequestMapping(value = "/add",method = RequestMethod.POST)
    public ConResult addCategory(@RequestParam("uid") Integer uid,
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

        if(categoryService.save(category) > 0){
            return ConResult.success(category.getId());
        }else {
            return ConResult.fail("添加分类失败");
        }
    }


    @ApiOperation(value = "禁用Category",notes = "根据Id禁用Category")
    @RequestMapping(value = "/disable/{id}",method = RequestMethod.GET)
    public ConResult disableCategory(@ApiParam(name = "id",value = "分类id") @PathVariable("id")Integer id){

        if(categoryService.updateStatusById(id,StatusEnum.DISABLE.getCode()) > 0){
            return ConResult.success("操作成功",null);
        }else {
            return ConResult.fail("操作失败");
        }
    }

    @ApiOperation(value = "获取CategoryList",notes = "根据用户id获取该用户的Category列表")
    @RequestMapping(value = "/list/{uid}",method = RequestMethod.GET)
    public ConResult<List<CategoryVo>> getCategoryList(@ApiParam(name = "uid",value = "用户id") @PathVariable("uid")Integer uid){

        return ConResult.success(categoryService.getCategoryList(uid));
    }

    /**
     * 修改Category，暂时用不到
     * @return
     */
    public ConResult updateCategory(){
        return ConResult.success();
    }


}
