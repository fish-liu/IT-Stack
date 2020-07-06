package com.grow.demo.service;

import com.grow.demo.dao.ITagDao;
import com.grow.demo.model.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * @author liuxw
 * @date 2020/7/6
 * @since 1.0
 */
@Service
public class TagService extends AbstractBaseService<Tag> {

    @Autowired
    private ITagDao iTagDao;

}
