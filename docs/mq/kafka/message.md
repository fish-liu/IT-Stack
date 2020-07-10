
<h2>Kafka的消息</h2>

参考文章：[全面解析kafka架构与原理](https://www.jianshu.com/p/bde902c57e80 ) 
[Kafka史上最详细原理总结](https://www.jianshu.com/p/7008d2a1e320)

[Kafka的架构原理，你真的理解吗？](https://www.jianshu.com/p/4bf007885116)

-------------------------------



本部分内容直接介绍跟消息相关的知识点，包含服务端对消息的存储设计，生产者对消息的生产及发送，以及消费者对消息的消费来介绍。


### 消息的存储

Kafka 将消息持久化到磁盘上，并且支持数据备份防止数据丢失从而达到消息的 **持久性、可靠性**





#### 服务端对消息的存储设计

知识回顾：

Kafka是文件存储，每个topic有多个partition，每个partition有多个replica副本(每个partition和replica都是均匀分配在不同的kafka broker上的)。每个partition由多个segment文件组成。这些文件是顺序存储的。因此读取和写入都是顺序的，因此，速度很快，省去了磁盘寻址的时间。

很多系统、组件为了提升效率一般恨不得把所有数据都扔到内存里，然后定期flush到磁盘上;而Kafka决定直接使用页面缓存;但是随机写入的效率很慢，为了维护彼此的关系顺序还需要额外的操作和存储，而线性的顺序写入可以避免磁盘寻址时间，实际上，线性写入(linear write)的速度大约是300MB/秒，但随即写入却只有50k/秒，其中的差别接近10000倍。这样，Kafka以页面缓存为中间的设计在保证效率的同时还提供了消息的持久化，每个consumer自己维护当前读取数据的offset(也可委托给zookeeper)，以此可同时支持在线和离线的消费。


Partition Recovery(恢复)机制

每个Partition会在磁盘记录一个RecoveryPoint，记录已经flush到磁盘的最大offset。当broker fail 重启时，会进行loadLogs。 首先会读取该Partition的RecoveryPoint，找到包含RecoveryPoint的segment及以后的segment， 这些segment就是可能没有完全flush到磁盘segments。然后调用segment的recover，重新读取各个segment的msg，并重建索引。

优点

• 以segment为单位管理Partition数据，方便数据生命周期的管理，删除过期数据简单。

• 在程序崩溃重启时，加快recovery速度，只需恢复未完全flush到磁盘的segment。

• 通过index中offset与物理偏移映射，用二分查找能快速定位msg，并且通过分多个Segment，每个index文件很小，查找速度更快。

3.2 Partition Replica同步机制

• Partition的多个replica中一个为Leader，其余为follower

• Producer只与Leader交互，把数据写入到Leader中

• Followers从Leader中拉取数据进行数据同步

• Consumer只从Leader拉取数据

ISR：in-sync replica，已同步的副本。准确的定义是“所有不落后的replica集合”。不落后有两层含义:距离上次FetchRequest的时间不大于某一个值或落后的消息数不大于某一个值， Leader失败后会从ISR中选取一个Follower做Leader。


-Delivery Mode :Kafka producer 发送message不用维护message的offsite信息，因为这个时候，offsite就相当于一个自增id，producer就尽管发送message就好了。而且Kafka与AMQ不同，AMQ大都用在处理业务逻辑上，而Kafka大都是日志，所以Kafka的producer一般都是大批量的batch发送message，向这个topic一次性发送一大批message，load balance到一个partition上，一起插进去，offsite作为自增id自己增加就好。但是Consumer端是需要维护这个partition当前消费到哪个message的offsite信息的，这个offsite信息，high level api是维护在Zookeeper上，low level api是自己的程序维护。（Kafka管理界面上只能显示high level api的consumer部分，因为low level api的partition offsite信息是程序自己维护，kafka是不知道的，无法在管理界面上展示 ）当使用high level api的时候，先拿message处理，再定时自动commit offsite+1（也可以改成手动）, 并且kakfa处理message是没有锁操作的。因此如果处理message失败，此时还没有commit offsite+1，当consumer thread重启后会重复消费这个message。但是作为高吞吐量高并发的实时处理系统，at least once的情况下，至少一次会被处理到，是可以容忍的。如果无法容忍，就得使用low level api来自己程序维护这个offsite信息，那么想什么时候commit offsite+1就自己搞定了。

-Topic & Partition：Topic相当于传统消息系统MQ中的一个队列queue，producer端发送的message必须指定是发送到哪个topic，但是不需要指定topic下的哪个partition，因为kafka会把收到的message进行load balance，均匀的分布在这个topic下的不同的partition上（ hash(message) % [broker数量]  ）。物理上存储上，这个topic会分成一个或多个partition，每个partiton相当于是一个子queue。在物理结构上，每个partition对应一个物理的目录（文件夹），文件夹命名是[topicname]_[partition]_[序号]，一个topic可以有无数多的partition，根据业务需求和数据量来设置。在kafka配置文件中可随时更高num.partitions参数来配置更改topic的partition数量，在创建Topic时通过参数指定parittion数量。Topic创建之后通过Kafka提供的工具也可以修改partiton数量。

一般来说，（1）一个Topic的Partition数量大于等于Broker的数量，可以提高吞吐率。（2）同一个Partition的Replica尽量分散到不同的机器，高可用。

当add a new partition的时候，partition里面的message不会重新进行分配，原来的partition里面的message数据不会变，新加的这个partition刚开始是空的，随后进入这个topic的message就会重新参与所有partition的load balance

-Partition Replica：每个partition可以在其他的kafka broker节点上存副本，以便某个kafka broker节点宕机不会影响这个kafka集群。存replica副本的方式是按照kafka broker的顺序存。例如有5个kafka broker节点，某个topic有3个partition，每个partition存2个副本，那么partition1存broker1,broker2，partition2存broker2,broker3。。。以此类推（replica副本数目不能大于kafka broker节点的数目，否则报错。这里的replica数其实就是partition的副本总数，其中包括一个leader，其他的就是copy副本）。这样如果某个broker宕机，其实整个kafka内数据依然是完整的。但是，replica副本数越高，系统虽然越稳定，但是回来带资源和性能上的下降；replica副本少的话，也会造成系统丢数据的风险。

（1）怎样传送消息：producer先把message发送到partition leader，再由leader发送给其他partition follower。（如果让producer发送给每个replica那就太慢了）

（2）在向Producer发送ACK前需要保证有多少个Replica已经收到该消息：根据ack配的个数而定

（3）怎样处理某个Replica不工作的情况：如果这个部工作的partition replica不在ack列表中，就是producer在发送消息到partition leader上，partition leader向partition follower发送message没有响应而已，这个不会影响整个系统，也不会有什么问题。如果这个不工作的partition replica在ack列表中的话，producer发送的message的时候会等待这个不工作的partition replca写message成功，但是会等到time out，然后返回失败因为某个ack列表中的partition replica没有响应，此时kafka会自动的把这个部工作的partition replica从ack列表中移除，以后的producer发送message的时候就不会有这个ack列表下的这个部工作的partition replica了。

（4）怎样处理Failed Replica恢复回来的情况：如果这个partition replica之前不在ack列表中，那么启动后重新受Zookeeper管理即可，之后producer发送message的时候，partition leader会继续发送message到这个partition follower上。如果这个partition replica之前在ack列表中，此时重启后，需要把这个partition replica再手动加到ack列表中。（ack列表是手动添加的，出现某个部工作的partition replica的时候自动从ack列表中移除的）

-Partition leader与follower：partition也有leader和follower之分。leader是主partition，producer写kafka的时候先写partition leader，再由partition leader push给其他的partition follower。partition leader与follower的信息受Zookeeper控制，一旦partition leader所在的broker节点宕机，zookeeper会冲其他的broker的partition follower上选择follower变为parition leader。

-Topic分配partition和partition replica的算法：（1）将Broker（size=n）和待分配的Partition排序。（2）将第i个Partition分配到第（i%n）个Broker上。（3）将第i个Partition的第j个Replica分配到第（(i + j) % n）个Broker上



-message状态：在Kafka中，消息的状态被保存在consumer中，broker不会关心哪个消息被消费了被谁消费了，只记录一个offset值（指向partition中下一个要被消费的消息位置），这就意味着如果consumer处理不好的话，broker上的一个消息可能会被消费多次。

-message持久化：Kafka中会把消息持久化到本地文件系统中，并且保持o(1)极高的效率。我们众所周知IO读取是非常耗资源的性能也是最慢的，这就是为了数据库的瓶颈经常在IO上，需要换SSD硬盘的原因。但是Kafka作为吞吐量极高的MQ，却可以非常高效的message持久化到文件。这是因为Kafka是顺序写入o（1）的时间复杂度，速度非常快。也是高吞吐量的原因。由于message的写入持久化是顺序写入的，因此message在被消费的时候也是按顺序被消费的，保证partition的message是顺序消费的。一般的机器,单机每秒100k条数据。

-message有效期：Kafka会长久保留其中的消息，以便consumer可以多次消费，当然其中很多细节是可配置的。



partiton中segment文件存储结构

producer发message到某个topic，message会被均匀的分布到多个partition上（随机或根据用户指定的回调函数进行分布），kafka broker收到message往对应partition的最后一个segment上添加该消息，当某个segment上的消息条数达到配置值或消息发布时间超过阈值时，segment上的消息会被flush到磁盘，只有flush到磁盘上的消息consumer才能消费，segment达到一定的大小后将不会再往该segment写数据，broker会创建新的segment。

每个part在内存中对应一个index，记录每个segment中的第一条消息偏移。

segment file组成：由2大部分组成，分别为index file和data file，此2个文件一一对应，成对出现，后缀".index"和“.log”分别表示为segment索引文件、数据文件.

segment文件命名规则：partion全局的第一个segment从0开始，后续每个segment文件名为上一个全局partion的最大offset(偏移message数)。数值最大为64位long大小，19位数字字符长度，没有数字用0填充。

每个segment中存储很多条消息，消息id由其逻辑位置决定，即从消息id可直接定位到消息的存储位置，避免id到位置的额外映射。



Partition Replication原则

Kafka高效文件存储设计特点

Kafka把topic中一个parition大文件分成多个小文件段，通过多个小文件段，就容易定期清除或删除已经消费完文件，减少磁盘占用。

通过索引信息可以快速定位message和确定response的最大大小。

通过index元数据全部映射到memory，可以避免segment file的IO磁盘操作。

通过索引文件稀疏存储，可以大幅降低index文件元数据占用空间大小。


Kafka集群partition replication默认自动分配分析

下面以一个Kafka集群中4个Broker举例，创建1个topic包含4个Partition，2 Replication；数据Producer流动如图所示：

![2](/images/rubin.webp)

当集群中新增2节点，Partition增加到6个时分布情况如下：

![2](/images/rubin2.webp)

副本分配逻辑规则如下：

在Kafka集群中，每个Broker都有均等分配Partition的Leader机会。

上述图Broker Partition中，箭头指向为副本，以Partition-0为例:broker1中parition-0为Leader，Broker2中Partition-0为副本。

上述图种每个Broker(按照BrokerId有序)依次分配主Partition,下一个Broker为副本，如此循环迭代分配，多副本都遵循此规则。

副本分配算法如下：

将所有N Broker和待分配的i个Partition排序.

将第i个Partition分配到第(i mod n)个Broker上.

将第i个Partition的第j个副本分配到第((i + j) mod n)个Broker上.




### 消息的生产及发送

负载均衡

kafka集群中的任何一个broker,都可以向producer提供metadata信息,这些metadata中包含"集群中存活的servers列表"/"partitions leader列表"等信息(请参看zookeeper中的节点信息). 当producer获取到metadata信息之后, producer将会和Topic下所有partition leader保持socket连接;消息由producer直接通过socket发送到broker,中间不会经过任何"路由层".



Producer发送消息的配置

3.5.1 同步模式

kafka有同步(sync)、异步(async)以及oneway这三种发送方式，某些概念上区分也可以分为同步和异步两种，同步和异步的发送方式通过producer.type参数指定，而oneway由request.require.acks参数指定。

producer.type的默认值是sync，即同步的方式。这个参数指定了在后台线程中消息的发送方式是同步的还是异步的。如果设置成异步的模式，可以运行生产者以batch的形式push数据，这样会极大的提高broker的性能，但是这样会增加丢失数据的风险。

3.5.2 异步模式

对于异步模式，还有4个配套的参数，如下：


![异步模式](/images/producer-async.webp)



3.5.3 oneway

oneway是只顾消息发出去而不管死活，消息可靠性最低，但是低延迟、高吞吐，这种对于某些完全对可靠性没有要求的场景还是适用的，即request.required.acks设置为0。

3.5.4 消息可靠性级别

当Producer向Leader发送数据时，可以通过request.required.acks参数设置数据可靠性的级别：

• 0: 不论写入是否成功，server不需要给Producer发送Response，如果发生异常，server会终止连接，触发Producer更新meta数据;

• 1: Leader写入成功后即发送Response，此种情况如果Leader fail，会丢失数据

• -1: 等待所有ISR接收到消息后再给Producer发送Response，这是最强保证

仅设置acks=-1也不能保证数据不丢失，当Isr列表中只有Leader时，同样有可能造成数据丢失。要保证数据不丢除了设置acks=-1， 还要保 证ISR的大小大于等于2，具体参数设置:

• (1)request.required.acks: 设置为-1 等待所有ISR列表中的Replica接收到消息后采算写成功;

• (2)min.insync.replicas: 设置为大于等于2，保证ISR中至少有两个Replica

Producer要在吞吐率和数据可靠性之间做一个权衡。

Produer :Producer向Topic发送message，不需要指定partition，直接发送就好了。kafka通过partition ack来控制是否发送成功并把信息返回给producer，producer可以有任意多的thread，这些kafka服务器端是不care的。Producer端的delivery guarantee默认是At least once的。也可以设置Producer异步发送实现At most once。Producer可以用主键幂等性实现Exactly once



### 消息的消费


消息处理模型历来有两种：

队列模型：一组消费者可以从服务器读取记录，每个记录都会被其中一个消费者处理，为保障消息的顺序，同一时刻只能有一个进程进行消费。

发布-订阅模型：记录被广播到所有的消费者。

Kafka的消费群的推广了这两个概念。消费群可以像队列一样让消息被一组进程处理(消费群的成员)，与发布 – 订阅模式一样，Kafka可以让你发送广播消息到多个消费群。

Kafka兼顾了消息的有序性和并发处理能力。传统的消息队列的消息在队列中是有序的，多个消费者从队列中消费消息，服务器按照存储的顺序派发消息。然而，尽管服务器是按照顺序派发消息，但是这些消息记录被异步传递给消费者，消费者接收到的消息也许已经是乱序的了。这实际上意味着消息的排序在并行消费中都将丢失。消息系统通常靠 “排他性消费”( exclusive consumer)来解决这个问题，只允许一个进程从队列中消费，当然，这意味着没有并行处理的能力。

Kafka做的更好。通过一个概念：并行性-分区-主题实现主题内的并行处理，Kafka是能够通过一组消费者的进程同时提供排序保证和并行处理以及负载均衡的能力：

(1)排序保障

每个主题的分区指定给每个消费群中的一个消费者，使每个分区只由该组中的一个消费者所消费。通过这样做，我们确保消费者是一个分区唯一的读者，从而顺序的消费数据。

(2)并行处理

因为有许多的分区，所以负载还能够均衡的分配到很多的消费者实例上去。但是请注意，一个消费群的消费者实例不能比分区数量多，因为分区数代表了一个主题的最大并发数，消费者的数量高于这个数量意义不大。





push/pull 模型

对于消费者而言有两种方式从消息中间件获取消息：

- ①Push方式：由消息中间件主动地将消息推送给消费者，采用Push方式，可以尽可能快地将消息发送给消费者;

- ②Pull方式：由消费者主动向消息中间件拉取消息，会增加消息的延迟，即消息到达消费者的时间有点长

> 但是，Push方式会有一个坏处：如果消费者的处理消息的能力很弱(一条消息需要很长的时间处理)，而消息中间件不断地向消费者Push消息，消费者的缓冲区可能会溢出。



Kafka只有Pull消费方式

Kafka使用PULL模型，PULL可以由消费者自己控制，但是PULL模型可能造成消费者在没有消息的情况下盲等，这种情况下可以通过long polling机制缓解，而对于几乎每时每刻都有消息传递的流式系统，这种影响可以忽略。Kafka 的 consumer 是以pull的形式获取消息数据的。 pruducer push消息到kafka cluster ，consumer从集群中pull消息。



### 消息的其他

消息的顺序消费问题

在说到消息中间件的时候，我们通常都会谈到一个特性：消息的顺序消费问题。这个问题看起来很简单：Producer发送消息1, 2, 3;Consumer按1, 2, 3顺序消费。但实际情况却是：无论RocketMQ，还是Kafka，缺省都不保证消息的严格有序消费!困难如下：

(1)Producer

发送端不能异步发送，异步发送在发送失败的情况下，就没办法保证消息顺序。比如你连续发了1，2，3。 过了一会，返回结果1失败，2, 3成功。你把1再重新发送1遍，这个时候顺序就乱掉了。

(2)存储端

对于存储端，要保证消息顺序，会有以下几个问题：

消息不能分区。也就是1个topic，只能有1个队列。在Kafka中，它叫做partition;在RocketMQ中，它叫做queue。 如果你有多个队列，那同1个topic的消息，会分散到多个分区里面，自然不能保证顺序。

即使只有1个队列的情况下，会有第2个问题。该机器挂了之后，能否切换到其他机器?也就是高可用问题。比如你当前的机器挂了，上面还有消息没有消费完。此时切换到其他机器，可用性保证了。但消息顺序就乱掉了。要想保证，一方面要同步复制，不能异步复制;另1方面得保证，切机器之前，挂掉的机器上面，所有消息必须消费完了，不能有残留。很明显，这个很难。

(3)接收端

对于接收端，不能并行消费，也即不能开多线程或者多个客户端消费同1个队列。

作者：丨程序之道丨
链接：https://www.jianshu.com/p/bde902c57e80
来源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。




