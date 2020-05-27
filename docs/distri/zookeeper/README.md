
https://www.cnblogs.com/mengchunchen/p/9316776.html

zookeeper

ZooKeeper 是一个开源的分布式协调服务，ZooKeeper 框架最初是在“Yahoo!"上构建的，用于以简单而稳健的方式访问他们的应用程序。

ZooKeeper 的设计目标是将那些复杂且容易出错的分布式一致性服务封装起来，构成一个高效可靠的原语集，并以一系列简单易用的接口提供给用户使用。

> 原语： 操作系统或计算机网络用语范畴。它是由若干条指令组成的，用于完成一定功能的一个过程。具有不可分割性，即原语的执行必须是连续的，在执行过程中不允许被中断。



### Zookeeper提供什么

Zookeepr提供文件系统及通知机制。

**文件系统：**

Zookeeper维护一个类似文件系统的数据结构：

![配置管理](/images/zkfile.png)

每个子目录项如 NameService 都被称作为 znode，和文件系统一样，自由增加及删除，唯一不同其可存储数据。

Znode有两种类型，短暂的（ephemeral）和持久的（persistent）
- Znode的类型在创建时确定并且之后不能再修改
- 短暂znode的客户端会话结束时，zookeeper会将该短暂znode删除，短暂znode不可以有子节点
- 持久znode不依赖于客户端会话，只有当客户端明确要删除该持久znode时才会被删除

Znode分为四种类型

  - (1) PERSISTENT-持久化目录节点。（客户端与zookeeper断开连接后，该节点依旧存在）。

  - (2) PERSISTENT_SEQUENTIAL-持久化顺序编号目录节点。（客户端与zookeeper断开连接后，该节点依旧存在，只是Zookeeper给该节点名称进行顺序编号）

  - (3) EPHEMERAL-临时目录节点（客户端与zookeeper断开连接后，该节点被删除）

  - (4) EPHEMERAL_SEQUENTIAL-临时顺序编号目录节点。（客户端与zookeeper断开连接后，该节点被删除，只是Zookeeper给该节点名称进行顺序编号）


**通知机制：**

客户端注册监听它关心的目录节点，当目录节点发生变化（数据改变、被删除、子目录节点增加删除）时，zookeeper会通知客户端。



ZooKeeper 一个最常用的使用场景就是用于担任服务生产者和服务消费者的注册中心。

服务生产者将自己提供的服务注册到 ZooKeeper 中心，服务的消费者在进行服务调用的时候先到 ZooKeeper 中查找服务，获取到服务生产者的详细信息之后，再去调用服务生产者的内容与数据。


结合个人使用讲一下 ZooKeeper

在我自己做过的项目中，主要使用到了 ZooKeeper 作为 Dubbo 的注册中心(Dubbo 官方推荐使用 ZooKeeper 注册中心)。

另外在搭建 Solr 集群的时候，我使用  ZooKeeper 作为 Solr 集群的管理工具。

这时，ZooKeeper 主要提供下面几个功能：

- 集群管理：容错、负载均衡。

- 配置文件的集中管理。

- 集群的入口。



为什么最好使用奇数台服务器构成 ZooKeeper 集群？

我们知道在 ZooKeeper 中 Leader 选举算法采用了 **Zab 协议**。Zab 核心思想是当多数 Server 写成功，则任务数据写成功：

如果有 3 个 Server，则最多允许 1 个 Server 挂掉。

如果有 4 个 Server，则同样最多允许 1 个 Server 挂掉。

既然 3 个或者 4 个 Server，同样最多允许 1 个 Server 挂掉，那么它们的可靠性是一样的。

所以选择奇数个 ZooKeeper Server 即可，这里选择 3 个 Server。



重要概念总结

关于 ZooKeeper  的一些重要概念：

ZooKeeper 本身就是一个分布式程序（只要半数以上节点存活，ZooKeeper 就能正常服务）。

为了保证高可用，最好是以集群形态来部署 ZooKeeper，这样只要集群中大部分机器是可用的（能够容忍一定的机器故障），那么 ZooKeeper 本身仍然是可用的。

ZooKeeper 将数据保存在内存中，这也就保证了 高吞吐量和低延迟（但是内存限制了能够存储的容量不太大，此限制也是保持 Znode 中存储的数据量较小的进一步原因）。

ZooKeeper 是高性能的。在“读”多于“写”的应用程序中尤其地高性能，因为“写”会导致所有的服务器间同步状态。（“读”多于“写”是协调服务的典型场景。）

ZooKeeper 有临时节点的概念。当创建临时节点的客户端会话一直保持活动，瞬时节点就一直存在。

而当会话终结时，瞬时节点被删除。持久节点是指一旦这个 ZNode 被创建了，除非主动进行 ZNode 的移除操作，否则这个 ZNode 将一直保存在 Zookeeper 上。

ZooKeeper 底层其实只提供了两个功能：①管理（存储、读取）用户程序提交的数据；②为用户程序提交数据节点监听服务。



下面关于会话（Session）、 Znode、版本、Watcher、ACL 概念的总结都在《从 Paxos 到 ZooKeeper 》第四章第一节以及第七章第八节有提到，感兴趣的可以看看！


会话（Session）

Session 指的是 ZooKeeper  服务器与客户端会话。在 ZooKeeper 中，一个客户端连接是指客户端和服务器之间的一个 TCP 长连接。

客户端启动的时候，首先会与服务器建立一个 TCP 连接，从第一次连接建立开始，客户端会话的生命周期也开始了。

通过这个连接，客户端能够通过心跳检测与服务器保持有效的会话，也能够向 Zookeeper 服务器发送请求并接受响应，同时还能够通过该连接接收来自服务器的 Watch 事件通知。

Session 的 sessionTimeout 值用来设置一个客户端会话的超时时间。

当由于服务器压力太大、网络故障或是客户端主动断开连接等各种原因导致客户端连接断开时，只要在 sessionTimeout 规定的时间内能够重新连接上集群中任意一台服务器，那么之前创建的会话仍然有效。

在为客户端创建会话之前，服务端首先会为每个客户端都分配一个 sessionID。

由于 sessionID 是 Zookeeper 会话的一个重要标识，许多与会话相关的运行机制都是基于这个 sessionID 的。

因此，无论是哪台服务器为客户端分配的 sessionID，都务必保证全局唯一。

Znode

在谈到分布式的时候，我们通常说的“节点"是指组成集群的每一台机器。

然而，在 ZooKeeper 中，“节点"分为两类：

第一类同样是指构成集群的机器，我们称之为机器节点。

第二类则是指数据模型中的数据单元，我们称之为数据节点一ZNode。

ZooKeeper 将所有数据存储在内存中，数据模型是一棵树（Znode Tree)，由斜杠（/）的进行分割的路径，就是一个 Znode，例如/foo/path1。每个上都会保存自己的数据内容，同时还会保存一系列属性信息。

在 Zookeeper 中，Node 可以分为持久节点和临时节点两类。所谓持久节点是指一旦这个 ZNode 被创建了，除非主动进行 ZNode 的移除操作，否则这个 ZNode 将一直保存在 ZooKeeper 上。

而临时节点就不一样了，它的生命周期和客户端会话绑定，一旦客户端会话失效，那么这个客户端创建的所有临时节点都会被移除。

另外，ZooKeeper 还允许用户为每个节点添加一个特殊的属性：SEQUENTIAL。

一旦节点被标记上这个属性，那么在这个节点被创建的时候，ZooKeeper 会自动在其节点名后面追加上一个整型数字，这个整型数字是一个由父节点维护的自增数字。

版本

在前面我们已经提到，Zookeeper 的每个 ZNode 上都会存储数据，对应于每个 ZNode，Zookeeper 都会为其维护一个叫作 Stat 的数据结构。

Stat 中记录了这个 ZNode 的三个数据版本，分别是：

version（当前 ZNode 的版本）

cversion（当前 ZNode 子节点的版本）

aversion（当前 ZNode 的 ACL 版本）

Watcher

Watcher（事件监听器），是 ZooKeeper 中的一个很重要的特性。

ZooKeeper 允许用户在指定节点上注册一些 Watcher，并且在一些特定事件触发的时候，ZooKeeper 服务端会将事件通知到感兴趣的客户端上去，该机制是 ZooKeeper 实现分布式协调服务的重要特性。

ACL

ZooKeeper 采用 ACL（AccessControlLists）策略来进行权限控制，类似于  UNIX 文件系统的权限控制。

ZooKeeper 定义了 5 种权限，如下图：

![ZooKeeper权限](/images/zkauth.png)
 

其中尤其需要注意的是，CREATE 和 DELETE 这两种权限都是针对子节点的权限控制。



ZooKeeper 特点

ZooKeeper 有哪些特点呢？具体如下：

- 顺序一致性：从同一客户端发起的事务请求，最终将会严格地按照顺序被应用到 ZooKeeper 中去。

- 原子性：所有事务请求的处理结果在整个集群中所有机器上的应用情况是一致的，也就是说，要么整个集群中所有的机器都成功应用了某一个事务，要么都没有应用。

- 单一系统映像：无论客户端连到哪一个 ZooKeeper 服务器上，其看到的服务端数据模型都是一致的。

- 可靠性：一旦一次更改请求被应用，更改的结果就会被持久化，直到被下一次更改覆盖。



### ZooKeeper 设计目标

#### 简单的数据模型

ZooKeeper 允许分布式进程通过共享的层次结构命名空间进行相互协调，这与标准文件系统类似。

名称空间由 ZooKeeper 中的数据寄存器组成，称为 Znode，这些类似于文件和目录。

与为存储设计的典型文件系统不同，ZooKeeper 数据保存在内存中，这意味着 ZooKeeper 可以实现高吞吐量和低延迟。

![ZooKeeper权限](/images/zkdata.png)


#### 可构建集群

为了保证高可用，最好是以集群形态来部署 ZooKeeper，这样只要集群中大部分机器是可用的（能够容忍一定的机器故障），那么 ZooKeeper 本身仍然是可用的。 

客户端在使用 ZooKeeper 时，需要知道集群机器列表，通过与集群中的某一台机器建立 TCP 连接来使用服务。

客户端使用这个 TCP 链接来发送请求、获取结果、获取监听事件以及发送心跳包。如果这个连接异常断开了，客户端可以连接到另外的机器上。

ZooKeeper 官方提供的架构图：

![ZooKeeper权限](/images/zkcluster.png)

上图中每一个 Server 代表一个安装 ZooKeeper 服务的服务器。组成 ZooKeeper 服务的服务器都会在内存中维护当前的服务器状态，并且每台服务器之间都互相保持着通信。

集群间通过 Zab 协议（Zookeeper Atomic Broadcast）来保持数据的一致性。


#### 顺序访问

对于来自客户端的每个更新请求，ZooKeeper 都会分配一个全局唯一的递增编号。

这个编号反应了所有事务操作的先后顺序，应用程序可以使用 ZooKeeper 这个特性来实现更高层次的同步原语。这个编号也叫做时间戳—zxid（ZooKeeper Transaction Id）。

#### 高性能

ZooKeeper 是高性能的。在“读”多于“写”的应用程序中尤其地高性能，因为“写”会导致所有的服务器间同步状态。（“读”多于“写”是协调服务的典型场景。）



### ZooKeeper 集群角色介绍

最典型集群模式：Master/Slave 模式（主备模式）。在这种模式中，通常 Master 服务器作为主服务器提供写服务，其他的 Slave 服务器从服务器通过异步复制的方式获取 Master 服务器最新的数据提供读服务。

但是，在 ZooKeeper 中没有选择传统的 Master/Slave 概念，而是引入了Leader、Follower 和 Observer 三种角色。

如下图所示：

![ZooKeeper权限](/images/zkcluster1.png)

ZooKeeper 集群中的所有机器通过一个 Leader 选举过程来选定一台称为 “Leader” 的机器。

Leader 既可以为客户端提供写服务又能提供读服务。除了 Leader 外，Follower 和  Observer 都只能提供读服务。

Follower 和 Observer 唯一的区别在于 Observer 机器不参与 Leader 的选举过程，也不参与写操作的“过半写成功”策略，因此 Observer 机器可以在不影响写性能的情况下提升集群的读性能。

![ZooKeeper权限](/images/zkclusterrole.png)




### ZooKeeper & ZAB 协议 & Paxos 算法

ZAB 协议 & Paxos 算法

Paxos 算法可以说是  ZooKeeper 的灵魂了。但是，ZooKeeper 并没有完全采用 Paxos 算法 ，而是使用 ZAB 协议作为其保证数据一致性的核心算法。

另外，在 ZooKeeper 的官方文档中也指出，ZAB 协议并不像 Paxos 算法那样，是一种通用的分布式一致性算法，它是一种特别为 ZooKeeper 设计的崩溃可恢复的原子消息广播算法。

ZAB 协议介绍

ZAB（ZooKeeper Atomic Broadcast 原子广播）协议是为分布式协调服务 ZooKeeper 专门设计的一种支持崩溃恢复的原子广播协议。

在 ZooKeeper 中，主要依赖 ZAB 协议来实现分布式数据一致性，基于该协议，ZooKeeper 实现了一种主备模式的系统架构来保持集群中各个副本之间的数据一致性。

ZAB 协议两种基本的模式

ZAB 协议包括两种基本的模式，分别是崩溃恢复和消息广播。
当整个服务框架在启动过程中，或是当 Leader 服务器出现网络中断、崩溃退出与重启等异常情况时，ZAB 协议就会进入恢复模式并选举产生新的 Leader 服务器。
当选举产生了新的 Leader 服务器，同时集群中已经有过半的机器与该 Leader 服务器完成了状态同步之后，ZAB 协议就会退出恢复模式。

其中，所谓的状态同步是指数据同步，用来保证集群中存在过半的机器能够和 Leader 服务器的数据状态保持一致。

当集群中已经有过半的 Follower 服务器完成了和 Leader 服务器的状态同步，那么整个服务框架就可以进人消息广播模式了。 

当一台同样遵守 ZAB 协议的服务器启动后加入到集群中时，如果此时集群中已经存在一个 Leader 服务器在负责进行消息广播。

那么新加入的服务器就会自觉地进人数据恢复模式：找到 Leader 所在的服务器，并与其进行数据同步，然后一起参与到消息广播流程中去。

正如上文介绍中所说的，ZooKeeper 设计成只允许唯一的一个 Leader 服务器来进行事务请求的处理。

Leader 服务器在接收到客户端的事务请求后，会生成对应的事务提案并发起一轮广播协议。

而如果集群中的其他机器接收到客户端的事务请求，那么这些非 Leader 服务器会首先将这个事务请求转发给 Leader 服务器。

关于 ZAB 协议 & Paxos 算法需要讲和理解的东西太多了，推荐阅读下面两篇文章：

图解 Paxos 一致性协议：

http://blog.xiaohansong.com/2016/09/30/Paxos/

Zookeeper ZAB 协议分析：

http://blog.xiaohansong.com/2016/08/25/zab/

关于如何使用 ZooKeeper 实现分布式锁，可以查看下面这篇文章：

Zookeeper ZAB 协议分析：

https://blog.csdn.net/qiangcuo6087/article/details/79067136
















