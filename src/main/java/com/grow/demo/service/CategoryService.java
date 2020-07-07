package com.grow.demo.service;

import com.grow.demo.dao.ICategoryDao;
import com.grow.demo.model.Category;
import com.grow.demo.model.vo.CategoryVo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @author liuxw
 * @date 2020/7/7
 * @since 1.0
 */
@Service
public class CategoryService extends AbstractBaseService<Category> {

    @Autowired
    private ICategoryDao iCategoryDao;

    /**
     * 获取分类列表
     * @param uid
     * @return
     */
    public List<CategoryVo> getCategoryList(Integer uid){
        return iCategoryDao.getCategoryList(uid);
    }

}
