
本文转载自 ：https://blog.csdn.net/u010013573/article/details/88363587

### 概述
- MySQL作为一个数据存储系统，核心功能为存储数据和读取数据。在数据存储方面，MySQL是基于文件系统或者说是磁盘来进行数据保存的，即数据都是保存为磁盘上的一个个文件；在数据读取方面，MySQL作为一个关系型数据库，在应用代码中使用SQL语句来定义需要查找获取的数据，然后通过MySQL服务器执行该SQL从磁盘文件中读取对应的数据返回给应用。

- MySQL作为一个后台数据存储软件，也是采用C/S架构，基于TCP/IP进行通信的，所以应用代码需要进行数据存储时，需要通过MySQL客户端首先与MySQL服务端建立连接，然后才能进行后续的存取操作。


### 整体架构
在MySQL的整体架构设计当中，主要包括连接层，SQL解析层，数据存储层或者说是存储引擎层。

   1、 连接层负责与应用代码建立数据通信的连接，在这里包括了身份认证和TCP连接建立，处理线程分配；
   
   2、 SQL层主要处理连接层接收到的数据操作相关请求，解析对应SQL语句，明白应用代码需要对什么数据进行何种操作，以及检查当前用户是否有权限对指定数据库和数据表进行访问和操作；
   
   3、数据存储层主要是被SQL层用来访问磁盘上的数据文件，对数据文件进行数据读写操作，即对于数据存储则从SQL层获取数据然后保存到对应的数据文件中，对应数据读取则加载读取对应的数据文件，然后将给定的数据返回给SQL层。（图片引自《高性能MySQL》）
   ![Mysql服务器架构设计图](/images/design.jpg)
   
   
#### 连接层
在连接层主要负责接收MySQL客户端的连接请求，在客户端和服务端之间建立TCP连接，由于MySQL服务端是基于单进程多线程架构，对于每一个客户端连接都会使用一个单例线程进行处理。

**1、连接和线程管理**
  
  - MySQL服务器支持的最大线程数量或者说MySQL服务器支持的最大并发连接数由max_conecctions控制，如下表示当前的MySQL服务器最多可以支持151个连接同时存在：

    ```linux
    mysql> show variables like '%max_connections%';
    +-----------------+-------+
    | Variable_name   | Value |
    +-----------------+-------+
    | max_connections | 151   |
    +-----------------+-------+
    1 row in set (0.00 sec)
    ```

  - 当前存在的连接数可以通过connections查看：如下表示当前存在5个数据库连接。
    
    ```linux
    mysql> show status like 'connections';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | Connections   | 5     |
    +---------------+-------+
    1 row in set (0.00 sec)
    ```

  - 如果当前总连接数达到了max_conecctions，则后续的连接会放在一个连接等待队列back_log中，如下：表示当前MySQL服务器的back_log最大长度为80个，所以结合以上max_connections，当前MySQL服务器最多能支持151+80=231个连接，超过的则根据TCP的backlog溢出处理，丢弃后续的TCP连接。

    ```linux
    mysql> show variables like '%back_log%';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | back_log      | 80    |
    +---------------+-------+
    1 row in set (0.00 sec)
    ```

**2、 身份认证**

  - 建立好TCP连接之后，则是基于客户端主机host，用户名username和密码password进行身份认证，即判断当前客户端是否有权限对该MySQL服务器进行连接。

  - 先判断该客户端所在的主机是否有权对该MySQL服务器进行连接，如果无权访问则直接返回权限不足，断开连接。如果主机认证通过，则基于用户名和密码来决定是否可以连接该MySQL服务器，即用户名和密码是否正确。

  - 在MySQL服务器中，身份认证相关的定义主要在MySQL的自带数据库mysql的user表定义，如下：user表关于身份认证相关的字段主要为：host, user, password（在MySQL5.7之后，使用authentication_string字段替代了password，在设置authentication_string的值时，使用password()函数），除此之外user表还包含其他权限控制相关的字段，如指定数据库，指定数据表的相关操作权限。

    ```linux
    mysql> use mysql;
    Database changed
    mysql> select host, user, authentication_string from user order by user;
    +-----------+---------------+-------------------------------------------+
    | host      | user          | authentication_string                     |
    +-----------+---------------+-------------------------------------------+
    | localhost | mysql.session | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE |
    | localhost | mysql.sys     | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE |
    | localhost | root          | *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B |
    | %         | stock_trade   | *CA860E408806A64DCFA3CF901C1652D9E1670D78 |
    | localhost | wpf           | *97BEDA7DA91BAB6A8B5779774F02A3463152E77B |
    +-----------+---------------+-------------------------------------------+
    5 rows in set (0.01 sec)
    ```

  - host字段中可以直接指定ip，域名或者使用%表示该用户可以从任意主机连接过来，或者统配作用如：192.168.1.%，具体匹配规则可以查看MySQL官方文档：6.2.4 Access Control, Stage 1: Connection Verification

  - 在user表添加，更新，删除访问用户如下：
  
    ```linux
    mysql> create user 'test_user'@'%' identified by '123456';
    Query OK, 0 rows affected (0.04 sec)
    
    mysql> update user set authentication_string=password('1234567') where user='test_user';
    Query OK, 1 row affected, 1 warning (0.05 sec)
    Rows matched: 1  Changed: 1  Warnings: 1
    
    mysql> drop user 'test_user'@'%';
    Query OK, 0 rows affected (0.00 sec)
    ```

**3、 权限控制**
  
    权限控制主要用于控制已经通过身份认证的用户，提交SQL请求对数据库进行的相关操作和访问，具体请看：MySQL权限控制
   
    
#### SQL层

- 当MySQL客户端与MySQL服务器建立好连接并且通过身份认证之后，则应用可以通过MySQL客户端发送包含SQL语句的请求到MySQL服务端执行。MySQL服务器接收到该请求之后，分发到SQL层进行SQL解析和执行。其中MySQL自身相关的命令command对应的SQL不需要经过以下解析执行过程，是直接执行的，如预处理命令Prepare（通常在MySQL慢日志会存在：administrator command: Prepare;）

- SQL层的核心组件为下图中的红框所示：（图片引自《MySQL性能调优与架构优化》）

![Mysql服务器架构设计图](/images/design1.png)


#### SQL执行过程

1、由上图可知，在SQL层，针对每个SQL语句，首先使用SQL命令解析器解析该SQL语句，具体为进行SQL的语义和语法分析，生成对应的语法解析树，从而可以确定该SQL语句的类型；

2、通过解析之后，根据SQL的类型，分发到对应的SQL处理器中，具体如下：
  - select语句：查询优化器，基于SQL执行的统计信息，对用户提交的SQL进行修改优化，生成对应的执行计划；
  - DML，即针对表的数据增删改：表变更模块，具体由insert 处理器、 delete 处理器、update 处理器、create 处理器这些小模块来负责不同的DML。
  - DDL，即针对表结构的修改，如ALTER：表维护模块，具体由 alter处理器等这些小模块来负责不同的DDL的；
  - 主从同步复制请求：复制模块，主要是读取二进制日志binlog然后发送给从库客户端；
  - MySQL运行状态查询：状态模块，如使用show status命令；

3、在各SQL处理器中，首先通过访问控制模块，即权限控制模块，分析提交该SQL的客户端对应的用户是否有所要访问或操作的数据库、数据表、数据表的字段的权限，如果权限不足则停止进行执行，否则调用存储引擎层的API交给存储引擎进行实际的数据存取操作。

**查询缓存QueryCache与查询优化器QueryOptimizer**

1、针对select查询请求，MySQL额外提供了查询缓存和查询优化器两个模块，其中查询缓存是用于缓存查询操作对应的结果集，即以查询语句和条件生成对应的hash值作为缓存的key，查询的结果集作为缓存的value，这样后续如果相同的请求则直接从该查询缓存返回对应的结果集即可，不需要进行相关的SQL解析与执行，从而提高性能。如果该被缓存的SQL中涉及的任意表发生了写操作，则MySQL会将该表相关的查询缓存删掉，避免脏数据产生。查询缓存默认是关闭的，如下：query_cache_type为OFF表示查询缓存是关闭的，其他变量含义为：

  - have_query_cache系统是否支持查询缓存，
  - query_cache_limit能缓存的单个结果集的最大大小（字节），默认为1M；
  - query_cache_min_res_unit启用缓存的最小结果集，默认为4K，
  - query_cache_size为系统用于查询缓存的内存大小，可修改。
  
```linux
mysql> show variables like '%query_cache%';
+------------------------------+---------+
| Variable_name                | Value   |
+------------------------------+---------+
| have_query_cache             | YES     |
| query_cache_limit            | 1048576 |
| query_cache_min_res_unit     | 4096    |
| query_cache_size             | 1048576 |
| query_cache_type             | OFF     |
| query_cache_wlock_invalidate | OFF     |
+------------------------------+---------+
6 rows in set (0.01 sec)
```

2、开启查询缓存需要修改配置文件my.cnf，然后重启MySQL服务器使之生效：

```linux
xyzdeMacBook-Pro:easy_web xyz$ mysql --verbose --help | grep my.cnf
                      order of preference, my.cnf, $MYSQL_TCP_PORT,
/etc/my.cnf /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf ~/.my.cnf 

vi /etc/my.cnf
在[mysqld]下面添加：
query_cache_size = 100M
query_cache_type = ON
```

3、之后可以通过以下命令来观察查询缓存的相关统计信息，从而分析查询缓存是否能高效命中：
```linux
mysql> show status like 'Qcache%';
+-------------------------+---------+
| Variable_name           | Value   |
+-------------------------+---------+
| Qcache_free_blocks      | 1       |
| Qcache_free_memory      | 1031832 |
| Qcache_hits             | 0       |
| Qcache_inserts          | 0       |
| Qcache_lowmem_prunes    | 0       |
| Qcache_not_cached       | 14      |
| Qcache_queries_in_cache | 0       |
| Qcache_total_blocks     | 1       |
+-------------------------+---------+
8 rows in set (0.01 sec)
```

4、查询优化器的主要功能是根据MySQL自身维护的一些统计信息，对用户提交的SQL进行修改优化，提供一个更高效的查询实现。


#### 数据存储层

数据存储层如下图红框所示：这层的主要作用是屏蔽底层存储引擎的实现细节，为SQL层提供一套进行数据存取的统一API，即存储引擎接口，从而实现可插拔的存储引擎实现。

![Mysql服务器架构设计图](/images/design2.png)

**存储引擎**

  - 存储引擎主要用于实现MySQL数据库的磁盘文件的组织、对数据文件进行数据存取，即接收SQL层的写请求将数据保存到对应的表的数据文件中，对于读请求，则加载对应表的磁盘文件的数据到内存中，然后返回给SQL层。
  
  - MySQL的存储引擎是一种可插拔的实现机制，即可以根据需要为每个表使用不同的存储引擎，如上图所示，常见的存储引擎包括：MyISAM，Innnodb，NDB，Memory，Archive等。

**数据文件**

  - MySQL数据库在物理上就是对应磁盘上的一个个数据文件，一般由表结构定义文件.frm，索引文件，数据文件这三种类型的文件组成，其中索引和数据可以在同一个文件中，而表结构定义文件是必需的。

  - 在磁盘文件组织方面，MySQL的每个数据库对应一个目录，每个目录里面包含这个数据库的表相关的定义文件和数据文件，如下：
  
    ```linux
    xyzdeMacBook-Pro:java-framework-demo xyz$ sudo chmod 777 /usr/local/mysql/data/
    xyzdeMacBook-Pro:java-framework-demo xyz$ cd /usr/local/mysql/data/
    // 数据库目录
    xyzdeMacBook-Pro:data xyz$ ls
    auto.cnf			ib_logfile0			mysqld.local.err		sys
    easy_log			ib_logfile1			mysqld.local.pid		turner
    easy_web			ibdata1				performance_schema		
    ib_buffer_pool			ibtmp1				mysql	xyzdeMacBook-Pro.local.err
    
    // 数据库内部的数据表文件
    xyzdeMacBook-Pro:data xyz$ sudo chmod 777 /usr/local/mysql/data/easy_web/
    xyzdeMacBook-Pro:data xyz$ cd easy_web/
    xyzdeMacBook-Pro:easy_web xyz$ ls
    db.opt		t_role.frm	t_role.ibd	t_user.frm	t_user.ibd	t_user_role.frm	t_user_role.ibd
    xyzdeMacBook-Pro:easy_web xyz$ ls -allh
    total 816
    drwxrwxrwx   9 _mysql  _mysql   288B 11  7 22:07 .
    drwxrwxrwx  21 _mysql  _mysql   672B  3  9 11:35 ..
    -rw-r-----   1 _mysql  _mysql    61B 11  7 11:42 db.opt
    -rw-r-----   1 _mysql  _mysql   8.4K 11  7 22:07 t_role.frm
    -rw-r-----   1 _mysql  _mysql   112K 11  7 22:10 t_role.ibd
    -rw-r-----   1 _mysql  _mysql   8.5K 11  7 22:07 t_user.frm
    -rw-r-----   1 _mysql  _mysql   128K 11  7 22:07 t_user.ibd
    -rw-r-----   1 _mysql  _mysql   8.4K 11  7 22:07 t_user_role.frm
    -rw-r-----   1 _mysql  _mysql   128K 11  7 22:10 t_user_role.ibd
    ```
						
  - 由上分析可知，存储引擎层主要进行数据存取，故不同的存储引擎在磁盘组织数据文件的方式也存在差异，以下主要以MyISAM存储引擎和Innodb存储引擎来分析：


#### MyISAM存储引擎

  - myisam存储引擎是MySQL自带的存储引擎，在MySQL5.1之前版本的默认存储引擎，myisam存储引擎相对于innodb存储引擎的不同之处是：不支持事务，不支持行锁，不支持外键约束，只对索引文件进行缓存，不对数据文件内容进行缓存，比较适合OLAP应用。
  
  - myisam的表相关的文件包括：表定义文件“.frm”，表索引文件“.MYI”，表数据文件“.MYD”，这三者类型的文件。


#### Innodb存储引擎

  - Innodb存储引擎是MySQL新版本的默认存储引擎，支持事务，行锁，外键约束，对数据文件和索引文件内容都进行缓存，非常适合OLTP应用。

  - Innodb的表相关文件包括：表定义文件“.frm”，表数据和索引文件".idb”，如以上easy_web数据库就是使用了Innodb存储引擎的。与myisam不同的是，Innodb的数据和索引是放在同一个文件的。

  - 对于".idb"文件，还存在一个类似的“idbdata”文件，不同之处为：如果Innodb存储引擎使用独享表空间，则每个表对应一个独立的".idb"文件；如果Innodb存储引擎使用共享表空间，则所有表共同使用一个（或多个）idbdata文件。

