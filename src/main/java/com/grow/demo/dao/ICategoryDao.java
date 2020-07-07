package com.grow.demo.dao;

import com.grow.demo.model.Category;
import com.grow.demo.model.vo.CategoryVo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * @author liuxw
 * @since 1.0
 */
@Mapper
@Repository
public interface ICategoryDao extends BaseDao<Category> {

    /**
     * 获取分类列表
     * @param uid
     * @return
     */
    List<CategoryVo> getCategoryList(@Param("uid") Integer uid);

}
