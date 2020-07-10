
<h2>Kafka服务</h2>

-------------------------------

本部分内容直接介绍跟Kafka服务相关的知识点，包含服务端对消息的存储，生产者对消息的生产及发送，以及消费者对消息的消费来介绍。




6.Kafka 与 Zookeeper

6.1 Zookeeper协调控制

1.管理broker与consumer的动态加入与离开。(Producer不需要管理，随便一台计算机都可以作为Producer向Kakfa Broker发消息)

2.触发负载均衡，当broker或consumer加入或离开时会触发负载均衡算法，使得一

个consumer group内的多个consumer的消费负载平衡。（因为一个comsumer消费一个或多个partition，一个partition只能被一个consumer消费）

3.维护消费关系及每个partition的消费信息。

6.2 Zookeeper上的细节：

1.每个broker启动后会在zookeeper上注册一个临时的broker registry，包含broker的ip地址和端口号，所存储的topics和partitions信息。

2.每个consumer启动后会在zookeeper上注册一个临时的consumer registry：包含consumer所属的consumer group以及订阅的topics。

3.每个consumer group关联一个临时的owner registry和一个持久的offset registry。对于被订阅的每个partition包含一个owner registry，内容为订阅这个partition的consumer id；同时包含一个offset registry，内容为上一次订阅的offset。





 Kakfa的设计思想

-Kakfa Broker Leader的选举：Kakfa Broker集群受Zookeeper管理。所有的Kafka Broker节点一起去Zookeeper上注册一个临时节点，因为只有一个Kafka Broker会注册成功，其他的都会失败，所以这个成功在Zookeeper上注册临时节点的这个Kafka Broker会成为Kafka Broker Controller，其他的Kafka broker叫Kafka Broker follower。（这个过程叫Controller在ZooKeeper注册Watch）。这个Controller会监听其他的Kafka Broker的所有信息，如果这个kafka broker controller宕机了，在zookeeper上面的那个临时节点就会消失，此时所有的kafka broker又会一起去Zookeeper上注册一个临时节点，因为只有一个Kafka Broker会注册成功，其他的都会失败，所以这个成功在Zookeeper上注册临时节点的这个Kafka Broker会成为Kafka Broker Controller，其他的Kafka broker叫Kafka Broker follower。例如：一旦有一个broker宕机了，这个kafka broker controller会读取该宕机broker上所有的partition在zookeeper上的状态，并选取ISR列表中的一个replica作为partition leader（如果ISR列表中的replica全挂，选一个幸存的replica作为leader; 如果该partition的所有的replica都宕机了，则将新的leader设置为-1，等待恢复，等待ISR中的任一个Replica“活”过来，并且选它作为Leader；或选择第一个“活”过来的Replica（不一定是ISR中的）作为Leader），这个broker宕机的事情，kafka controller也会通知zookeeper，zookeeper就会通知其他的kafka broker。





Leader与Followers

一个Topic可能有很多分区，以便它能够支持海量的的数据，更重要的意义是分区是进行并行处理的基础单元。日志的分区会跨服务器的分布在Kafka集群中，每个分区可以配置一定数量的副本分区提供容错能力。为了保证较高的处理效率，消息的读写都是在固定的一个副本上完成。这个副本就是所谓的Leader，而其他副本则是Follower，而Follower则会定期地到Leader上同步数据。

(1)leader处理所有的读取和写入分区的请求，而followers被动的从领导者拷贝数据。

(2)如果leader失败了，followers之一将自动成为新的领导者。

(3)每个服务器可能充当一些分区的leader和其他分区的follower，这样的负载就会在集群内很好的均衡分配。

(4)一个分区在同一时刻只能有一个消费者实例进行消费。

(1)Leader选举与ISR

如果某个分区所在的服务器除了问题，不可用，kafka会从该分区的其他的副本中选择一个作为新的Leader。之后所有的读写就会转移到这个新的Leader上。现在的问题是应当选择哪个作为新的Leader。显然，只有那些跟Leader保持同步的Follower才应该被选作新的Leader。

Kafka会在Zookeeper上针对每个Topic维护一个称为ISR(in-sync replica，已同步的副本)的集合，该集合中是一些分区的副本。只有当这些副本都跟Leader中的副本同步了之后，kafka才会认为消息已提交，并反馈给消息的生产者。如果这个集合有增减，kafka会更新zookeeper上的记录。如果某个分区的Leader不可用，Kafka就会从ISR集合中选择一个副本作为新的Leader。显然通过ISR，kafka需要的冗余度较低，可以容忍的失败数比较高。假设某个topic有f+1个副本，kafka可以容忍f个服务器不可用。

(2)为什么不用少数服从多数的方法

少数服从多数是一种比较常见的一致性算法和Leader选举法。它的含义是只有超过半数的副本同步了，系统才会认为数据已同步;选择Leader时也是从超过半数的同步的副本中选择。这种算法需要较高的冗余度。譬如只允许一台机器失败，需要有三个副本;而如果只容忍两台机器失败，则需要五个副本。而kafka的ISR集合方法，分别只需要两个和三个副本。

(3)如果所有的ISR副本都失败了怎么办

此时有两种方法可选，一种是等待ISR集合中的副本复活，一种是选择任何一个立即可用的副本，而这个副本不一定是在ISR集合中。这两种方法各有利弊，实际生产中按需选择。如果要等待ISR副本复活，虽然可以保证一致性，但可能需要很长时间。而如果选择立即可用的副本，则很可能该副本并不一致。





-Consumer Rebalance的触发条件：（1）Consumer增加或删除会触发 Consumer Group的Rebalance（2）Broker的增加或者减少都会触发 Consumer Rebalance


6.副本

kafka中,replication策略是基于partition,而不是topic;kafka将每个partition数据复制到多个server上,任何一个partition有一个leader和多个follower(可以没有);备份的个数可以通过broker配置文件来设定。leader处理所有的read-write请求,follower需要和leader保持同步.Follower就像一个"consumer",消费消息并保存在本地日志中;leader负责跟踪所有的follower状态,如果follower"落后"太多或者失效,leader将会把它从replicas同步列表中删除.当所有的follower都将一条消息保存成功,此消息才被认为是"committed",那么此时consumer才能消费它,这种同步策略,就要求follower和leader之间必须具有良好的网络环境.即使只有一个replicas实例存活,仍然可以保证消息的正常发送和接收,只要zookeeper集群存活即可.

选择follower时需要兼顾一个问题,就是新leader server上所已经承载的partition leader的个数,如果一个server上有过多的partition leader,意味着此server将承受着更多的IO压力.在选举新leader,需要考虑到"负载均衡",partition leader较少的broker将会更有可能成为新的leader.



kafka使用zookeeper来存储一些meta信息,并使用了zookeeper watch机制来发现meta信息的变更并作出相应的动作(比如consumer失效,触发负载均衡等)

Broker node registry: 当一个kafka broker启动后,首先会向zookeeper注册自己的节点信息(临时znode),同时当broker和zookeeper断开连接时,此znode也会被删除.

Broker Topic Registry: 当一个broker启动时,会向zookeeper注册自己持有的topic和partitions信息,仍然是一个临时znode.

Consumer and Consumer group: 每个consumer客户端被创建时,会向zookeeper注册自己的信息;此作用主要是为了"负载均衡".一个group中的多个consumer可以交错的消费一个topic的所有partitions;简而言之,保证此topic的所有partitions都能被此group所消费,且消费时为了性能考虑,让partition相对均衡的分散到每个consumer上.

Consumer id Registry: 每个consumer都有一个唯一的ID(host:uuid,可以通过配置文件指定,也可以由系统生成),此id用来标记消费者信息.

Consumer offset Tracking: 用来跟踪每个consumer目前所消费的partition中最大的offset.此znode为持久节点,可以看出offset跟group_id有关,以表明当group中一个消费者失效,其他consumer可以继续消费.

Partition Owner registry: 用来标记partition正在被哪个consumer消费.临时znode。此节点表达了"一个partition"只能被group下一个consumer消费,同时当group下某个consumer失效,那么将会触发负载均衡(即:让partitions在多个consumer间均衡消费,接管那些"游离"的partitions)

当consumer启动时,所触发的操作:

A) 首先进行"Consumer id Registry";

B) 然后在"Consumer id Registry"节点下注册一个watch用来监听当前group中其他consumer的"leave"和"join";只要此znode path下节点列表变更,都会触发此group下consumer的负载均衡.(比如一个consumer失效,那么其他consumer接管partitions).

C) 在"Broker id registry"节点下,注册一个watch用来监听broker的存活情况;如果broker列表变更,将会触发所有的groups下的consumer重新balance.

总结:

1) Producer端使用zookeeper用来"发现"broker列表,以及和Topic下每个partition leader建立socket连接并发送消息.

2) Broker端使用zookeeper用来注册broker信息,已经监测partition leader存活性.

3) Consumer端使用zookeeper用来注册consumer信息,其中包括consumer消费的partition列表等,同时也用来发现broker列表,并和partition leader建立socket连接,并获取消息。



Leader与副本同步

对于某个分区来说，保存正分区的"broker"为该分区的"leader"，保存备份分区的"broker"为该分区的"follower"。备份分区会完全复制正分区的消息，包括消息的编号等附加属性值。为了保持正分区和备份分区的内容一致，Kafka采取的方案是在保存备份分区的"broker"上开启一个消费者进程进行消费，从而使得正分区的内容与备份分区的内容保持一致。一般情况下，一个分区有一个“正分区”和零到多个“备份分区”。可以配置“正分区+备份分区”的总数量，关于这个配置，不同主题可以有不同的配置值。注意，生产者，消费者只与保存正分区的"leader"进行通信。

Kafka允许topic的分区拥有若干副本，这个数量是可以配置的，你可以为每个topic配置副本的数量。Kafka会自动在每个副本上备份数据，所以当一个节点down掉时数据依然是可用的。

Kafka的副本功能不是必须的，你可以配置只有一个副本，这样其实就相当于只有一份数据。

创建副本的单位是topic的分区，每个分区都有一个leader和零或多个followers.所有的读写操作都由leader处理，一般分区的数量都比broker的数量多的多，各分区的leader均匀的分布在brokers中。所有的followers都复制leader的日志，日志中的消息和顺序都和leader中的一致。followers向普通的consumer那样从leader那里拉取消息并保存在自己的日志文件中。

许多分布式的消息系统自动的处理失败的请求，它们对一个节点是否着（alive）”有着清晰的定义。Kafka判断一个节点是否活着有两个条件：

1. 节点必须可以维护和ZooKeeper的连接，Zookeeper通过心跳机制检查每个节点的连接。

2. 如果节点是个follower,他必须能及时的同步leader的写操作，延时不能太久。

符合以上条件的节点准确的说应该是“同步中的（in sync）”，而不是模糊的说是“活着的”或是“失败的”。Leader会追踪所有“同步中”的节点，一旦一个down掉了，或是卡住了，或是延时太久，leader就会把它移除。至于延时多久算是“太久”，是由参数replica.lag.max.messages决定的，怎样算是卡住了，怎是由参数replica.lag.time.max.ms决定的。

只有当消息被所有的副本加入到日志中时，才算是“committed”，只有committed的消息才会发送给consumer，这样就不用担心一旦leader down掉了消息会丢失。Producer也可以选择是否等待消息被提交的通知，这个是由参数acks决定的。

Kafka保证只要有一个“同步中”的节点，“committed”的消息就不会丢失。




Producers直接发送消息到broker上的leader partition，不需要经过任何中介或其他路由转发。为了实现这个特性，kafka集群中的每个broker都可以响应producer的请求，并返回topic的一些元信息，这些元信息包括哪些机器是存活的，topic的leader partition都在哪，现阶段哪些leader partition是可以直接被访问的。

Producer客户端自己控制着消息被推送到哪些partition。实现的方式可以是随机分配、实现一类随机负载均衡算法，或者指定一些分区算法。Kafka提供了接口供用户实现自定义的partition，用户可以为每个消息指定一个partitionKey，通过这个key来实现一些hash分区算法。比如，把userid作为partitionkey的话，相同userid的消息将会被推送到同一个partition。

以Batch的方式推送数据可以极大的提高处理效率，kafka Producer 可以将消息在内存中累计到一定数量后作为一个batch发送请求。Batch的数量大小可以通过Producer的参数控制，参数值可以设置为累计的消息的数量（如500条）、累计的时间间隔（如100ms）或者累计的数据大小(64KB)。通过增加batch的大小，可以减少网络请求和磁盘IO的次数，当然具体参数设置需要在效率和时效性方面做一个权衡。

Producers可以异步的并行的向kafka发送消息，但是通常producer在发送完消息之后会得到一个future响应，返回的是offset值或者发送过程中遇到的错误。这其中有个非常重要的参数“acks”,这个参数决定了producer要求leader partition 收到确认的副本个数，如果acks设置数量为0，表示producer不会等待broker的响应，所以，producer无法知道消息是否发送成功，这样有可能会导致数据丢失，但同时，acks值为0会得到最大的系统吞吐量。

若acks设置为1，表示producer会在leader partition收到消息时得到broker的一个确认，这样会有更好的可靠性，因为客户端会等待直到broker确认收到消息。若设置为-1，producer会在所有备份的partition收到消息时得到broker的确认，这个设置可以得到最高的可靠性保证。

Kafka 消息有一个定长的header和变长的字节数组组成。因为kafka消息支持字节数组，也就使得kafka可以支持任何用户自定义的序列号格式或者其它已有的格式如Apache Avro、protobuf等。Kafka没有限定单个消息的大小，但我们推荐消息大小不要超过1MB,通常一般消息大小都在1~10kB之前。

发布消息时，kafka client先构造一条消息，将消息加入到消息集set中（kafka支持批量发布，可以往消息集合中添加多条消息，一次行发布），send消息时，producer client需指定消息所属的topic。




Consumers

Kafka提供了两套consumer api，分为high-level api和sample-api。Sample-api 是一个底层的API，它维持了一个和单一broker的连接，并且这个API是完全无状态的，每次请求都需要指定offset值，因此，这套API也是最灵活的。

在kafka中，当前读到哪条消息的offset值是由consumer来维护的，因此，consumer可以自己决定如何读取kafka中的数据。比如，consumer可以通过重设offset值来重新消费已消费过的数据。不管有没有被消费，kafka会保存数据一段时间，这个时间周期是可配置的，只有到了过期时间，kafka才会删除这些数据。（这一点与AMQ不一样，AMQ的message一般来说都是持久化到mysql中的，消费完的message会被delete掉）

High-level API封装了对集群中一系列broker的访问，可以透明的消费一个topic。它自己维持了已消费消息的状态，即每次消费的都是下一个消息。

High-level API还支持以组的形式消费topic，如果consumers有同一个组名，那么kafka就相当于一个队列消息服务，而各个consumer均衡的消费相应partition中的数据。若consumers有不同的组名，那么此时kafka就相当与一个广播服务，会把topic中的所有消息广播到每个consumer。

High level api和Low level api是针对consumer而言的，和producer无关。

High level api是consumer读的partition的offsite是存在zookeeper上。High level api会启动另外一个线程去每隔一段时间，offsite自动同步到zookeeper上。换句话说，如果使用了High level api， 每个message只能被读一次，一旦读了这条message之后，无论我consumer的处理是否ok。High level api的另外一个线程会自动的把offiste+1同步到zookeeper上。如果consumer读取数据出了问题，offsite也会在zookeeper上同步。因此，如果consumer处理失败了，会继续执行下一条。这往往是不对的行为。因此，Best Practice是一旦consumer处理失败，直接让整个conusmer group抛Exception终止，但是最后读的这一条数据是丢失了，因为在zookeeper里面的offsite已经+1了。等再次启动conusmer group的时候，已经从下一条开始读取处理了。

Low level api是consumer读的partition的offsite在consumer自己的程序中维护。不会同步到zookeeper上。但是为了kafka manager能够方便的监控，一般也会手动的同步到zookeeper上。这样的好处是一旦读取某个message的consumer失败了，这条message的offsite我们自己维护，我们不会+1。下次再启动的时候，还会从这个offsite开始读。这样可以做到exactly once对于数据的准确性有保证。

对于Consumer group：

1. 允许consumer group（包含多个consumer，如一个集群同时消费）对一个topic进行消费，不同的consumer group之间独立消费。

2. 为了对减小一个consumer group中不同consumer之间的分布式协调开销，指定partition为最小的并行消费单位，即一个group内的consumer只能消费不同的partition。

![consumer-group](/images/consumer-group.webp)

Consumer与Partition的关系：

- 如果consumer比partition多，是浪费，因为kafka的设计是在一个partition上是不允许并发的，所以consumer数不要大于partition数

- 如果consumer比partition少，一个consumer会对应于多个partitions，这里主要合理分配consumer数和partition数，否则会导致partition里面的数据被取的不均匀

- 如果consumer从多个partition读到数据，不保证数据间的顺序性，kafka只保证在一个partition上数据是有序的，但多个partition，根据你读的顺序会有不同

- 增减consumer，broker，partition会导致rebalance，所以rebalance后consumer对应的partition会发生变化

- High-level接口中获取不到数据的时候是会block的

负载低的情况下可以每个线程消费多个partition。但负载高的情况下，Consumer 线程数最好和Partition数量保持一致。如果还是消费不过来，应该再开 Consumer 进程，进程内线程数同样和分区数一致。

消费消息时，kafka client需指定topic以及partition number（每个partition对应一个逻辑日志流，如topic代表某个产品线，partition代表产品线的日志按天切分的结果），consumer client订阅后，就可迭代读取消息，如果没有消息，consumer client会阻塞直到有新的消息发布。consumer可以累积确认接收到的消息，当其确认了某个offset的消息，意味着之前的消息也都已成功接收到，此时broker会更新zookeeper上地offset registry。






高可靠分布式存储模型

在 Kafka 中保证高可靠模型依靠的是副本机制，有了副本机制之后，就算机器宕机也不会发生数据丢失。

高性能的日志存储

Kafka 一个 Topic 下面的所有消息都是以 Partition 的方式分布式的存储在多个节点上。

同时在 Kafka 的机器上，每个 Partition 其实都会对应一个日志目录，在目录下面会对应多个日志分段(LogSegment)。

LogSegment 文件由两部分组成，分别为“.index”文件和“.log”文件，分别表示为 Segment 索引文件和数据文件。

这两个文件的命令规则为：Partition 全局的第一个 Segment 从 0 开始，后续每个 Segment 文件名为上一个 Segment 文件最后一条消息的 Offset 值，数值大小为 64 位，20 位数字字符长度，没有数字用 0 填充。

如下，假设有 1000 条消息，每个 LogSegment 大小为 100，下面展现了 900-1000 的索引和 Log：

![kafka-log](/images/kafka-log.webp)




由于 Kafka 消息数据太大，如果全部建立索引，既占了空间又增加了耗时，所以 Kafka 选择了稀疏索引的方式，这样索引可以直接进入内存，加快偏查询速度。

简单介绍一下如何读取数据，如果我们要读取第 911 条数据首先第一步，找到它是属于哪一段的。

根据二分法查找到它属于的文件，找到 0000900.index 和 00000900.log 之后，然后去 index 中去查找 (911-900) = 11 这个索引或者小于 11 最近的索引。

在这里通过二分法我们找到了索引是 [10,1367]，然后我们通过这条索引的物理位置 1367，开始往后找，直到找到 911 条数据。

上面讲的是如果要找某个 Offset 的流程，但是我们大多数时候并不需要查找某个 Offset，只需要按照顺序读即可。

而在顺序读中，操作系统会在内存和磁盘之间添加 Page Cache，也就是我们平常见到的预读操作，所以我们的顺序读操作时速度很快。

但是 Kafka 有个问题，如果分区过多，那么日志分段也会很多，写的时候由于是批量写，其实就会变成随机写了，随机 I/O 这个时候对性能影响很大。所以一般来说 Kafka 不能有太多的 Partition。

针对这一点，RocketMQ 把所有的日志都写在一个文件里面，就能变成顺序写，通过一定优化，读也能接近于顺序读。

大家可以思考一下：

• 为什么需要分区，也就是说主题只有一个分区，难道不行吗?

• 日志为什么需要分段?

副本机制

Kafka 的副本机制是多个服务端节点对其他节点的主题分区的日志进行复制。

当集群中的某个节点出现故障，访问故障节点的请求会被转移到其他正常节点(这一过程通常叫 Reblance)。

Kafka 每个主题的每个分区都有一个主副本以及 0 个或者多个副本，副本保持和主副本的数据同步，当主副本出故障时就会被替代。


![replicas](/images/replicas.webp)



在 Kafka 中并不是所有的副本都能被拿来替代主副本，所以在 Kafka 的 Leader 节点中维护着一个 ISR(In Sync Replicas)集合。

翻译过来也叫正在同步中集合，在这个集合中的需要满足两个条件：

• 节点必须和 ZK 保持连接。

• 在同步的过程中这个副本不能落后主副本太多。

另外还有个 AR(Assigned Replicas)用来标识副本的全集，OSR 用来表示由于落后被剔除的副本集合。

所以公式如下：ISR = Leader + 没有落后太多的副本;AR = OSR+ ISR。

这里先要说下两个名词：HW(高水位)是 Consumer 能够看到的此 Partition 的位置，LEO 是每个 Partition 的 Log 最后一条 Message 的位置。

HW 能保证 Leader 所在的 Broker 失效，该消息仍然可以从新选举的 Leader 中获取，不会造成消息丢失。

当 Producer 向 Leader 发送数据时，可以通过 request.required.acks 参数来设置数据可靠性的级别：

• 1(默认)：这意味着 Producer 在 ISR 中的 Leader 已成功收到的数据并得到确认后发送下一条 Message。如果 Leader 宕机了，则会丢失数据。

• 0：这意味着 Producer 无需等待来自 Broker 的确认而继续发送下一批消息。这种情况下数据传输效率最高，但是数据可靠性却是最低的。

• -1：Producer 需要等待 ISR 中的所有 Follower 都确认接收到数据后才算一次发送完成，可靠性最高。

但是这样也不能保证数据不丢失，比如当 ISR 中只有 Leader 时(其他节点都和 ZK 断开连接，或者都没追上)，这样就变成了 acks = 1 的情况。

高可用模型及幂等

在分布式系统中一般有三种处理语义：

at-least-once

至少一次，有可能会有多次。如果 Producer 收到来自 Ack 的确认，则表示该消息已经写入到 Kafka 了，此时刚好是一次，也就是我们后面的 Exactly-once。

但是如果 Producer 超时或收到错误，并且 request.required.acks 配置的不是 -1，则会重试发送消息，客户端会认为该消息未写入 Kafka。

如果 Broker 在发送 Ack 之前失败，但在消息成功写入 Kafka 之后，这一次重试将会导致我们的消息会被写入两次。

所以消息就不止一次地传递给最终 Consumer，如果 Consumer 处理逻辑没有保证幂等的话就会得到不正确的结果。

在这种语义中会出现乱序，也就是当第一次 Ack 失败准备重试的时候，但是第二消息已经发送过去了，这个时候会出现单分区中乱序的现象。

我们需要设置 Prouducer 的参数 max.in.flight.requests.per.connection，flight.requests 是 Producer 端用来保存发送请求且没有响应的队列，保证 Produce r端未响应的请求个数为 1。

at-most-once

如果在 Ack 超时或返回错误时 Producer 不重试，也就是我们讲 request.required.acks = -1，则该消息可能最终没有写入 Kafka，所以 Consumer 不会接收消息。

exactly-once

刚好一次，即使 Producer 重试发送消息，消息也会保证最多一次地传递给 Consumer。该语义是最理想的，也是最难实现的。

在 0.10 之前并不能保证 exactly-once，需要使用 Consumer 自带的幂等性保证。0.11.0 使用事务保证了。

如何实现 exactly-once

要实现 exactly-once 在 Kafka 0.11.0 中有两个官方策略：

单 Producer 单 Topic

每个 Producer 在初始化的时候都会被分配一个唯一的 PID，对于每个唯一的 PID，Producer 向指定的 Topic 中某个特定的 Partition 发送的消息都会携带一个从 0 单调递增的 Sequence Number。

在我们的 Broker 端也会维护一个维度为，每次提交一次消息的时候都会对齐进行校验：

• 如果消息序号比 Broker 维护的序号大一以上，说明中间有数据尚未写入，也即乱序，此时 Broker 拒绝该消息，Producer 抛出 InvalidSequenceNumber。

• 如果消息序号小于等于 Broker 维护的序号，说明该消息已被保存，即为重复消息，Broker 直接丢弃该消息，Producer 抛出 DuplicateSequenceNumber。

如果消息序号刚好大一，就证明是合法的。

上面所说的解决了两个问题：

• 当 Prouducer 发送了一条消息之后失败，Broker 并没有保存，但是第二条消息却发送成功，造成了数据的乱序。

• 当 Producer 发送了一条消息之后，Broker 保存成功，Ack 回传失败，Producer 再次投递重复的消息。

上面所说的都是在同一个 PID 下面，意味着必须保证在单个 Producer 中的同一个 Seesion 内，如果 Producer 挂了，被分配了新的 PID，这样就无法保证了，所以 Kafka 中又有事务机制去保证。












