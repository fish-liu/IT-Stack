
本文转载自 ：https://blog.csdn.net/u010013573/article/details/88372175


### 概述

- MySQL为了实现数据的安全性和故障可恢复性（MySQL自身故障导致或者主机断电之类导致MySQL服务器异常退出的场景，对于主机磁盘损坏之类的故障无法恢复），对于数据的所有增删改操作在对相应的数据表进行写入之前，支持先记录到一个二进制日志中，即支持Write log ahead策略，然后在进行数据文件的写入操作。

- 对于事务操作，每个事务操作提交之前，也会先将事务内的修改操作记录到二进制日志中，然后在执行事务提交，所以二进制日志也是事务安全的。

- 由于开启二进制日志功能时，每次写入操作都要进行二进制日志写入和数据文件写入两次写入操作，故在一定程度上会影响写入操作的性能，故默认情况下MySQL的二进制日志功能是关闭的，具体可以如下查看：

```linux
mysql> show variables like 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | OFF   |
+---------------+-------+
1 row in set (0.00 sec)
```

- 二进制日志的内容可以是基于被修改的数据行Row或者基于SQL语句Statement，具体下面分析。


### 启用二进制日志功能

- 如果需要打开二进制日志功能，则需要在配置文件my.cnf的[mysqld]节点下面添加如下配置：即配置二进制文件的文件目录，然后重启MySQL服务器则可以打开二进制日志功能：

```linux
vi /etc/my.cnf

[mysqld]
log-bin=/data/logs/mysql/mysql-bin

或者（以下三行配置与上面一行配置等价）

[mysqld]
log_bin=ON # 打开binlog日志
log_bin_basename=/data/logs/mysql/mysql-bin # binlog日志的基本文件名，后面会追加标识来表示每一个文件
log_bin_index=/data/logs/mysql/mysql-bin.index # 指定的是binlog文件的索引文件，这个文件管理了所有的binlog文件的目录

# MySQL5.7以后版本，需要添加server-id，server-id不能与集群其他机器重复
server-id=1
```

- 打开二进制日志之后，在/data/logs/mysql/mysql-bin目录下面就会存在类似于：mysql-bin.000001，mysql-bin.00002 …之类的文件，这些就是记录了MySQL数据库数据修改的二进制日志文件。


### 定制所需的二进制日志

- 除了配置log-bin启用二进制日志之外，还需要配置一下参数来定制二进制日志，即可以指定对某些数据库的数据进行二进制日志记录，忽略某些数据库的记录，从而可以优化性能：

```linux
max_binlog_size：指定binlog的最大存储上限，超过时自动创建一个新的日志文件进行记录；
binlog-do-db=db_name：指定只对该数据库进行二进制日志记录，忽略其他的二进制日志记录；
binlog-ignore-db=db_name：忽略该指定的数据库的二进制日志记录，会对其他数据库进行二进制日志记录。
```

- 如下MySQL5.7的binlog默认大小为1G左右：

```linux
mysql> show variables like '%max_binlog_size%';
+-----------------+------------+
| Variable_name   | Value      |
+-----------------+------------+
| max_binlog_size | 1073741824 |
+-----------------+------------+
1 row in set (0.01 sec)
```

### 二进制日志的内容格式

- 二进制日志的内容格式可以基于数据行Row、语句Statement和二者混杂Mixed三种种格式之一。由于MySQL主从复制是基于二进制日志实现的，故二进制日志的内容格式也直接影响了主从复制的行为。

  - 1、基于数据行Row：将数据被修改的数据行传给从库，这种方式的优点是只记录数据修改，不需要记录SQL的上下文信息，兼容性较好；缺点是如果是批量操作、ALTER修改表操作，则会产生大量的二进制日志，导致大量的数据传输，大量消耗网络带宽资源，对主从库主机的IO影响较大。

  - 2、基于语句Statement：将修改数据的SQL语句发送给从库，然后在从库直接执行即可，这种方式的优点是减少二进制日志量，传输数据量小，不受批量操作的影响，缺点是主从库之间的MySQL版本需要保持严格一致，否则可能出现主库中产生的SQL在从库无法执行的问题，其次是需要保持主从库之间的SQL上下文一致，即SQL如果涉及函数，存储过程之类的，则需要保证从库也需要有主库上的这些函数，存储过程，否则从库无法执行这条SQL语句。如下为使用MySQL自带的mysqlbinlog查看binlog的内容：

  ```linux
  # at 552
  ## 执行时间:17:50:46；pos点:665
  #131128 17:50:46 server id 1  end_log_pos 665   Query   thread_id=11    exec_time=0     error_code=0 
  SET TIMESTAMP=1385632246/*!*/;
  update t_user set name='xyz' where id=1             ## 执行的SQL
  /*!*/;
  # at 665
  #131128 17:50:46 server id 1  end_log_pos 692   Xid = 1454  ## 执行时间:17:50:46；pos点:692 
  
  注：
  server id 1     数据库主机的服务号
  end_log_pos 665 pos点
  thread_id=11    线程号
  ```

  - 3、Mixed混杂模式：所以一般需要结合以上两种方式来实现复制，即Mixed模式。

- MySQL5.1.5之前的版本只支持基于Statement的复制，MySQL5.1.5及其之后版本支持基于Row的复制，MySQL5.1.8及其之后版本支持基于Mixed的复制。默认为基于Statement。

- 可以在my.conf配置来修改二进制日志的格式：推荐使用Mixed。

```linux
[mysqld]
#设置日志格式
binlog_format = mixed
```

### 主从复制二进制日志实现数据同步

- MySQL主从复制就是基于二进制日志实现的，即在主库和从库之间复制二进制日志，从库解析该二进制日志获取主库的修改操作，然后在从库重新执行，从而保证相应的数据在从库也得到了修改。

