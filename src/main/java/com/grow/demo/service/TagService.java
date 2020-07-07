package com.grow.demo.service;

import com.grow.demo.dao.ITagDao;
import com.grow.demo.model.Tags;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * @author liuxw
 * @since 1.0
 */
@Service
public class TagService extends AbstractBaseService<Tags> {

    @Autowired
    private ITagDao iTagDao;

}
