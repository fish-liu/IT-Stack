package com.grow.demo.dao;

import com.grow.demo.model.Tag;
import com.grow.demo.util.BaseDao;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

/**
 * @author liuxw
 * @date 2020/7/6
 * @since 1.0
 */
@Mapper
@Repository
public interface ITagDao extends BaseDao<Tag> {



}
