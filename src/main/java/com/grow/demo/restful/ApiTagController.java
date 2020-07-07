package com.grow.demo.restful;

import com.grow.demo.common.ConResult;
import com.grow.demo.model.Tags;
import com.grow.demo.service.TagService;
import io.swagger.annotations.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

/**
 * @author liuxw
 * @since 1.0
 */
@Api(tags = "tag 接口API")
@RestController
@RequestMapping("/api/tag")
public class ApiTagController {

    @Autowired
    private TagService tagService;

    @ApiOperation(value = "添加tag",notes = "用户id，分类id必填，tag名称不能为空")
    @ApiImplicitParams({
            @ApiImplicitParam(paramType="query", name = "uid", value = "用户id", required = true, dataType = "Integer"),
            @ApiImplicitParam(paramType="query", name = "cateId", value = "分类id", required = true, dataType = "Integer"),
            @ApiImplicitParam(paramType="query", name = "tagName", value = "tag名称", required = true, dataType = "String")
    })
    @ApiResponses({
            @ApiResponse(code = 200, message = "成功")
    })
    @RequestMapping(value = "/add",method = RequestMethod.POST)
    public ConResult addTag(@RequestParam(value="uid") Integer uid,
                            @RequestParam(value="cateId") Integer cateId,
                            @RequestParam(value="tagName") String tagName
                            ){
        if(uid == null || uid == 0){
            return ConResult.fail();
        }

        if(cateId == null || cateId == 0){
            return ConResult.fail();
        }

        if(StringUtils.isEmpty(tagName)){
            return ConResult.fail();
        }

        Tags tag = Tags.builder().uid(uid).cateId(cateId).tagName(tagName).build();

        if(tagService.save(tag) > 0){
            return ConResult.success(tag.getId());
        }else {
            return ConResult.fail();
        }

    }

    @ApiOperation(value = "修改tag",notes = "根据tagId修改tag名称")
    @RequestMapping(value = "/update",method = RequestMethod.POST)
    public ConResult updateTag(){

        Tags tag = Tags.builder().id(1).tagName("").build();
        if(tagService.update(tag)>0){
            return ConResult.success();
        }else {
            return ConResult.success();
        }
    }

    /**
     * 根据id删除tag
     * @param id
     * @return
     */
    @ApiOperation(value = "删除tag",notes = "根据tagId删除tag")
    @RequestMapping(value = "/delete/{id}",method = RequestMethod.GET)
    public ConResult deleteTag(@PathVariable("id") Integer id){

        if(tagService.deleteById(id) > 0){
            return ConResult.success("删除成功");
        }else {
            return ConResult.fail("删除失败");
        }
    }

}
