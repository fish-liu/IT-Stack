
生产者

发送方式 

参考文章：[Kafka之sync、async以及oneway](https://honeypps.com/mq/kafka-sync-async-oneway/)

生产者对消息的发送有三种方式：同步（sync）、异步（async）以及oneway

某些概念上区分也可以分为同步和异步两种，同步和异步的发送方式通过“producer.type”参数指定，而oneway由“request.require.acks”参数指定。





消息的发送包含的处理步骤



1、 拦截器处理

参考文章：[Kafka Producer拦截器](https://honeypps.com/mq/kafka-producer-interceptor/)



2、 序列化处理

参考文章：[Kafka消息序列化和反序列化上](https://honeypps.com/mq/kafka-message-serialize-and-deserialize-1/)

[Kafka消息序列化和反序列化下](https://honeypps.com/mq/kafka-message-serialize-and-deserialize-2/)



3、 计算分区

参考文章：[Kafka分区分配计算(分区器Partitions)](https://honeypps.com/mq/kafka-partitions-distributed-calculation/)

计算分区的方式：

- 如果key为null，则按照一种轮询的方式来计算分区分配

- 如果key不为null则使用称之为murmur的Hash算法（非加密型Hash函数，具备高运算性能及低碰撞率）来计算分区分配

- KafkaProducer中还支持自定义分区分配方式
与org.apache.kafka.clients.producer.internals.DefaultPartitioner一样首先实现org.apache.kafka.clients.producer.Partitioner接口，然后在KafkaProducer的配置中指定partitioner.class为对应的自定义分区器（Partitioners）即可






