package com.fish.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * @author liuxw
 * @date 2020/6/29
 * @since 1.0
 */
@Controller
public class IndexController {


    @RequestMapping("/")
    public String index(){
        return "index";
    }

    @RequestMapping("/test1")
    @ResponseBody
    public String test1(){
        return "test1";
    }

}
