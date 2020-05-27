

参考：https://www.cnblogs.com/raphael5200/p/5285583.html

### Zookeepr基本概念

#### 角色简介

Zookeeper角色分为三类：

- 领导者：负责进行投票的发起和决议,更新系统状态。

- 学习者：①跟随者：Follower用于接收客户请求并向客户端返回结果，在选中过程中参与投票。②观察者：Observer可以接收客户端连接，将写请求转发给leader节点。但不参加投票过程,只同步leader状态。Observer目的在于扩展系统，提高读取速度。

- 客户端：请求发起方。

![配置管理](/images/zkcluster1-1.png)

![配置管理](/images/zkclusterrole.png)


**Observer**　

- Zookeeper需保证高可用和强一致性,为了支持更多的客户端，需要增加更多Server；

- Server增多，投票阶段延迟增大，影响性能；权衡伸缩性和高吞吐率，引入Observer

- Observer不参与投票,Observers接受客户端的连接，并将写请求转发给leader节点；

- 加入更多Observer节点，提高伸缩性，同时不影响吞吐率


#### 设计目的

（1）一致性：client不论连接到哪个Server，展示给它都是同一个视图，这是zookeeper最重要的性能。

（2）可靠性：具有简单、健壮、良好的性能，如果消息m被到一台服务器接受，那么它将被所有的服务器接受。

（3）实时性：Zookeeper保证客户端将在一个时间间隔范围内获得服务器的更新信息，或者服务器失效的信息。但由于网络延时等原因，Zookeeper不能保证两个客户端能同时得到刚更新的数据，如果需要最新数据，应该在读数据之前调用sync()接口。

（4）等待无关（wait-free）：慢的或者失效的client不得干预快速的client的请求，使得每个client都能有效的等待。

（5）原子性：更新只能成功或者失败，没有中间状态。

（6）顺序性：包括全局有序和偏序两种：全局有序是指如果在一台服务器上消息a在消息b前发布，则在所有Server上消息a都将在消息b前被发布；偏序是指如果一个消息b在消息a后被同一个发送者发布，a必将排在b前面。


#### Zookeeper 的数据模型　

- 层次化的目录结构，命名符合常规文件系统规范

- 每个节点在zookeeper中叫做znode,并且其有一个唯一的路径标识

- 节点Znode可以包含数据和子节点，但是EPHEMERAL类型的节点不能有子节点

- Znode中的数据可以有多个版本，比如某一个路径下存有多个数据版本，那么查询这个路径下的数据就需要带上版本

- 客户端应用可以在节点上设置监视器

- 节点不支持部分读写，而是一次性完整读写


### Zookeeper工作原理

Zookeeper的核心是原子广播，这个机制保证了各个Server之间的同步。实现这个机制的协议叫做Zab协议。Zab协议有两种模式，它们分别是恢复模式（选主）和广播模式（同步）。当服务启动或者在领导者崩溃后，Zab就进入了恢复模式，当领导者被选举出来，且大多数Server完成了和 leader的状态同步以后，恢复模式就结束了。状态同步保证了leader和Server具有相同的系统状态。

为了保证事务的顺序一致性，zookeeper采用了递增的事务id号（zxid）来标识事务。所有的提议（proposal）都在被提出的时候加上 了zxid。实现中zxid是一个64位的数字，它高32位是epoch用来标识leader关系是否改变，每次一个leader被选出来，它都会有一个 新的epoch，标识当前属于那个leader的统治时期。低32位用于递增计数。

**每个Server在工作过程中有三种状态：**

（1）LOOKING：当前Server不知道leader是谁，正在搜寻。

（2）LEADING：当前Server即为选举出来的leader。


（3）FOLLOWING：leader已经选举出来，当前Server与之同步。


#### 选主流程

当leader崩溃或者leader失去大多数的follower，这时候zk进入恢复模式，恢复模式需要重新选举出一个新的leader，让所有的 Server都恢复到一个正确的状态。

Zk的选举算法有两种：一种是基于basic paxos实现的，另外一种是基于fast paxos算法实现的。系统默认的选举算法为fast paxos。

- Basic paxos：当前Server发起选举的线程,向所有Server发起询问,选举线程收到所有回复,计算zxid最大Server,并推荐此为leader，若此提议获得n/2+1票通过,此为leader，否则重复上述流程，直到leader选出。

- Fast paxos:某Server首先向所有Server提议自己要成为leader，当其它Server收到提议以后，解决epoch和 zxid的冲突，并接受对方的提议，然后向对方发送接受提议完成的消息，重复这个流程，最后一定能选举出Leader。(即提议方解决其他所有epoch和 zxid的冲突,即为leader)。


#### 同步流程

（1）Leader等待server连接；

（2）Follower连接leader，将最大的zxid发送给leader；

（3）Leader根据follower的zxid确定同步点，完成同步后通知follower 已经成为uptodate状态；

（4）Follower收到uptodate消息后，又可以重新接受client的请求进行服务了。

![配置管理](/images/zktongbu.png)


#### 主要功能（server）

（1）Leader主要功能：

- ①恢复数据 

- ②维持与Learner的心跳，接收Learner请求并判断Learner的请求消息类型；

- ③Learner的消息类型主要有PING消息、REQUEST消息、ACK消息、REVALIDATE消息，根据不同的消息类型，进行不同的处理。

  - PING消息是指Learner的心跳信息；
  - REQUEST消息是Follower发送的提议信息，包括写请求及同步请求；
  - ACK消息是 Follower的对提议的回复，超过半数的Follower通过，则commit该提议；
  - REVALIDATE消息是用来延长SESSION有效时间。

（2）Follower主要功能：

- ①向Leader发送请求（PING消息、REQUEST消息、ACK消息、REVALIDATE消息）；

- ②接收Leader消息并进行处理；

- ③接收Client的请求，如果为写请求，发送给Leader进行投票；

- ④返回Client结果。


#### 数据一致性与paxos 算法

据说Paxos算法的难理解与算法的知名度一样令人敬仰，所以我们先看如何保持数据的一致性，这里有个原则就是：
在一个分布式数据库系统中，如果各节点的初始状态一致，每个节点都执行相同的操作序列，那么他们最后能得到一个一致的状态。

• Paxos算法解决的什么问题呢，解决的就是保证每个节点执行相同的操作序列。好吧，这还不简单，master维护一个全局写队列，所有写操作都必须 放入这个队列编号，那么无论我们写多少个节点，只要写操作是按编号来的，就能保证一致性。没错，就是这样，可是如果master挂了呢。

• Paxos算法通过投票来对写操作进行全局编号，同一时刻，只有一个写操作被批准，同时并发的写操作要去争取选票，只有获得过半数选票的写操作才会被 批准（所以永远只会有一个写操作得到批准），其他的写操作竞争失败只好再发起一轮投票，就这样，在日复一日年复一年的投票中，所有写操作都被严格编号排 序。编号严格递增，当一个节点接受了一个
编号为100的写操作，之后又接受到编号为99的写操作（因为网络延迟等很多不可预见原因），它马上能意识到自己 数据不一致了，自动停止对外服务并重启同步过程。任何一个节点挂掉都不会影响整个集群的数据一致性（总2n+1台，除非挂掉大于n台）。


https://www.cnblogs.com/mengchunchen/p/9316776.html




