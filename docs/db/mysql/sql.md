
本文转载自 ： https://blog.csdn.net/u010013573/article/details/88834130


**SQL解析顺序与MySQL底层实现** 

-------


### SQL语句的核心元素

SQL语句的核心组成如下：其他复杂查询，如子查询，UNION等也是基于这些元素来构成的，只是MySQL服务器对结果进行了处理。

```sql
SELECT DISTINCT
    < select_list >
    
FROM
    < left_table > < join_type >
JOIN < right_table > ON < join_condition >

WHERE
    < where_condition >
    
GROUP BY
    < group_by_list >
HAVING
    < having_condition >
    
ORDER BY
    < order_by_condition >
LIMIT < limit_number >
```


### MySQL对SQL的解析顺序

MySQL server接收到查询请求后，按以下顺序执行该SQL：

- 1、确定从哪些表查找数据，主要是处理FROM和JOIN语句。

```sql
FROM <left_table>
ON <join_condition>
<join_type> JOIN <right_table>
```

- 2、在这些表根据WHERE语句指定的条件，查找数据列的值符合查询条件的数据行。

```sql
WHERE <where_condition>
```


- 3、确定和获取所需要哪些数据行之后，则对这些数据行依次进行分组，排序，确定所需的数据列，最后根据LIMIT决定需要返回多少数据给客户端。

  - 分组：HAVING一般与GROUP BY一起使用，弥补了WHERE不能使用聚合函数的不足。通常GROUP BY之后一般也需要在SELECT中使用聚合函数进行统计计算，常见的聚合函数包含：SUM, COUNT, AVG，MAX, MIN。
  
  ```sql
  GROUP BY <group_by_list>
  HAVING <having_condition>
  ```

  例子1：每个学生所选的课程门数以及每个学生的平均分数：

  ```sql
  SELECT id, COUNT(course) as numcourse, AVG(score) as avgscore
  FROM student
  GROUP BY id
  ```

  例子2：在例子1的基础上，查询平均分高于80分的学生记录：

  ```sql
  SELECT id, COUNT(course) as numcourse, AVG(score) as avgscore
  FROM student
  GROUP BY id
  HAVING AVG(score)>=80;
  ```

  - 排序：

  ```sql
  ORDER BY <order_by_condition>
  LIMIT <limit_number>
  ```
  
  这里是指拿到结果之后的排序，而通常这种是性能比较低的情况，通过explain分析SQL，如果Extra显示Using filesort则是这种情况。

  一般会借助有序索引来排序，即如果order by的列是加了有序索引（MySQL的B-TREE），则可以在存储引擎层就完成了排序。但是这里有个前提条件是该列必须是where中的其中一个条件并且该条件符合使用索引的规则，如下：

  order by的列trade_date不在where中，extra显示Using filesort，表示使用外部排序，不能使用有序索引来排序：

  ```sql
  mysql> explain select trade_date from store_order_day where ul='11111' order by trade_date
      -> ;
  +----+-------------+-------------------+------------+------+------------------------+------------------------+---------+-------+------+----------+------------------------------------------+
  | id | select_type | table             | partitions | type | possible_keys          | key                    | key_len | ref   | rows | filtered | Extra                                    |
  +----+-------------+-------------------+------------+------+------------------------+------------------------+---------+-------+------+----------+------------------------------------------+
  |  1 | SIMPLE      | store_order_day   | NULL       | ref  | idx_ul_type_order_price | idx_ul_type_order_price | 768     | const |    5 |   100.00 | Using where; Using index; Using filesort |
  +----+-------------+-------------------+------------+------+------------------------+------------------------+---------+-------+------+----------+------------------------------------------+
  1 row in set, 1 warning (0.00 sec)
  ```

  当把order by的列trade_date加到where查询条件时，则extra不再存在Using filesort，可以使用索引排序了，故不会走到这步拿到结果再排序：
  
  ```sql
  mysql> explain select trade_date from store_order_day where ul='11111' and trade_date='2019-03-25' order by trade_date;
  +----+-------------+-------------------+------------+------+--------------------------------+---------+---------+-------+------+----------+-------------+
  | id | select_type | table             | partitions | type | possible_keys                  | key     | key_len | ref   | rows | filtered | Extra       |
  +----+-------------+-------------------+------------+------+--------------------------------+---------+---------+-------+------+----------+-------------+
  |  1 | SIMPLE      | store_order_day | NULL       | ref  | PRIMARY,idx_ul_type_order_price | PRIMARY | 3       | const |    1 |    16.67 | Using where |
  +----+-------------+-------------------+------------+------+--------------------------------+---------+---------+-------+------+----------+-------------+
  1 row in set, 1 warning (0.00 sec)
  ```

  - 选择需要的列

  ```sql
  SELECT 
  DISTINCT SUM COUNT <select_list>
  ```

  - 需要返回多少行数据

  ```sql
  LIMIT <limit_number>
  ```


### MySQL的server层和存储引擎层的处理

#### 存储引擎层

- 存储引擎负责将数据存储到磁盘和从磁盘读取数据，并且维护了索引实现，从而可以快速检索定位到查询需要的数据行。

- 在SQL语句中，存储引擎层主要处理FROM和JOIN中涉及的表，WHERE的查询条件中涉及的包含索引的列，但是前提是WHERE中各列的查询规则符合存储引擎的索引使用规则，如多个列对于联合索引需要满足B+Tree的最左前戳匹配规则；列需要是独立的列，即不能包含相关函数，如WHERE a+1=4，即使列a加了索引也没法使用，而应该使用WHERE a=3。

- 存储引擎层的整体执行过程为：

  - 首先在查询条件中包含索引的列所对应的索引中进行查找，过滤得出需要读取数据表中的哪些数据行，根据索引中的这些数据行位置指针回表读取这些数据行的数据；

    或者如果没有索引可用，则需要读取整个数据表的所有数据行；

    或者如果索引已经可以覆盖到需要查询的数据，则不需要读取数据表中的数据行了。

  - 根据索引查找到对应的数据行之后，则需要将这些数据行返回给server层。server层基于WHERE语句中其他不能使用索引来过滤的条件，对存储引擎层返回的数据行进行进一步过滤。

- 数据行：如果该查询符合索引覆盖，则只返回索引数据给server层，即通过explain分析时Extra显示Using index；否则存储引擎需要回表获取完整的数据行返回给server层，如果是全表扫描，需要将整个表的所有完整的数据行返回给server层，这种情况很造成很严重的性能问题，即非常缓慢和消耗大量的系统资源。


#### server层

- server层从存储引擎层获取需要的数据行，然后进一步处理WHERE语句的条件，进一步进行数据过滤。确定需要的数据行集合之后，则需要根据SQL语句的定义，依次处理GROUP BY，HAVING，ORDER BY，SELECT，LIMIT这些语句，最终将处理好的数据返回给客户端。

