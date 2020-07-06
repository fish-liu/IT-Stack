package com.grow.demo.dao;

import com.grow.demo.model.Article;
import com.grow.demo.util.BaseDao;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

/**
 * @author liuxw
 * @since 1.0
 */
@Mapper
@Repository
public interface IArticleDao extends BaseDao<Article>{



}
