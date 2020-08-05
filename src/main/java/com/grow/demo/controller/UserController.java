package com.grow.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * 用户相关controller
 * 改controller下的方法需要权限（需要登录）
 * @author liuxw
 * @since 1.0
 */
@Controller
@RequestMapping("/user")
public class UserController {

    /**
     * 用户首页
     */
    @RequestMapping("/")
    public String home(){
        return "user/home";
    }

    /**
     * 添加信息页
     * @return
     */
    @RequestMapping("/article")
    public String article(){
        return "user/article";
    }

    /**
     * 分类管理页
     * @return
     */
    @RequestMapping("/category")
    public String category(){
        return "user/category";
    }

    /**
     * 标签管理页
     * @return
     */
    @RequestMapping("/tags")
    public String tags(){
        return "user/tags";
    }


}
