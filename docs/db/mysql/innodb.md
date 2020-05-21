
本文转载自 ：https://blog.csdn.net/u010013573/article/details/89067671 和 

https://blog.csdn.net/u010013573/article/details/89072087 、 https://blog.csdn.net/u010013573/article/details/89075248 



### 锁与MVCC机制的实现原理


#### 一、概述

- 锁的主要作用是在并发访问时，锁住所操作的数据表，数据页或者数据行，MySQL中不同的存储引擎存在差异，从而避免多个客户端对同一个数据进行操作，导致数据不一致现象的发生。

- 锁根据是否需要对数据修改分为共享锁和排它锁，分记为S锁和X锁，其中S锁与S锁是共享的，S锁与X锁是互斥的，X锁与X锁也是互斥的，即数据读取SELECT操作使用共享锁，数据更新相关操作使用互斥锁。

- 在MySQL当中，myisam存储引擎使用的是表锁，innodb存储引擎使用的是行锁，其中锁的粒度越大，并发性能越差，所以OLTP应用一般使用innodb存储引擎，并发性能更好。

- 在innodb存储引擎的事务实现当中，行锁主要用来实现事务的ACID的I，即隔离性。不同事务之间，当需要对同一个数据行进行修改时，则第一个写事务加X锁之后，其他需要写事务需要阻塞。对于读事务，由于MVCC机制不需要对数据行加锁，故可以正常读数据，不过是最近的快照数据。


#### 二、MVCC机制

**1、MVCC机制与锁**

- 锁主要包含S锁和X锁，由于S锁与X锁互斥，故如果有其他事务对数据行加了X锁，则其他事务，不管是读事务还是写事务，再申请加S锁或X锁时，都需要阻塞，所以这样会影响并发性能。

- 在innodb存储引擎当中，由于默认隔离级别为REPEATABLE READ（可重复读），对于读操作SELECT，默认是使用MVCC机制实现一致性非锁定读，该机制不需要对数据行进行加锁，故不会占用和等待数据行上的锁，提供了并发性能。

**2、MVCC的实现基础**

- 基于undo日志快照，实现了MVCC机制，由于每个数据行可能存在多个版本的快照，故也称为多版本并发控制机制，实现了“一致性非锁定读”，在事务当中，读操作SELECT不需要加锁，而是读取undo日志中的最新快照。其中undo日志为用来实现事务回滚，本身没有带来额外的开销，过程如下：

![Mysql - MVCC](/images/mvcc.png)


**3、MVCC与事务隔离级别**

- 在innodb存储引擎中，不是所有的事务隔离级别都是使用MVCC机制的一致性非锁定读来提供并发性能。使用该机制的为REPEATABLE-READ可重复读和READ COMMITTED读提交，不过这两种机制所使用的数据行快照版本存在差别。

- 可重复读：基于事务开始时，读取的数据行版本，在事务过程中，不会改变，即对相同的数据行，如果事务本身没有进行修改，则多次SELECT返回相同的数据。

- 读提交：在事务期间，每次SELECT读取的都是最新的数据行数据快照，因为读提交这种事务隔离级别，不实现可重复读。

- 由于REPEATABLE-READ和READ-COMMITTED这两种事务隔离级别都使用了MVCC机制来实现一致性非锁定读，故如果读操作需要加锁的话，则需要显示加锁，如下：

```linux
SELECT ... FOR UPDATE; // 加X锁
SELECT ... LOCK IN SHARE MODE; // 加S锁
```

**4、MVCC机制与外键约束**

- 外键约束主要用来实现数据完整性，即主表和关联表之间的完整性。在关联表中进行UPDATE和INSERT等写事务时，首先需要SELECT父表，此时的SELECT读取父表不是基于MVCC机制来实现一致性非锁定读的，因为这样会产生数据不一致问题，如当前父表的数据行被其他事务修改了，而是需要对父表加S锁，即在内部实现当中对父表是使用：SELECT … LOCK IN SHARE MODE 来读取的，如果此处有其他事务对父表加X锁，则该操作需要阻塞。


#### 三、锁的实现

**1、索引与行锁**

- innodb存储引擎使用行锁来实现数据的并发安全性。不过并不是对所有的写事务都使用行锁，使用行锁的前提是：写事务对数据表的写操作的查找条件需要包含索引列，包含主键索引或者辅助索引，如UPDATE … SET … WHERE …中的WHERE列需要包含索引列，否则会使用表锁。

- 所以innodb的行锁锁在的其实是数据行的索引，如果是主键索引，由于主键索引是聚簇索引，故锁住的是数据行本身；如果是辅助索引，锁住的是该索引，而不是具体的数据行。

**2、锁的类型**

- 行锁只是一个比较泛的概念，在innodb存储引擎中，行锁的实现主要包含三种算法：

  1、Record-Key Lock：单个数据行的锁，锁住单条记录；
  
  2、Gap Lock：间隙锁，锁住一个范围，但是不包含数据行本身；
  
  3、Next-Key Lock：Record-Key Lock + Gap Lock，锁住数据行本身和一个范围的数据行。

- 所以innodb的行锁不是简单的锁住某一个数据行这个单条记录，而是根据更新条件，如WHERE中可能包含 > 等范围条件，和事务隔离级别来确定是锁住单条还是多条数据行。

**3、事务隔离级别与锁**

- a. REPEATABLE-READ：可重复读

  - 可重复读这种事务隔离级别使用的是Next-Key Lock这种锁，即锁住数据行本身和临近一个范围的数据行。不过如果查询条件只包含唯一索引且记录唯一，如=操作，则会降级为Record-Key Lock，只锁住该单独的数据行，如 UPDATE … SET … WHERE a=1，其中a为主键索引，则此处只锁住这条记录，而不是锁住周围的其他数据行。如果是辅助索引，则继续使用Next-Key Lock，即对于=操作，也会锁住周围的数据行。

  - REPEATABLE-READ使用Next-Key Lock这种锁算法的主要原因是：innodb存储引擎的可重复读实现是不存在幻读现象的，所以通过锁住一个范围来避免这个范围在当前事务操作过程中，进行了数据写入，如下：假如当前存a=1,2,5的数据行：

    ```linux
    SELECT * FROM t WHERE a >= 2 FOR UPDATE;
    ```

    如果使用Record-Key Lock，则是锁住a=2和a=5这两个数据行，但是期间其他事务可以插入a=4的数据行，当再次执行该SQL的时候，则数据就变成了2，4，5三个数据行了，存在幻读现象，不符合可重复读；

    所以在REPEATABLE-READ这种事务隔离级别下，以上SQL锁住的是(2, +无穷大)，这个范围的数据行，即只要a大于等于2的数据行都不能插入和更新，故插入a=4的数据行的事务需要阻塞。

- b. READ COMMITTED：读提交

  - READ-COMMITED这种事务隔离级别使用的是Record-Key Lock这种锁算法，只需要锁住当前SQL匹配的数据行即可，如上面的SQL，只需锁住a=2和a=5的数据行，其他事务可以插入a=4的数据行，故存在幻读现象。


#### 四、死锁检测

- 死锁的定义为：两个或多个事务在执行过程中，相互竞争资源而导致相互等待，导致都无法继续执行下去产生死锁的现象。

- 死锁的解决方法包含：阻塞回滚，超时回滚和主动检测回滚三种解决方法，其中阻塞回滚为只要遇到阻塞则立即回滚事务，超时回滚为阻塞超时之后回滚，这两种都是被动回滚，而主动检测回滚为innodb主动检测是否存在死锁，存在则回滚事务量最小的事务。

- 主动检测回滚：innodb使用了一个等待图算法来检测发生死锁的事务，如果发现某些事务存在等待环，则回滚这些事务中undo日志量最小的事务来解决死锁，如下：t1和t2之间存在死锁，其中图的节点为事务，边指向该事务等待的资源所在的其他事务。

![Mysql - checklock](/images/checklock.png)



### 事务实现机制


#### 一、概述

- 事务机制主要用于实现数据库对并发访问的支持和在并发访问下的数据一致性和可靠性。MySQL的myisam存储引擎是不支持事务的，通过表锁来实现数据的可靠性，类似于Java多线程的同步锁synchronized，避免并发修改，但是并发性能较差，比较适合OLAP的应用，同时数据库奔溃恢复比较麻烦。

- innodb存储引擎是支持事务的，支持多个客户端高性能地进行并发操作，相对myisam并发性能较好，比较适合OLTP的应用。innodb存储引擎实现了事务的ACID特性，即原子性，一致性，隔离性和持久性。

- ACID特性主要用于保证并发访问时，数据的一致性和可靠性，是对简单地进行加表锁实现串行化访问来保证数据一致性和可靠性的一种改进和优化，实现了多个客户端的并发访问。


#### 二、ACID实现

##### 1、SQL标准的ACID的定义：

  - A：原子性，一次数据库访问包含的多个数据库操作是一个整体，要么全部成功执行，要么全部失败回滚，相当于一个原子操作，不允许部分成功，部分失败；

  - C：一致性，事务执行前后，数据保持一致状态，不存在数据不一致问题；

  - I：隔离性，或者称为并发性，实现多个客户端的并发事务操作相互隔离，互不影响。不过这个在数据库实现当中，影响程度一般需要和并发性取一个折中，即定义了多个隔离级别，每个隔离级别的隔离程度和并发性存在差异，具体后面分析。

  - D：只要事务成功提交，则数据保证持久化保存，即使数据库奔溃也能恢复回来，保证数据的可靠性。


##### 2、Innodb的ACID实现

innodb存储引擎的原子性A和持久性D主要是通过redo重做日志来实现的，数据一致性除了redo日志外，需要undo日志来辅助实现，即当事务提交失败时，通过undo日志来实现回滚，取消该事务对数据库的操作。隔离性I主要是通过锁和MVCC机制来实现。

**a. redo日志：原子性、持久性**

  - redo日志主要是记录对数据的物理修改，在事务提交时，必须先将本次事务的所有修改写到redo日志中进行持久化，实现了原子性和持久性。redo日志写入成功之后才进行实际的事务提交，对数据库的数据进行实际的修改。

  - 所以redo日志记录了所有的数据修改操作，如果在事务提交时写入redo日志成功，再进行数据库修改时，数据库发送了崩溃，则可以在重启时，通过redo日志来恢复这些修改。如果事务提交之前，数据库奔溃，则该次事务操作的所有修改都没有执行，保证了原子性。

**b. undo日志：一致性**

  - 相对于redo日志记录数据的物理修改，undo日志是逻辑记录，是MySQL数据库内部的特殊的segment，segment内部对应每个事务都有一条记录，这个记录记录了该事务所有修改操作的逆过程。

  - 在事务操作过程中，每个修改操作都会记录在undo日志中，记录到undo日志的内容与该次修改操作相反，如INSERT对应DELETE，UPDATE则对应更新前的记录（这里记录了该数据的数据快照，负责实现了MVCC机制）。

  - 所以当该事务需要回滚时，只需要执行该事务对应的undo日志中的记录，即逆向的SQL语句，如插入了10条记录，则删除这10条记录。

  - 对于undo日志的删除，不是事务提交后就马上删除的，而是通过purge线程来完成的。由于MVCC机制是基于undo日志来实现，故该事务对应的数据行的快照数据可能被其他事务在引用，所以通过purge线程来检测是否存在其他事务在引用该数据行的快照，如果没有才进行该事务对应的undo日志的删除。

**c. 锁：隔离性**

  - 事务的隔离性主要是针对写操作，因为读操作是不会对数据进行修改，故不存在隔离的说法，通过隔离多个对相同的数据进行并发修改的事务，保证数据的一致性。
  
  - 对于数据的修改操作一般需要加互斥锁（记为X锁），如果一个事务对数据进行了加X锁，则其他需要修改该数据的事务就需要阻塞等待该事务释放该X锁才能继续执行，所以加锁操作直接影响了并发性能。基于并发性和数据一致性的考虑，隔离性定义了READ-UNCOMMITTED，READ-COMMITTED，REPEATABLE-READ, SERIALIZABLE这四个隔离级别，并发性能依次变差，数据一致性依次变强。


#### 三、隔离性

以上分析了事务的隔离性主要是通过锁和MVCC机制来实现，而隔离性主要是解决并发事务操作存在的以下问题，并通过事务隔离机制来规避这些问题，不过不是所有的隔离级别都会解决所有的这些问题，因为还需要与并发性取一个折中。

##### 1. 事务（并发操作）存在的问题

**a. 脏读**

  - 在一个事务内部读取到了其他未提交事务的数据修改，如果基于这些未提交的数据做计算或者更新，则如果发生事务回滚或其他事务之后又进行了修改，则会出现数据不一致问题。

**b. 幻读**

  - 在一个事务内部，两次读取的数据行数不一样，如其他事务进行数据插入或者数据删除操作。

**c. 不可重复读**

  - 在整个事务期间，如果存在其他事务对该数据进行了修改并成功提交了，则同一个数据的多次读取值不一样。

**d. 更新丢失**

  - 数据覆盖：一个事务覆盖了另外一个事务的执行结果；

  - 数据脏读：一个事务基于另外一个未提交事务的数据修改来做修改，当另外一个事务回滚后，当前事务基于该脏数据进行修改导致数据不一致。

##### 2. 隔离级别：锁与并发性能的权衡

为了解决以上并发事务操作存在的问题和与并发性取个折中，定义了以下四个隔离级别：

**a. READ-UNCOMMITTED：读未提交**

  - 没有解决以上的任何一个问题，读写均不需要加锁，数据一致性最差，并发性能最好，存在并发操作的应用，如OLTP，基本不会使用这个隔离级别；

**b. READ-COMMITTED：读提交**

  - 能够读取其他已提交事务的数据修改，不存在脏读和更新丢失问题，存在幻读和不可重复读问题。

**c. REPEATABLE-READ：可重复读**

  - 解决了以上的所有问题，即不存在脏读，幻读，不可重复读和更新丢失问题，这也是MySQL的innodb存储引擎的默认隔离级别。

  - 不可重复读的解决：读提交和可重复读的读操作都是基于MVCC机制来实现一致性无锁读取，区别在于可重复读是基于事务开始时的数据快照，整个事务期间不变，故多次读取数据一致；而读提交是基于数据的最新快照，即其他已提交事务的最新修改快照，故事务期间的两次读取可能不一样。

  - 幻读的解决：读提交和可重复读的写操作都是基于互斥行锁实现，但是二者使用的锁的算法存在差别，读提交只锁住匹配的行，可重复读锁住匹配的行和周围的行（间隙锁的存在），即可重复读需要锁住更多的数据行，其他事务不能对这些被锁住的行进行插入、删除操作，故不会新增或减少数据行，不存在幻读发生。具体可参考：：上面的MVCC机制的实现原理

  - REPEATABLE-READ，相对于SERIALIZABLE串行化，数据一致性方面唯一的不足是基于MVCC机制读取的数据的快照版本，故数据可能存在延迟。

**d. SERIALIZABLE：串行化**

  - 解决了以上的所有问题，对读写操作均需要加锁，读操作加共享锁，写操作加互斥锁，串行化了多个事务操作，并发性能最差，数据一致性最好。



### 索引的实现原理

#### 概述

- 在数据库当中，索引就跟书的目录一样用来加快数据的查找速度，对于一个SQL查询操作，根据索引快速过滤掉不符合要求的数据并定位到符合要求的数据，从而不需要扫描整个表来获取所需的数据。

- 在innodb存储引擎中，主要是基于B+树来实现索引，在非叶子节点存放索引关键字（所以如果建了多个独立索引，则对应多棵B+树，这样对于非主键索引，则叶子节点存放的是主键索引的主键值，需要通过二次查找主键索引所在的B+树获取对应的数据行，这也叫回表查询），在叶子节点存放数据记录（此时为主键索引或者说是聚簇索引，即数据行和索引存放在一起的索引）或者主键索引中的主键值（此时为非聚簇索引），所有的数据记录都在同一层，叶子节点，即数据记录直接之间通过指针相连，构成一个双向链表，从而可以方便地遍历到所有的或者某一范围的数据记录。


#### B树，B+树

- B树和B+树都是多路平衡搜索树，通过在每个节点存放更多的关键字和通过旋转、分裂操作来保持树的平衡来降低树的高度，从而减少数据检索的磁盘访问量。

- B+树相对于B树的一个主要的不同点是B+的叶子节点通过指针前后相连，具体为通过双向链表来前后相连，所以非常适合执行范围查找。具体可以参考：
数据结构-树（三）：[多路搜索树B树、B+树](others/ds/tree.md)

- innodb存储引擎的聚簇和非聚簇索引都是基于B+树实现的。


#### 主键索引

- innodb存储引擎使用主键索引作为表的聚簇索引，聚簇索引的特点是非叶子节点存放主键作为查找关键字，叶子节点存放实际的数据记录本身（也称为数据页），从左到右以关键字的顺序，存放数据记录，故聚簇索引其实就是数据存放的方式，所以每个表只能存在一个聚簇索引，innodb存储引擎的数据表也称为索引组织表。结构如下：（图片引自《MySQL技术内幕：Innodb存储引擎》）

![Mysql btree-index](/images/btree-index.png)


- 在查询当中，如果是通过主键来查找数据，即使用explain分析SQL的key显示PRIMARY时，查找效率是最高的，因为叶子节点存放的就是数据记录本身，所有可以直接返回，而不需要像非聚簇索引一样需要通过额外回表查询（在主键索引中）获取数据记录。

- 其次是对于ORDER BY排序操作，不管是正序ASC还是逆序DESC，如果ORDER BY的列是主键，则由于主键索引对应的B+树本身是有序的， 故存储引擎返回的数据就是已经根据主键有序的，不需要在MySQL服务器层再进行排序，提高了性能，如果通过explain分析SQL时，extra显示Using filesort，则说明需要在MySQL服务器层进行排序，此时可能需要使用临时表或者外部文件排序，这种情况一般需要想办法优化。

- 对于基于主键的范围查找，由于聚簇索引的叶子节点已经根据主键的顺序，使用双向链表进行了相连，故可以快速找到某一范围的数据记录。


#### 辅助索引

- 辅助索引也称为二级索引，是一种非聚簇索引，一般是为了提高某些查询的效率而设计的，即使用该索引列查询时，通过辅助索引来避免全表扫描。由于辅助索引不是聚簇索引，每个表可以存在多个辅助索引，结构如下：

![Mysql辅助索引](/images/secondary-index.jpg)


- 辅助索引的非叶子节存放索引列的关键字，叶子节点存放对应聚簇索引（或者说是主键索引）的主键值。即通过辅助索引定位到需要的数据后，如果不能通过索引覆盖所需列，即通过该辅助索引列来获取该次查询所需的所有数据列，则需要通过该对应聚簇索引的主键值定位到在聚簇索引中的主键，然后再通过该主键值在聚簇索引中找到对应的叶子页，从而获取到对应的数据记录，所以整个过程涉及到先在辅助索引中查找，再在聚簇索引（即主键索引）中查找（回表查询）两个过程。

- 举个例子：

  - 辅助索引对应的B+树的高度为3，则需要3次磁盘IO来定位到叶子节点，其中叶子节点包含对应聚簇索引的某个主键值；
  
  - 然后通过叶子节点的对应聚簇索引的主键值，在聚簇索引中找到对应的数据记录，即如果聚簇索引对应的B+树高度也是3，则也需要3次磁盘IO来定位到聚簇索引的叶子页，从而在该叶子页中获取实际的数据记录。
  
- 以上过程总共需要进行6次磁盘IO。故如果需要回表查询的数据行较多，则所需的磁盘IO将会成倍增加，查询性能会下降。所以需要在过滤程度高，即重复数据少的列来建立辅助索引。


##### Cardinality：索引列的数据重复度

- 由以上分析可知，通过辅助索引进行查询时，如果需要回表查询并且查询的数据行较多时，需要大量的磁盘IO来获取数据，故这种索引不但没有提供查询性能，反而会降低查询性能，并且MySQL优化器在需要返回较多数据行时，也会放弃使用该索引，直接进行全表扫描。所以辅助索引所选择的列需要是重复度低的列，即一般查询后只需要返回一两行数据。如果该列存在太多的重复值，则需要考虑放弃在该列建立辅助索引。

- 具体可以通过：SHOW INDEX FROM 数据表，的Cardinality的值来判断：

```linux
mysql> SHOW INDEX FROM store_order;
+---------------+------------+------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table         | Non_unique | Key_name   | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+---------------+------------+------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| store_order   |          0 | PRIMARY    |            1 | store_id    | A         |         201 |     NULL | NULL   |      | BTREE      |         |               |
| store_order   |          1 | idx_expire |            1 | expire_date | A         |          68 |     NULL | NULL   | YES  | BTREE      |         |               |
| store_order   |          1 | idx_ul     |            1 | ul          | A         |          22 |     NULL | NULL   | YES  | BTREE      |         |               |
+---------------+------------+------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
3 rows in set (0.01 sec)
```
- Cardinality表示索引列的唯一值的估计数量，如果跟数据行的数量接近，则说明该列存在的重复值少，列的过滤性较好；如果相差太大，即Cardinality / 数据行总数，的值太小，如性别列只包含“男”，“女”两个值，则说明该列存在大量重复值，需要考虑是否删除该索引。


##### 覆盖索引

由于回表查询开销较大，故为了减少回表查询的次数，可以在辅助索引中增加查询所需要的所有列，如使用联合索引，这样可以从辅助索引中获取查询所需的所有数据（由于辅助索引的叶子页包含主键值，即使索引没有该主键值，如果只需返回主键值和索引列，则也会使用覆盖索引），不需要回表查询完整的数据行，从而提高性能，这种机制称为覆盖索引。
当使用explain分析查询SQL时，如果extra显示 using index 则说明使用了覆盖索引返回数据，该查询性能较高。
由于索引的存在会增加更新数据的开销，即更新数据时，如增加和删除数据行，需要通过更新对应的辅助索引，故在具体设计时，需要在两者之间取个折中。


##### 联合索引与最左前戳匹配

- 联合索引是使用多个列作为索引，如（a,b,c)，表示使用a，b，c三个列来作为索引，由B+树的特征可知，索引都是需要符合最左前戳匹配的，故其实相当于建立a，（a,b），(a,b,c)三个索引。

- 所以在设计联合索引时，除了需要考虑是否可以优化为覆盖索引外，还需要考虑多个列的顺序，一般的经验是：查询频率最高，过滤性最好（重复值较少)的列在前，即左边。

**联合索引优化排序order by**

- 除此之外，可以考虑通过联合索引来减少MySQL服务端层的排序，如用户订单表包含联合索引(user_id, buy_date)，单列索引(user_id)：（注意这里只是为了演示联合索引，实际项目，只需联合索引即可，如上所述，(a,b)，相当于a, (a,b)两个索引）：

```linux
KEY `idx_user_id` (`user_id`),
KEY `idx_user_id_buy_date` (`user_id`,`buy_date`)
```

- 如果只是普通的查询某个用户的订单，则innodb会使用user_id索引，如下：

```linux
mysql> explain select user_id, order_id  from t_order where user_id = 1;
+----+-------------+---------+------------+------+----------------------------------+-------------+---------+-------+------+----------+-------------+
| id | select_type | table   | partitions | type | possible_keys                    | key         | key_len | ref   | rows | filtered | Extra       |
+----+-------------+---------+------------+------+----------------------------------+-------------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | t_order | NULL       | ref  | idx_user_id,idx_user_id_buy_date | idx_user_id | 4       | const |    4 |   100.00 | Using index |
+----+-------------+---------+------------+------+----------------------------------+-------------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```

- 但是当需要基于购买日期buy_date来排序并取出该用户最近3天的购买记录时，则单列索引user_id和联合索引（user_id, buy_date）都可以使用，innodb会选择使用联合索引，因为在该联合索引中buy_date已经有序了，故不需要再在MySQL服务器层进行一次排序，从而提高了性能，如下：

```linux
mysql> explain select user_id, order_id  from t_order where user_id = 1 order by buy_date limit 3;
+----+-------------+---------+------------+------+----------------------------------+----------------------+---------+-------+------+----------+--------------------------+
| id | select_type | table   | partitions | type | possible_keys                    | key                  | key_len | ref   | rows | filtered | Extra                    |
+----+-------------+---------+------------+------+----------------------------------+----------------------+---------+-------+------+----------+--------------------------+
|  1 | SIMPLE      | t_order | NULL       | ref  | idx_user_id,idx_user_id_buy_date | idx_user_id_buy_date | 4       | const |    4 |   100.00 | Using where; Using index |
+----+-------------+---------+------------+------+----------------------------------+----------------------+---------+-------+------+----------+--------------------------+
1 row in set, 1 warning (0.01 sec)
```

- 如果删除idx_user_id_buy_date这个联合索引，则显示Using filesort：

```linux
mysql> alter table t_order drop index idx_user_id_buy_date;
Query OK, 0 rows affected (0.02 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> explain select user_id, order_id  from t_order where user_id = 1 order by buy_date limit 3;
+----+-------------+---------+------------+------+---------------+------+---------+------+------+----------+-----------------------------+
| id | select_type | table   | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                       |
+----+-------------+---------+------------+------+---------------+------+---------+------+------+----------+-----------------------------+
|  1 | SIMPLE      | t_order | NULL       | ALL  | idx_user_id   | NULL | NULL    | NULL |    4 |   100.00 | Using where; Using filesort |
+----+-------------+---------+------------+------+---------------+------+---------+------+------+----------+-----------------------------+
1 row in set, 1 warning (0.00 sec)
```
