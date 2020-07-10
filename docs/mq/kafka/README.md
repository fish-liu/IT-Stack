

<h2>Kafka</h2>


Kafka是最初由Linkedin公司开发，是一个分布式、支持分区的（partition）、多副本的（replica），基于zookeeper协调的分布式消息系统，它的最大的特性就是可以实时的处理大量数据以满足各种需求场景：比如基于hadoop的批处理系统、低延迟的实时系统、storm/Spark流式处理引擎，web/nginx日志、访问日志，消息服务等等，用scala语言编写，Linkedin于2010年贡献给了Apache基金会并成为顶级开源 项目。

从 0.9 版本开始，Kafka 的标语已经从“一个**高吞吐量**，分布式的消息系统”改为"一个分布式流平台"。

> Kafka是一个具有高吞吐量，高拓展性，高性能和高可靠的基于发布订阅模式的消息队列.

#### 1.1  Kafka的特性:

- 高吞吐量、低延迟：kafka每秒可以处理几十万条消息，它的延迟最低只有几毫秒，每个topic可以分多个partition, consumer group 对partition进行consume操作。

- 可扩展性：kafka集群支持热扩展

- 持久性、可靠性：消息被持久化到本地磁盘，并且支持数据备份防止数据丢失

- 容错性：允许集群中节点失败（若副本数量为n,则允许n-1个节点失败）

- 高并发：支持数千个客户端同时读写

- 它支持多订阅者，当失败时能自动平衡消费者。


#### 1.2   Kafka的使用场景：

- 日志收集：一个公司可以用Kafka可以收集各种服务的log，通过kafka以统一接口服务的方式开放给各种consumer，例如hadoop、Hbase、Solr等。

- 消息系统：解耦和生产者和消费者、缓存消息等。

- 用户活动跟踪：Kafka经常被用来记录web用户或者app用户的各种活动，如浏览网页、搜索、点击等活动，这些活动信息被各个服务器发布到kafka的topic中，然后订阅者通过订阅这些topic来做实时的监控分析，或者装载到hadoop、数据仓库中做离线分析和挖掘。

- 运营指标：Kafka也经常用来记录运营监控数据。包括收集各种分布式应用的数据，生产各种操作的集中反馈，比如报警和报告。

- 流式处理：比如spark streaming和storm

- 事件源

-------------------------------



[Kafka如何保证高吞吐量](mq/kafka/throughput.md)



kafka 系列比较全的文章

https://www.cnblogs.com/jixp/category/1308441.html


kafka 的介绍

https://blog.csdn.net/u010013573/category_8899443.html



Kafka的架构原理，你真的理解吗？

https://www.jianshu.com/p/4bf007885116


Kafka史上最详细原理总结

http://blog.csdn.net/YChenFeng/article/details/74980531


全面解析kafka架构与原理

https://www.jianshu.com/p/bde902c57e80


Kafka架构和原理深度剖析 （2015年的版本，比较老，已看完）
https://www.cnblogs.com/feiyudemeng/p/9253983.html
