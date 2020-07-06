package com.grow.demo.util;

/**
 * @author liuxw
 * @since 1.0
 */
public interface BaseDao<T> {

    /**
     * 保存记录
     * @param t
     * @return
     */
    int save(T t);

    /**
     * 更新记录
     * @param t
     * @return
     */
    int update(T t);

    /**
     * 根据id更新状态
     * @param id
     * @param status
     * @return
     */
    int updateStatusById(Integer id,int status);

    /**
     * 根据id 删除记录
     * @param id
     * @return
     */
    int deleteById(Integer id);

}
