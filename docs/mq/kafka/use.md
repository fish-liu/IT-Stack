
参考：[Kafka集群配置](https://honeypps.com/mq/kafka-cluster-config/)

### Kafka集群配置

假设集群中有三台机器, ip地址分别为： xx.101.139.1, xx.101.139.2, xx.101.139.3.

zookeeper集群： xx.101.139.1:2181, xx.101.139.2:2181, xx.101.139.3:2181.

kafka broker集群: xx.101.139.1:9092, xx.101.139.2:9092, xx.101.139.3:9092.



### 配置zookeeper集群

- 修改zookeeper的配置文件，在$ZOOKEEPER_HOME/conf/下的zoo.cfg.（每台机器都需要添加）

在文件末尾添加：

```
server.0=xx.101.139.1:2888:3888
server.1=xx.101.139.2:2888:3888
server.2=xx.101.139.3:2888:3888
```

这里简单说明一下：server.A=B：C：D

A是一个数字,表示这个是第几号服务器,B是这个服务器的ip地址

C第一个端口用来集群成员的信息交换,表示的是这个服务器与集群中的Leader服务器交换信息的端口

D是在leader挂掉时专门用来进行选举leader所用


- 创建server id标识

在zoo.cfg下同时还需要配置(单机版时就已经设定，在配置集群时就可不必在设置)

```
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/tmp/zookeeper/data
dataLogDir/tmp/zookeeper/log
clientPort=2181
```

在上面可以看到有个dataDir的配置，在配置集群时需要在dataDir配置的/tmp/zookeeper/data下创建一个名称为”myid”的文件，文件里填上serverid号。

```
vim /tmp/zookeeper/data/myid
之后在其中输入0 （根据上一步的配置，xx.101.139.1配置为0，xx.101.139.2配置为1，依次类推对应起来）
输入：wq保存退出
```

- 启动各个节点的zookeeper: bin/zkServer.sh start

- 通过bin/zkServer.sh status查看各个节点的状态。

```
JMX enabled by default
Using config: /root/util/zookeeper-3.4.6/bin/../conf/zoo.cfg
Mode: follower (或Leader)
```


### 配置kafka集群


- 需要修改$KAFKA_HOME/config下的server.properties文件

修改broker.id的值，比如xx.101.139.1设置为0，xx.101.139.2设置为1，依次类推。(每台kafka broker server必须唯一)

最好将host.name设置为本机的ip地址而不是默认的localhost.

修改zookeeper.connect为zookeeper集群的ip，本例中可以这样设置：

zookeeper.connect=xx.101.139.1:2181,xx.101.139.2:2181,xx.101.139.3:2181

- 在每台机器上启动kafka

bin/kafka-server-start.sh config/server.properties

