
<h2>高可靠之持久化与高可用之镜像队列</h2>

参考：[高可靠之持久化与高可用之镜像队列](https://blog.csdn.net/u010013573/article/details/90816020)  、 [RabbitMQ镜像队列实现原理](https://www.jianshu.com/p/f917067bcee3)

--------------------------------------------

### 一、概述

#### 1. 分布式系统的需要

RabbitMQ 是对内存队列，如 Java 的阻塞队列 BlockingQueue，的一种升级，即作为一个进程队列实现不同进程之间的消息通信交互，而内存队列，如 BlockingQueue 则通常用于实现一个 Java 进程的不同线程之间的消息通信交互。这也是顺应从单体应用到分布式系统的演变所必须的消息队列的演进，解决了分布式系统不同系统之间的消息传递问题。

#### 2. 基于内存存储

- 由于 RabbitMQ 主要用于实现不同进程或者说不同系统之间的消息传递，与内存队列在进程重启自动销毁类似，RabbitMQ 的相关组件，如交换器，队列，消息等默认情况下也是存放在内存中的，当 RabbitMQ 服务器重启时，这些组件相关的元数据会丢失，重启时需要重新创建这些核心组件。

- 这样设计的合理之处在于 RabbitMQ 并不是一个数据存储系统，而是相对于内存队列，提供了通过网络的方式为不同系统进行消息传递，这也是 AMQP 协议的核心所在。

#### 3. 数据持久化

- 不过在实际应用中，由于组成分布式系统的各个子系统的功能通常是固定的，如电商网站中的账号系统，订单系统，物流系统等，当选择 RabbitMQ 作为这些子系统的消息队列时，通常需要保证 RabbitMQ 在意外宕机或者重启后，相关的交换器，队列，未消费的消息还存在，而不需要重新创建交换器或者队列，并且未消费的消息不会丢失，这样才能减少对生产者和消费者，如以上的电商系统的相关业务子系统，的影响。

- 所以需要对交换器，队列和队列的消息进行持久化处理，即持久化到磁盘中，当 RabbitMQ 宕机或者重启时，可以从磁盘将这些组件的数据重新加载到内存中。

### 二、持久化：高可靠

#### 1. 元数据持久化

- 交换器和队列的持久化主要是在创建交换器或者队列时，通过设置durable 参数为 true 来告诉 RabbitMQ 对这个所创建的交换器或者队列进行持久化处理。

- 通常需要对交换器和队列同时设置持久化，这样能保证不只是交换器和队列在 RabbitMQ 重启时还存在，交换器和队列之间的绑定关系 Binding 也还存在，这样对生产者和消费者影响最小，即生产者和消费者可以继续正常生产数据或者消费数据，就像 RabbitMQ 没有重启过一样。

- 交换器和队列的持久化主要是针对交换器和队列的相关元数据的持久化，将这些元数据持久化到磁盘中。

  - 对于交换器而言，需要持久化的元数据主要包括队列的名字，队列类型，如 faout，direct，topic或者headers，以及其他相关属性，如持久化属性durable。交换器持久化之后，当RabbitMQ重启后，生产者可以继续使用这个交换器来传递数据，而无需在手动创建这个交换器，这样能尽可能地降低对生产者的影响。
  - 对于队列而言，需要持久化的元数据主要为队列的名字，以及属性，如是否持久化 durable，是否自动删除。不过这里需要注意的是，如果一个队列是排他队列，即只对当前的连接 Connection 有效，只能被当前连接Connection 的多个 Channel 访问，则即使设置了该队列为持久队列，当这个连接 Connection 断开时，该队列也会自动删除掉，而不会再持久化到磁盘中。
  - 除了需要持久化交换器和队列自身的元数据外，交换器和队列之间的绑定映射关系也会持久化。
  - 在磁盘存储方面，交换器和队列的持久化信息通常存放在 rabbitmq 服务器的 /var/lib/rabbitmq/mnesia/ 目录下面。

#### 2. 消息持久化

- 以上的分析的交换器和队列的持久化只是针对交换器和队列自身元数据的持久化，而不会对消息进行持久化，即消息还是存放在 RabbitMQ 服务器的内存中的，如果 RabbitMQ 服务器宕机或者重启，队列中的消息会丢失。

- 所以如果要保证投递到队列中的消息在 RabbitMQ 服务器宕机重启时不会丢失，需要进行消息持久化。消息持久化主要是在生产者控制的。即生产者在创建消息时，可以设置消息的属性 properties 的 deliveryMode 为 2 来指定这个消息是需要持久化的。

- 当将该消息投递到 RabbitMQ 服务器的队列之后，需要首先写到磁盘中，然后再在内存队列保留这条消息，最后如果生产者需要确认 ACK，则再回调通知生产者这条消息投递成功。

- 由于消息写入磁盘是随机写操作，性能较低，会一定程度影响 RabbitMQ 服务器整体的吞吐量，所以一般对重要，对消息丢失容忍度低的场景的消息，才将该消息设置为持久化。还有就是当对磁盘文件写入时，操作系统不是对每次写入都直接写到磁盘文件的，而是会写到操作系统的页缓存中，等之后再刷到磁盘，所以如果在这期间，机器宕机了，则即使设置了消息持久化，也可能造成消息丢失。

### 三、镜像队列：高可用

- 以上的消息持久化机制的可靠性的前提是：该机器不宕机，磁盘不损坏，即还是存在单点故障问题，并没有实现消息在其他机器的冗余存储来避免单点故障。

- RabbitMQ 的消息默认是只在其所被投递到的某个机器的 RabbitMQ 服务器的某个队列中存放一份，在其他队列或者其他机器的队列并没有一份拷贝，所以缺乏高可用特性。

- 所以为了实现高可用，RabbitMQ 提供了镜像队列机制。所谓镜像队列其实就是在另外一个 RabbitMQ 服务器 Broker 存放一个该队列的一个拷贝队列，实现队列内消息的冗余存储。

**主备模式**

镜像队列机制是基于主备模式的：

- 针对这个队列的所有操作都是只能在 Master 节点进行操作的，包括生产者发布消息到队列，分发消息给消费者，跟踪消费者的消费确认ACK等，然后将这些操作对应的消息由 Master 节点广播同步给其他节点。

- 针对消息消费，与 MySQL 和 Redis 的主从模式中 master 负责写请求，slave 负责读请求实现读写分离不同的是，在 RabbitMQ 的镜像队列模式中，消费者是从 Master 节点消费数据的，即不管消费者连接的是哪个节点进行消费，如连接到从节点消费，从节点会将消费请求转发到 master 进行消费。当成功消费并确认 ACK 删除该消息时，由 Master 节点同步这个删除信息给其他 Slave 节点。

- 所以镜像队列解决的是消息高可用问题，而不是基于负载均衡实现的高吞吐量问题。高吞吐量主要是通过 RabbitMQ 集群来实现的，即在不同节点创建不同队列来提高消息处理能力和吞吐量。

- 消费者默认不会从 Slave 节点消费数据，只有当 Master 节点宕机，Slave 节点升级为 Master 节点时才会消费这个节点的数据。Master 节点宕机时，会从所有 slave 节点中选择最早加入这个镜像队列集合的 slave 作为新的master，即根据加入时间来判断的。

参考：[RabbitMQ官方文档：Highly Available (Mirrored) Queues](https://www.rabbitmq.com/ha.html)


#### 镜像队列使用

1. 策略设置

镜像队列设置可以基于策略设置，策略设置可以通过如下两种方法：

（1）RabbitMQ 管理后台

![MessageQueue](/images/rabbit-008.webp)

（2）rabbitmqctl 设置

policy 添加命令：

```
rabbitmqctl set_policy [-p <vhost>] [--priority <priority>] [--apply-to <apply-to>] <name> <pattern>  <definition>
```

指令参数详情

| 参数名称 | 描述 |
|---|---|
| -p | 可选参数，针对指定 vhost 下的exchange或 queue |
| --priority | 可选参数，policy 的优先级 |
| --apply-to | 可选参数，策略适用的对象类型，其值可为 "queues", "exchanges" 或 "all".默认是"all" |
| name | policy 的名称 |
| pattern |	匹配模式（正则表达式） |
| definition | 镜像定义，json 格式，包括三部分（ha-mode,ha-params,ha-sync-mode）具体配置见下表 |

definition参数详情

| 参数名称 |	描述 |
|---|---|
| ha-mode |	指名镜像队列模式，其值可为"all","exactly"或"nodes"，all：表示在集群所有节点上进行镜像；exactly：表示在指定个数的节点上镜像，节点个数由 ha-params 指定；nodes：表示在指定节点上进行镜像，节点名称通过ha-params 指定。|
| ha-params	| ha-mode模式需要用到的参数：exactly 模式下为数字表述镜像节点数，nodes 模式下为节点列表表示需要镜像的节点。|
| ha-sync-mode | 镜像队列中消息的同步方式，其值可为"automatic"或"manually". | 


例如：对队列名称为 hello 开头的所有队列镜像镜像，并且在集群的节点 rabbit@10.18.195.57上进行镜像，队列消息自动同步，policy 的设置命令：

```
rabbitmqctl set_policy --apply-to queues hello-ha "^hello" '{"ha-mode":"nodes","ha-params":["rabbit@10.18.195.57"],"ha-sync-mode":"automatic"}'
```

2. ha 策略确认

镜像队列策略是否生效可以通过如下两种方式验证：

（1）RabbitMQ 管理后台

![MessageQueue](/images/rabbit-009.webp)

可以通过策略管理验证策略是否配置正确

![MessageQueue](/images/rabbit-010.webp)

通过队列列表也可以查看队列应用的策略，如果是镜像策略，可以看到当前队列副本数

![MessageQueue](/images/rabbit-011.webp)

通过队列详情可以查看镜像队列当前主副本在哪个节点，从副本在哪几个节点

（2）rabbitmqctl 查看

查看策略详情指令：

```
rabbitmqctl list_policies
```

返回：

![MessageQueue](/images/rabbit-012.webp)

查看队列是否镜像指令：

```
rabbitmqctl list_queues name pid slave_pids
```

![MessageQueue](/images/rabbit-013.webp)


#### 镜像队列实现原理

1.整体介绍

通常队列由两部分组成：一部分是 amqqueue_process, 负责协议相关的消息处理，即接收生产者发布的消息，向消费者投递消息，处理消息 confirm，ack 等等；另外一部分是 backing_queue， 作为消息存储的具体形式和引擎，提供了相关接口供进程amqqueue_process调用，用来完成消息的存储及可能的持久化工作等。

镜像队列和普通队列组成有所不同，镜像队列存在两类进程：master队列进程为 amqqueue_process，slave 队列进程为 rabbit_mirror_queue_slave，每个进程会创建一个 gm（guaranteed multicast）进程，镜像队列中所有 gm 进程会组成一个进程组用于广播和接收消息。同时和普通队列一样，每个进程都包含一个用于处理消息逻辑的队列 backing_queue（默认为rabbit_variable_queue）。集群中每个有客户端连接的节点都会启动若干个channel进程，channel进程中记录着镜像队列中master和所有slave进程的Pid，以便直接与队列进程通信。整体结构如下：

![MessageQueue](/images/rabbit-014.webp)

gm 负责消息广播，至于广播消息处理，master 队列上回掉处理是通过coordinator，消息相关协议操作是通过amqqueue_process处理，而 slave 队列都是由rabbit_mirror_queue_slave进行处理。

> 注意：消息的发布和消费都是通过 master 队列完成，master 队列对消息进行处理同时将消息的处理动作通过 gm 广播给所有 slave 队列，slave 的 gm 收到消息后，通过回调交由 rabbit_mirror_queue_slave 进行实际处理。

2.gm（Guaranteed Muticast）

镜像队列 gm 组通过将所有 gm 进程形成一个循环链表，每个 gm 都会监控位于自己左右两边的 gm，当有 gm 新增时，相邻的 gm 保证当前广播的消息会通知到新的 gm 上；当有 gm 失效时，相邻的 gm 会接管保证本次广播消息会通知到所有 gm。

gm 组信息会记录在本地数据库（mnesia）中，不同的镜像队列行程的 gm 组也是不同的。

消息从 master 队列对应的 gm 发出后，顺着链表依次传送到所有 gm 进程，由于所有 gm 进程组成一个循环链表，master 队列的 gm 线程最终会收到自己发送的消息，这个时候 master 队列就知道消息已经复制到所有 slave 队列了。

![MessageQueue](/images/rabbit-015.webp)

3.重要的数据结构

queue 队列相关信息

```
-record(q, 
        { q,                    %% 队列信息数据结构amqqueue
          exclusive_consumer,   %% 当前队列的独有消费者
          has_had_consumers,    %% 当前队列中是否有消费者的标识
          backing_queue,        %% backing_queue对应的模块名字
          backing_queue_state,  %% backing_queue对应的状态结构
          consumers,            %% 消费者存储的优先级队列
          expires,              %% 当前队列未使用就删除自己的时间
          sync_timer_ref,       %% 同步confirm的定时器，当前队列大部分接收一次消息就要确保当前定时器的存在(200ms的定时器)
          rate_timer_ref,       %% 队列中消息进入和出去的速率定时器
          expiry_timer_ref,     %% 队列中未使用就删除自己的定时器
          stats_timer,          %% 向rabbit_event发布信息的数据结构状态字段
          msg_id_to_channel,    %% 当前队列进程中等待confirm的消息gb_trees结构，里面的结构是Key:MsgId Value:{SenderPid, MsgSeqNo}
          ttl,                  %% 队列中设置的消息存在的时间
          ttl_timer_ref,        %% 队列中消息存在的定时器
          ttl_timer_expiry,     %% 当前队列头部消息的过期时间点
          senders,              %% 向当前队列发送消息的rabbit_channel进程列表
          dlx,                  %% 死亡消息要发送的exchange交换机(通过队列声明的参数或者policy接口来设置)
          dlx_routing_key,      %% 死亡消息要发送的路由规则(通过队列声明的参数或者policy接口来设置)
          max_length,           %% 当前队列中消息的最大上限(通过队列声明的参数或者policy接口来设置)
          max_bytes,            %% 队列中消息内容占的最大空间
          args_policy_version,  %% 当前队列中参数设置对应的版本号，每设置一次都会将版本号加一
          status                %% 当前队列的状态
        }).
```

state 记录 gm 进程状态

```
-record(state,
        { self,                 %% gm本身的ID
          left,                 %% 该节点左边的节点
          right,                %% 该节点右边的节点
          group_name,           %% group名称与队列名一致
          module,               %% 回调模块rabbit_mirror_queue_slave或者rabbit_mirror_queue_coordinator
          view,                 %% group成员列表视图信息，记录了成员的ID及每个成员的左右邻居节点(组装成一个循环列表)
          pub_count,            %% 当前已发布的消息计数
          members_state,        %% group成员状态列表 记录了广播状态:[#member{}]
          callback_args,        %% 回调函数的参数信息，rabbit_mirror_queue_slave/rabbit_mirror_queue_coordinator进程PID
          confirms,             %% confirm列表
          broadcast_buffer,     %% 缓存待广播的消息
          broadcast_buffer_sz,  %% 当前缓存带广播中消息实体总的大小
          broadcast_timer,      %% 广播消息定时器
          txn_executor          %% 操作Mnesia数据库的操作函数
        }).

```

gm_group 整个镜像队列群组的信息，该信息会存储到Mnesia数据库

```
-record(gm_group, 
        { name,    %% group的名称,与queue的名称一致
          version, %% group的版本号, 新增节点/节点失效时会递增
          members  %% group的成员列表, 按照节点组成的链表顺序进行排序
        }).
```

view_member 镜像队列群组视图成员数据结构

```
-record(view_member, 
        { id,       %% 单个镜像队列(结构是{版本号，该镜像队列的Pid})
          aliases,  %% 记录id对应的左侧死亡的GM进程列表
          left,     %% 当前镜像队列左边的镜像队列(结构是{版本号，该镜像队列的Pid})
          right     %% 当前镜像队列右边的镜像队列(结构是{版本号，该镜像队列的Pid})
        }).
```


#### 镜像队列组群维护

**1.节点新加入组群**

目前已有节点 A，B，C，新加入节点 B，如图：

![MessageQueue](/images/rabbit-016.webp)

节点加入集群流程如下：

（1）新增节点先从 gm_group 中获取对应 group 成员信息；

（2）随机选择一个节点并向这个节点发送加入请求；

（3）集群节点收到新增节点请求后，更新 gm_group 对应信息，同时更新左右节点更新邻居信息（调整对左右节点的监控）；

（4）集群节点回复通知新增节点成功加入 group；

（5）新增节点收到回复后更新 rabbit_queue 中的相关信息，同时根据策略同步消息。

![MessageQueue](/images/rabbit-017.webp)


核心流程详解：

（1）新增节点 D 的 GM 进程请求加入组群

```
%% 同步处理将自己加入到镜像队列的群组中的消息
handle_cast(join, State = #state { self          = Self,
                                   group_name    = GroupName,
                                   members_state = undefined,
                                   module        = Module,
                                   callback_args = Args,
                                   txn_executor  = TxnFun })->
    %% join_group函数主要执行逻辑
    %% 1.判断时候有存活节点，如果没有存活，则重新创建gm_group数据库数据
    %% 2.如果有存活GM进程，随机选择一个GM进程
    %% 3.将当前新增节点GM进程加入到选择的GM进程右侧
    %% 4.将所有存活的镜像队列组装成镜像队列循环队列视图A->D->B->C->A
    View = join_group(Self, GroupName, TxnFun),
    MembersState =
        %% 获取镜像队列视图的所有key列表
        case alive_view_members(View) of
            %% 如果是第一个GM进程的启动则初始化成员状态数据结构
            [Self] -> blank_member_state();
            %% 如果不是第一个GM进程加入到Group中，则成员状态先不做初始化，让自己左侧的GM进程发送过来的信息进行初始化
            _      -> undefined
        end,
    %% 检查当前镜像队列的邻居信息(根据消息镜像队列的群组循环视图更新自己最新的左右两边的镜像队列)
    State1 = check_neighbours(State #state { view = View, members_state = MembersState }),
    %% 通知启动该GM进程的进程已经成功加入镜像队列群组(rabbit_mirror_queue_coordinator或rabbit_mirror_queue_slave模块回调)
    handle_callback_result(
      {Module:joined(Args, get_pids(all_known_members(View))), State1});
```

（2）GM 进程 A 处理新增 GM 进程到自己右侧

```
%% 处理将新的镜像队列加入到本镜像队列的右侧的消息
handle_call({add_on_right, NewMember}, _From,
            State = #state { self          = Self,
                             group_name    = GroupName,
                             members_state = MembersState,
                             txn_executor  = TxnFun }) ->
    %% 记录将新的镜像队列成员加入到镜像队列组中，将新加入的镜像队列写入gm_group结构中的members字段中(有新成员加入群组的时候，则将版本号增加一)
    Group = record_new_member_in_group(NewMember, Self, 
                                       GroupName, TxnFun),
    %% 根据组成员信息生成新的镜像队列视图数据结构
    View1 = group_to_view(Group),
    %% 删除擦除的成员
    MembersState1 = remove_erased_members(MembersState, 
                                          View1),
    %% 向新加入的成员即右边成员发送加入成功的消息
    ok = send_right(NewMember, View1,
                    {catchup, Self,          
                     prepare_members_state(MembersState1)}),
    %% 根据新的镜像队列循环队列视图和老的视图修改视图，同时根据镜像队列循环视图更新自己左右邻居信息
    {Result, State1} = change_view(View1, State #state {
                                                        members_state = MembersState1 }),
    %% 向请求加入的镜像队列发送最新的当前镜像队列的群组信息
    handle_callback_result({Result, {ok, Group}, State1}).
```

(3) GM进程 D 处理 GM 进程 A 发送过来成员状态信息

```
%% 左侧的GM进程通知右侧的GM进程最新的成员状态(此情况是本GM进程是新加入Group的，等待左侧GM进程发送过来的消息进行初始化成员状态)
handle_msg({catchup, Left, MembersStateLeft},
           State = #state { self          = Self,
                            left          = {Left, _MRefL},
                            right         = {Right, _MRefR},
                            view          = View,
                            %% 新加入的GM进程在加入后是没有初始化成员状态，是等待左侧玩家发送消息来进行初始化
                            members_state = undefined }) ->
    %% 异步向自己右侧的镜像队列发送最新的所有成员信息，让Group中的所有成员更新成员信息
    ok = send_right(Right, View, {catchup, Self, MembersStateLeft}),
    %% 将成员信息转化成字典数据结构
    MembersStateLeft1 = build_members_state(MembersStateLeft),
    %% 新增加的GM进程更新最新的成员信息
    {ok, State #state { members_state = MembersStateLeft1 }};
```

**2.节点失效**

当 Slave 节点失效时，仅仅是相邻节点感知，然后重新调整邻居节点信息，更新 rabbit_queue, gm_group的记录。

​ 当 Master 节点失效时流程如下：

（1）由于所有 mirror_queue_slave进程会对 amqqueue_process 进程监控，如果 Master 节点失效，mirror_queue_slave感知后通过 GM 进行广播；

（2）存活最久的 Slave 节点会提升自己为 master 节点；

（3）该节点会创建出新的 coordinator，并通知 GM 进程修改回调处理器为 coordinator；

（4）原来的 mirror_queue_slave 作为 amqqueue_process 处理生产发布的消息，向消费者投递消息。

核心流程详解：

（1）GM 进程挂掉处理

```
%% 接收到自己左右两边的镜像队列GM进程挂掉的消息
handle_info({'DOWN', MRef, process, _Pid, Reason},
            State = #state { self          = Self,
                             left          = Left,
                             right         = Right,
                             group_name    = GroupName,
                             confirms      = Confirms,
                             txn_executor  = TxnFun }) ->
    %% 得到挂掉的GM进程
    Member = case {Left, Right} of
                 %% 左侧的镜像队列GM进程挂掉的情况
                 {{Member1, MRef}, _} -> Member1;
                 %% 右侧的镜像队列GM进程挂掉的情况
                 {_, {Member1, MRef}} -> Member1;
                 _                    -> undefined
             end,
    case {Member, Reason} of
        {undefined, _} ->
            noreply(State);
        {_, {shutdown, ring_shutdown}} ->
            noreply(State);
        _ -> timer:sleep(100),
            %% 先记录有镜像队列成员死亡的信息，然后将所有存活的镜像队列组装镜像队列群组循环队列视图
            %% 有成员死亡的时候会将版本号增加一，record_dead_member_in_group函数是更新gm_group数据库表中的数据，将死亡信息写入数据库表
            View1 = group_to_view(record_dead_member_in_group(
                                    Member, GroupName, 
                                    TxnFun)),
            handle_callback_result(
              case alive_view_members(View1) of
                  %% 当存活的镜像队列GM进程只剩自己的情况
                  [Self] -> maybe_erase_aliases(
                              State #state {
                                            members_state = blank_member_state(),
                                            confirms      = purge_confirms(Confirms) },
                                           View1);
                  %% 当存活的镜像队列GM进程不止自己(根据新的镜像队列循环队列视图和老的视图修改视图，同时根据镜像队列循环视图更新自己左右邻居信息)
                  %% 同时将当前自己节点的消息信息发布到自己右侧的GM进程
                  _      -> change_view(View1, State)
              end)
    end.
```

（2）主镜像队列回调 rabbit_mirror_queue_coordinator处理 GM 进程挂掉

```
%% 处理循环镜像队列中有死亡的镜像队列(主镜像队列接收到死亡的镜像队列不可能是主镜像队列死亡的消息，它监视的左右两侧的从镜像队列进程)
handle_cast({gm_deaths, DeadGMPids},
            State = #state { q  = #amqqueue { name = QueueName, pid = MPid } })
  when node(MPid) =:= node() ->
    %% 返回新的主镜像队列进程，死亡的镜像队列进程列表，需要新增加镜像队列的节点列表
    case rabbit_mirror_queue_misc:remove_from_queue(
           QueueName, MPid, DeadGMPids) of
        {ok, MPid, DeadPids, ExtraNodes} ->
            %% 打印镜像队列死亡的日志
            rabbit_mirror_queue_misc:report_deaths(MPid, true, QueueName,
                                                   DeadPids),
            %% 异步在ExtraNodes的所有节点上增加QName队列的从镜像队列
            rabbit_mirror_queue_misc:add_mirrors(QueueName, ExtraNodes, async),
            noreply(State);
        {error, not_found} ->
            {stop, normal, State}
    end;
```

（3）从镜像队列回调 rabbit_mirror_queue_coordinator处理 GM 进程挂掉

```
%% 从镜像队列处理有镜像队列成员死亡的消息(从镜像队列接收到主镜像队列死亡的消息)
handle_call({gm_deaths, DeadGMPids}, From,
            State = #state { gm = GM, q = Q = #amqqueue {
                                                         name = QName, pid = MPid }}) ->
    Self = self(),
    %% 返回新的主镜像队列进程，死亡的镜像队列进程列表，需要新增加镜像队列的节点列表
    case rabbit_mirror_queue_misc:remove_from_queue(QName, Self, DeadGMPids) of
        {error, not_found} -> gen_server2:reply(From, ok),
        {stop, normal, State};
        {ok, Pid, DeadPids, ExtraNodes} ->
            %% 打印镜像队列死亡的日志(Self是副镜像队列)
            rabbit_mirror_queue_misc:report_deaths(Self, false, QName, DeadPids),
            case Pid of
                %% 此情况是主镜像队列没有变化
                MPid ->
                    gen_server2:reply(From, ok),
                    %% 异步在ExtraNodes的所有节点上增加QName队列的副镜像队列
                    rabbit_mirror_queue_misc:add_mirrors(
                      QName, ExtraNodes, async),
                    noreply(State);
                %% 此情况是本从镜像队列成为主镜像队列
                Self ->
                    %% 将自己这个从镜像队列提升为主镜像队列
                    QueueState = promote_me(From, State),
                    %% 异步在ExtraNodes的所有节点上增加QName队列的副镜像队列
                    rabbit_mirror_queue_misc:add_mirrors(
                      QName, ExtraNodes, async),
                    %% 返回消息，告知自己这个从镜像队列成为主镜像队列
                    {become, rabbit_amqqueue_process, QueueState, hibernate};
                _ ->
                    %% 主镜像队列已经发生变化
                    gen_server2:reply(From, ok),
                    [] = ExtraNodes,
                    %% 确认在主节点宕机时否有为完成传输的数据，确认所有从节点都接收到主节点宕机的消息，然后传输未传输的消息。
                    ok = gm:broadcast(GM, process_death),
                    noreply(State #state { q = Q #amqqueue { pid = Pid } })
            end
    end;
```

（4）主镜像队列挂掉否选取新的主镜像队列

```
%% 返回新的主镜像队列进程，死亡的镜像队列进程列表，需要新增加镜像队列的节点列表
remove_from_queue(QueueName, Self, DeadGMPids) ->
    rabbit_misc:execute_mnesia_transaction(
      fun () ->
               %% 代码运行到这一步有可能队列已经被删除
               case mnesia:read({rabbit_queue, QueueName}) of
                   [] -> {error, not_found};
                   [Q = #amqqueue { pid        = QPid,
                                    slave_pids = SPids,
                                    gm_pids    = GMPids }] ->
                       %% 获得死亡的GM列表和存活的GM列表
                       {DeadGM, AliveGM} = lists:partition(
                                             fun ({GM, _}) ->
                                                      lists:member(GM, DeadGMPids)
                                             end, GMPids),
                       %% 获得死亡的实际进程的Pid列表
                       DeadPids  = [Pid || {_GM, Pid} <- DeadGM],
                       %% 获得存活的实际进程的Pid列表
                       AlivePids = [Pid || {_GM, Pid} <- AliveGM],
                       %% 获得slave_pids字段中存活的队列进程Pid列表
                       Alive     = [Pid || Pid <- [QPid | SPids],
                                           lists:member(Pid, AlivePids)],
                       %% 从存活的镜像队列提取出第一个镜像队列进程Pid，它是最老的镜像队列，它将作为新的主镜像队列进程
                       {QPid1, SPids1} = promote_slave(Alive),
                       Extra =
                           case {{QPid, SPids}, {QPid1, SPids1}} of
                               {Same, Same} ->
                                   [];
                               %% 此处的情况是主镜像队列没有变化，或者调用此接口的从镜像队列成为新的主镜像队列
                               _ when QPid =:= QPid1 orelse QPid1 =:= Self ->
                                   %% 主镜像队列已经变化，当前从队列变更为主队列，信息更新到数据库（mnesia）
                                   Q1 = Q#amqqueue{pid        = QPid1,
                                                   slave_pids = SPids1,
                                                   gm_pids    = AliveGM},
                                   store_updated_slaves(Q1),
                                   
                                   %% 根据队列的策略如果启动的从镜像队列需要自动同步，则进行同步操作
                                   maybe_auto_sync(Q1),
                                   %% 根据当前集群节点和从镜像队列进程所在的节点得到新增加的节点列表
                               slaves_to_start_on_failure(Q1, DeadGMPids);
                               %% 此处的情况是主镜像队列已经发生变化，且调用此接口的从镜像队列没有成为新的主镜像队列
                               _ ->
                                   %% 更新最新的存活的从镜像队列进程Pid列表和存活的GM进程列表
                                   Q1 = Q#amqqueue{slave_pids = Alive,
                                                   gm_pids    = AliveGM},
                                   %% 存储更新队列的从镜像队列信息
                                   store_updated_slaves(Q1),
                                   []
                           end,
                       {ok, QPid1, DeadPids, Extra}
               end
      end).
```


#### 镜像队列消息同步

**1.消息广播**

消息广播流程如下：

（1）Master 节点发出消息，顺着镜像队列循环列表发送；

（2）所有 Slave 节点收到消息会对消息进行缓存（Slave 节点缓存消息用于在广播过程中，有节点失效或者新增节点，这样左侧节点感知变化后会重新将消息推送给右侧节点）；

（3）当 Master 节点收到自己发送的消息后意味着所有节点都收到了消息，会再次广播 Ack 消息；

（4）Ack 消息同样会顺着循环列表经过所有 Slave 节点，通知 Slave 节点可以清除缓存消息；

（5）当 Ack 消息回到 Master 节点，对应消息的广播结束。

![MessageQueue](/images/rabbit-018.webp)

核心流程详解：

（1）GM 组群中消息广播

```
%% 节点挂掉的情况或者新增节点发送给自己右侧GM进程的信息
%% 左侧的GM进程通知右侧的GM进程最新的成员状态(此情况是有新GM进程加入Group，但是自己不是最新加入的GM进程，但是自己仍然需要更新成员信息)
handle_msg({catchup, Left, MembersStateLeft},
           State = #state { self = Self,
                            left = {Left, _MRefL},
                            view = View,
                            members_state = MembersState })
  when MembersState =/= undefined ->
    %% 将最新的成员信息转化成字典数据结构
    MembersStateLeft1 = build_members_state(MembersStateLeft),
    %% 获取左侧镜像队列传入的成员信息和自己进程存储的成员信息的ID的去重
    AllMembers = lists:usort(?DICT:fetch_keys(MembersState) ++
                        ?DICT:fetch_keys(MembersStateLeft1)),
    %% 根据左侧GM进程发送过来的成员状态和自己GM进程里的成员状态得到需要广播给后续GM进程的信息
    {MembersState1, Activity} =
        lists:foldl(
          fun (Id, MembersStateActivity) ->
                   %% 获取左侧镜像队列传入Id对应的镜像队列成员信息
                   #member { pending_ack = PALeft, last_ack = LA } =
                               find_member_or_blank(Id, MembersStateLeft1),
                   with_member_acc(
                     %% 函数的第一个参数是Id对应的自己进程存储的镜像队列成员信息
                     fun (#member { pending_ack = PA } = Member, Activity1) ->
                              %% 发送者和自己是一个人则表示消息已经发送回来，或者判断发送者是否在死亡列表中
                              case is_member_alias(Id, Self, View) of
                                  %% 此情况是发送者和自己是同一个人或者发送者已经死亡
                                  true ->
                                      %% 根据左侧GM进程发送过来的ID最新的成员信息和本GM进程ID对应的成员信息得到已经发布的信息
                                      {_AcksInFlight, Pubs, _PA1} = find_prefix_common_suffix(PALeft, PA),
                                      %% 重新将自己的消息发布
                                      {Member #member { last_ack = LA },
                                    %% 组装发送的内容和ack消息结构
                                      activity_cons(Id, pubs_from_queue(Pubs), [], Activity1)};
                                  false ->
                                      %% 根据左侧GM进程发送过来的ID最新的成员信息和本GM进程ID对应的成员信息得到Ack和Pub列表
                                      %% 上一个节点少的消息就是已经得到确认的消息，多出来的是新发布的消息
                                      {Acks, _Common, Pubs} =
                      find_prefix_common_suffix(PA, PALeft),
                                      {Member,
                                       %% 组装发送的发布和ack消息结构
                                       activity_cons(Id, pubs_from_queue(Pubs), acks_from_queue(Acks), Activity1)}
                              end
                     end, Id, MembersStateActivity)
          end, {MembersState, activity_nil()}, AllMembers),
    handle_msg({activity, Left, activity_finalise(Activity)},
               State #state { members_state = MembersState1 });
```

(2) GM 进程内部广播

```
%% GM进程内部广播的接口(先调用本GM进程的回调进程进行处理消息，然后将广播数据放入广播缓存中)
internal_broadcast(Msg, SizeHint,
                   State = #state { self                = Self,
                                    pub_count           = PubCount,
                                    module              = Module,
                                    callback_args       = Args,
                                    broadcast_buffer    = Buffer,
                                    broadcast_buffer_sz = BufferSize }) ->
    %% 将发布次数加一
    PubCount1 = PubCount + 1,
    {%% 先将消息调用回调模块进行处理
     Module:handle_msg(Args, get_pid(Self), Msg),
     %% 然后将广播消息放入广播缓存
     State #state { pub_count           = PubCount1,
                    broadcast_buffer    = [{PubCount1, Msg} | Buffer],
                    broadcast_buffer_sz = BufferSize + SizeHint}}.

```

（3）缓存消息发送定时器

```
%% 确保广播定时器的关闭和开启，当广播缓存中有数据则启动定时器，当广播缓存中没有数据则停止定时器
%% 广播缓存中没有数据，同时广播定时器不存在的情况
ensure_broadcast_timer(State = #state { broadcast_buffer = [],
                                        broadcast_timer  = undefined }) ->
    State;
%% 广播缓存中没有数据，同时广播定时器存在，则直接将定时器删除掉
ensure_broadcast_timer(State = #state { broadcast_buffer = [],
                                        broadcast_timer  = TRef }) ->
    erlang:cancel_timer(TRef),
    State #state { broadcast_timer = undefined };
%% 广播缓存中有数据且没有定时器的情况
ensure_broadcast_timer(State = #state { broadcast_timer = undefined }) ->
    TRef = erlang:send_after(?BROADCAST_TIMER, self(), flush),
    State #state { broadcast_timer = TRef };
ensure_broadcast_timer(State) ->
    State.
```

> 注：当处理消息时，缓存中的内容大小超过100M 则不会等定时器触发，会立刻将消息发给自己右侧的 GM 进程。


**2.消息同步**

配置镜像队列时有一个属性ha-sync-mode，支持两种模式 automatic 或 manually 默认为 manually。

当 ha-sync-mode = manually，新节点加入到镜像队列组后，可以从左节点获取当前正在广播的消息，但是在加入之前已经广播的消息无法获取，所以会处于镜像队列之间数据不一致的情况，直到加入之前的消息都被消费后，主从镜像队列数据保持一致。当加入之前的消息未全部消费完之前，主节点宕机，新节点选为主节点时，这部分消息将丢失。

​当 ha-sync-mode = automatic，新加入组群的 Slave 节点会自动进行消息同步，使主从镜像队列数据保持一致。





