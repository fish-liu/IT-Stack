package com.grow.demo.service;

import com.grow.demo.dao.IArticleDao;
import com.grow.demo.model.Article;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * @author liuxw
 * @since 1.0
 */
@Service
public class ArticleService extends AbstractBaseService<Article> {

    @Autowired
    private IArticleDao iArticleDao;
}
