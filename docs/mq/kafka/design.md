
<h2> kafka的 架构设计 </h2>

文章参考：https://www.jianshu.com/p/bde902c57e80 
https://www.jianshu.com/p/4bf007885116 
https://www.jianshu.com/p/7008d2a1e320

---------------------------------------

### Kafka 整体架构

Kafka架构图 

![Kafka 架构](/images/kafka.webp)

- 一个kafka集群由一个或多个broker服务器组成，它负责持久化和备份具体的kafka消息。

- Kafka中发布订阅的对象是topic。我们可以为每类数据创建一个topic，把向topic发布消息的客户端称作producer，从topic订阅消息的客户端称作consumer。Producers和consumers可以同时从多个topic读写数据。

- Kafka通过Zookeeper管理集群配置，选举leader，以及在consumer group发生变化时进行rebalance。

- producer使用push模式将消息发布到broker，consumer使用pull模式从 broker订阅并消费消息。


#### Kafka核心API：

- 生产者 API： 允许应用程序发布记录流至一个或多个Kafka的话题(Topics)。

- 消费者API： 允许应用程序订阅一个或多个主题，并处理这些主题接收到的记录流。

- Streams API： 允许应用程序充当流处理器(stream processor)，从一个或多个主题获取输入流，并生产一个输出流至一个或多个的主题，能够有效地变换输入流为输出流。

- Connector API： 允许构建和运行可重用的生产者或消费者，能够把 Kafka主题连接到现有的应用程序或数据系统。例如，一个连接到关系数据库的连接器(connector)可能会获取每个表的变化。

> Kafka的客户端和服务器之间的通信是靠一个简单的，高性能的，与语言无关的TCP协议完成的。这个协议有不同的版本，并保持向前兼容旧版本。Kafka不光提供了一个Java客户端，还有许多语言版本的客户端。


### 核心概念简介

Kafka的核心组件（概念）包含Borker，Topic主题，Partition分区，Producer生产者，Consumer group（Consumer消费者）等；先对Kafka中的概念有个大致的了解，具体的介绍参见每个核心功能的具体介绍页面。

- Broker：Kafka节点，一个Kafka节点就是一个broker，多个broker可以组成一个Kafka集群。

- Topic：一类消息，消息存放的目录即主题，例如page view日志、click日志等都可以以topic的形式存在，Kafka集群能够同时负责多个topic的分发。

- Partition：topic物理上的分组，一个topic可以分为多个partition，每个partition是一个有序的队列

- Segment：partition物理上由多个segment组成，每个Segment存着message信息

- Producer: 生产message发送到topic

- Consumer: 订阅topic消费message, consumer作为一个线程来消费

- Consumer Group：一个Consumer Group包含多个consumer, 这个是预先在配置文件中配置好的。各个consumer（consumer 线程）可以组成一个组（Consumer group ），partition中的每个message只能被组（Consumer group ） 中的一个consumer（consumer 线程 ）消费，如果一个message可以被多个consumer（consumer 线程 ） 消费的话，那么这些consumer必须在不同的组。Kafka不支持一个partition中的message由两个或两个以上的consumer thread来处理，即便是来自不同的consumer group的也不行。它不能像AMQ那样可以多个BET作为consumer去处理message，这是因为多个BET去消费一个Queue中的数据的时候，由于要保证不能多个线程拿同一条message，所以就需要行级别悲观所（for update）,这就导致了consume的性能下降，吞吐量不够。而kafka为了保证吞吐量，只允许一个consumer线程去访问一个partition。如果觉得效率不高的时候，可以加partition的数量来横向扩展，那么再加新的consumer thread去消费。这样没有锁竞争，充分发挥了横向的扩展性，吞吐量极高。这也就形成了分布式消费的概念。



#### Broker

Broker 即代理服务器，kafka 部署在集群中的多台机器上，其中的每一台服务器即 Broker，它代表 kafka 的一个实例或节点，多个 Broker 构成一个 kafka 集群。一个机器上可以部署一个或者多个Broker，这多个Broker连接到相同的ZooKeeper就组成了Kafka集群。

![Broker](/images/broker.webp)


#### Topic

Topic 即主题（Kafka的核心抽象概念记录流 ）；主题是一种分类或发布的一系列记录的名义上的名字。Kafka的主题始终是支持多用户订阅的; 也就是说，一个主题可以有零个，一个或多个消费者订阅写入的数据。

**Topic 与broker**

一个Broker上可以创建一个或者多个Topic。同一个topic可以在同一集群下的多个Broker中分布。

![Topic](/images/topic.webp)

Topic 在逻辑上可以被认为是一个 queue，每条消费都必须指定它的topic，可以简单理解为必须指明把这条消息放进哪个queue里。 为了使得Kafka的吞吐率可以水平扩展，物理上把topic分成一个或多个partition，每个partition在物理上对应一个文件夹，该文件 夹下存储这个partition的所有消息和索引文件。

> Topic只是一个名义上的组件，真正在Broker间分布式的Partition。


#### Partition与日志

parition是物理上的概念，每个topic包含一个或多个partition，创建topic时可指定parition数量。每个partition对应于一个文件夹，该文件夹下存储该partition的数据和索引文件


Kafka会为每个topic维护了多个分区(partition)，每个分区会映射到一个逻辑的日志(log)文件。每个分区是一个有序的，不可变的消息序列，新的消息不断追加到这个有组织的有保证的日志上。分区会给每个消息记录分配一个顺序ID号 – 偏移量， 能够唯一地标识该分区中的每个记录。

日志分区是分布式的存在于一个kafka集群的多个broker上。每个partition会被复制多份存在于不同的broker上。这样做是为了容灾。具体会复制几份，会复制到哪些broker上，都是可以配置的。经过相关的复制策略后，每个topic在每个broker上会驻留一到多个partition：

![Partition](/images/partition.webp)


> 一个broker中不会出现两个一样的Partition，replica会被均匀的分布在各个kafka server(broker)上 。Kafka并不允许replicas 数设置大于 broker数，因为在一个broker上如果有2个replica其实是没有意义的，因为再多的replica同时在一台broker上，随着该broker的crash，一起不可用。


#### Segment

partition物理上由多个segment组成，每个Segment存着message信息 



#### 保留策略与Offset

Kafka集群保留所有发布的记录，不管这个记录有没有被消费过，Kafka提供可配置的保留策略去删除旧数据(还有一种策略根据分区大小删除数据)。例如，如果将保留策略设置为两天，在记录公布后两天内，它可用于消费，之后它将被丢弃以腾出空间。Kafka的性能跟存储的数据量的大小无关， 所以将数据存储很长一段时间是没有问题的。

![Offset](/images/offset.webp)


事实上，保留在每个消费者元数据中的最基础的数据就是消费者正在处理的当前记录的偏移量(offset)或位置(position)。这种偏移是由消费者控制：通常偏移会随着消费者读取记录线性前进，但事实上，因为其位置是由消费者进行控制，消费者可以在任何它喜欢的位置读取记录。例如，消费者可以恢复到旧的偏移量对过去的数据再加工或者直接跳到最新的记录，并消费从“现在”开始的新的记录。

这些功能的结合意味着，实现Kafka的消费者的代价都是很小的，他们可以增加或者减少而不会对集群或其他消费者有太大影响。例如，你可以使用我们的命令行工具去追随任何主题，而且不会改变任何现有的消费者消费的记录。


#### Leader与Followers

一个Topic可能有很多分区，以便它能够支持海量的的数据，更重要的意义是分区是进行并行处理的基础单元。日志的分区会跨服务器的分布在Kafka集群中，每个分区可以配置一定数量的副本分区提供容错能力。为了保证较高的处理效率，消息的读写都是在固定的一个副本上完成。这个副本就是所谓的Leader，而其他副本则是Follower，而Follower则会定期地到Leader上同步数据。

(1)leader处理所有的读取和写入分区的请求，而followers被动的从领导者拷贝数据。

(2)如果leader失败了，followers之一将自动成为新的领导者。

(3)每个服务器可能充当一些分区的leader和其他分区的follower，这样的负载就会在集群内很好的均衡分配。

(4)一个分区在同一时刻只能有一个消费者实例进行消费。

![Leader](/images/leader.webp)

 
**Leader选举与ISR**

如果某个分区所在的服务器除了问题，不可用，kafka会从该分区的其他的副本中选择一个作为新的Leader。之后所有的读写就会转移到这个新的Leader上。现在的问题是应当选择哪个作为新的Leader。显然，只有那些跟Leader保持同步的Follower才应该被选作新的Leader。

Kafka会在Zookeeper上针对每个Topic维护一个称为ISR(in-sync replica，已同步的副本)的集合，该集合中是一些分区的副本。只有当这些副本都跟Leader中的副本同步了之后，kafka才会认为消息已提交，并反馈给消息的生产者。如果这个集合有增减，kafka会更新zookeeper上的记录。如果某个分区的Leader不可用，Kafka就会从ISR集合中选择一个副本作为新的Leader。显然通过ISR，kafka需要的冗余度较低，可以容忍的失败数比较高。假设某个topic有f+1个副本，kafka可以容忍f个服务器不可用。


**为什么不用少数服从多数的方法**

少数服从多数是一种比较常见的一致性算法和Leader选举法。它的含义是只有超过半数的副本同步了，系统才会认为数据已同步;选择Leader时也是从超过半数的同步的副本中选择。这种算法需要较高的冗余度。譬如只允许一台机器失败，需要有三个副本;而如果只容忍两台机器失败，则需要五个副本。而kafka的ISR集合方法，分别只需要两个和三个副本。

**如果所有的ISR副本都失败了怎么办**

此时有两种方法可选，一种是等待ISR集合中的副本复活，一种是选择任何一个立即可用的副本，而这个副本不一定是在ISR集合中。这两种方法各有利弊，**实际生产中按需选择**。如果要等待ISR副本复活，虽然可以保证一致性，但可能需要很长时间。而如果选择立即可用的副本，则很可能该副本并不一致。


#### 生产者和消费者

**生产者**

生产者发布数据到他们所选择的主题。生产者负责选择把记录分配到主题中的哪个分区。这可以使用轮询算法( round-robin)进行简单地平衡负载，也可以根据一些更复杂的语义分区算法(比如基于记录一些键值)来完成。

**消费者**

消费者以消费群(consumer group)的名称来标识自己，每个发布到主题的消息都会发送给订阅了这个主题的消费群里面的一个消费者实例，即一个消费群只发送一次。消费者的实例可以在单独的进程或单独的机器上。

![consumer group](/images/consumer.webp)



#### 消费模型


消息由生产者发送到 Kafka 集群后，会被消费者消费。一般来说我们的消费模型有两种：

• 推送模型(Push)

• 拉取模型(Pull)





#### 网络模型

- Kafka Client：单线程 Selector

![单线程 Selector](/images/client-selector.webp)

单线程模式适用于并发链接数小，逻辑简单，数据量小的情况。在 Kafka 中，Consumer 和 Producer 都是使用的上面的单线程模式。

> 这种模式不适合 Kafka 的服务端，在服务端中请求处理过程比较复杂，会造成线程阻塞，一旦出现后续请求就会无法处理，会造成大量请求超时，引起雪崩。而在服务器中应该充分利用多线程来处理执行逻辑。

- Kafka Server：多线程 Selector

![多线程 Selector](/images/server-selector.webp)

在 Kafka 服务端采用的是多线程的 Selector 模型，Acceptor 运行在一个单独的线程中，对于读取操作的线程池中的线程都会在 Selector 注册 Read 事件，负责服务端读取请求的逻辑。

成功读取后，将请求放入 Message Queue共享队列中。然后在写线程池中，取出这个请求，对其进行逻辑处理。

这样，即使某个请求线程阻塞了，还有后续的线程从消息队列中获取请求并进行处理，在写线程中处理完逻辑处理，由于注册了 OP_WIRTE 事件，所以还需要对其发送响应。




