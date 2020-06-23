
<h2>RabbitMQ的架构设计与核心组件</h2>
文章参考：https://blog.csdn.net/u010013573/article/details/90761429 及 https://blog.csdn.net/n950814abc/article/details/98219335

----------------------------------------


### 一、概念

- RabbitMQ是基于erlang语言开发的一个消息队列系统，是对AMQP协议的实现，其中AMQP的全称为Advanced Message Queuing Protocol，即高级消息队列协议，该协议主要用于制定基于队列进行消息传递的一个开放标准。

- AMQP的核心概念包括：虚拟主机vhost，连接Connection，信道Channel，数据交换器Exchanger，队列Queue，交换器与队列之间的绑定Binding，统一负责消息接收和分发的服务端Broker。由于RabbitMQ是基于AMQP协议实现的，故在RabbitMQ的实现当中也是围绕对这些概念进行内部功能组件的设计，并将这些组件整合起来提供一个完整的消息队列服务。

- 在应用方面，RabbitMQ起源于金融系统，主要用于分布式系统的内部各子系统之间的数据存储转发，这是系统解耦方面的一种运用。

  - 即如果是单体应用则通常可以使用内存队列，如Java的BlockingQueue即可，而将单体应用拆分为分布式系统之后，则通过RabbitMQ这种进程队列来在各子系统之间进行消息传递，从而达到解耦的作用。
  - 除此之外，RabbitMQ还可以运用在高并发系统当中的流量削峰，即将请求流量数据临时存放到RabbitMQ当中，从而避免大量的请求流量直接达到后台服务，把后台服务冲垮。通过使用RabbitMQ来存放这些请求流量，后台服务从RabbitMQ中消费数据，从而达到流量削峰的目的。
  - 除了系统解耦和流量削峰外，RabbitMQ还常用于消息通讯，即可以用于实现IM聊天系统。

### 二、AMQP协议：高级消息队列协议

由以上分析可知，RabbitMQ是基于AMQP协议实现的一个消息队列中间件，主要用于分布式系统当中不同系统之间的消息传递。所以在核心设计层面也是围绕AMQP协议来展开的。

RabbitMQ的核心架构示意图：（图片引自《RabbitMQ实战指南》）

![RabbitMQ的核心架构示意图](/images/cluster-1.png)

![RabbitMQ的核心架构示意图](/images/cluster-2.png)

### 三、 核心组件

#### 1、Connection连接与Channel信道

- 在高并发系统设计当中，需要尽量减少服务器的连接数，因为每个连接都需要占用服务器的一个文件句柄，而服务器的文件句柄数量是有限的，具体可以通过ulimit命令查看。

- 在Rabbit中，无论是生产者还是消费者都可以看做客户端，都需要和RabbitMQ Broker 建立连接，这个连接就是一条TCP 连接，也就是Connection 。

- 为了减少连接的数量，AMQP 协议抽象了信道 Channel 的概念，一个客户端与 RabbitMQ 服务器建立一个 TCP 连接，在客户端可以使用多个Channel，每个信道都会被指派一个唯一的ID。这多个 Channel 共用这条TCP连接来进行与服务端之间的数据传输；信道是建立在Connection 之上的虚拟连接， RabbitMQ 处理的每条AMQP 指令都是通过信道完成的。

![connection](/images/connection.png)

**1. 数据安全性**

Channel是建立在这个TCP连接之上的虚拟连接，就相当于每个channel都是一个独立的TCP连接一样。而在数据安全性方面，Rabbitmq的设计是每个不同Channel实例都对应一个唯一的ID，故这个真实的TCP连接发送和接收到数据时，则可以根据这个唯一的ID来确定这个数据属于哪个channel。

**2. Channel与线程的映射**

Channel与线程一一对应：使用Channel的场景通常为在客户端每个线程使用一个独立的Channel实例来进行数据传输，这样就实现了不同线程之间的隔离。不过由于所有线程都共用一个TCP连接进行数据传输，如果传输的数据量小则问题不大，如果需要进行大数据量传输，则该TCP连接的带宽就会成为性能瓶颈，所以此时需要考虑使用多个TCP连接。


**我们完全可以直接使用Connection 就能完成信道的工作，为什么还要引入信道呢?**

一个应用程序中有很多个线程需要从RabbitMQ 中消费消息，或者生产消息，那么必然需要建立很多个Connection ，也就是许多个TCP 连接。然而对于操作系统而言，建立和销毁TCP 连接是非常昂贵的开销，如果遇到使用高峰，性能瓶颈也随之显现。RabbitMQ 采用类似NIO' (Non-blocking 1/0) 的做法，选择TCP 连接复用，不仅可以减少性能开销，同时也便于管理。

每个线程把持一个信道，所以信道复用了Connection 的TCP 连接。同时RabbitMQ 可以确保每个线程的私密性，就像拥有独立的连接一样。当每个信道的流量不是很大时，复用单一的Connection 可以在产生性能瓶颈的情况下有效地节省TCP 连接资源。但是当信道本身的流量很大时，这时候多个信道复用一个Connection 就会产生性能瓶颈，进而使整体的流量被限制了。此时就需要开辟多个Connection ，将这些信道均摊到这些Connection 中， 至于这些相关的调优策略需要根据业务自身的实际情况进行调节。

信道在AMQP 中是一个很重要的概念，大多数操作都是在信道这个层面展开的。在代码清单中也可以看出一些端倪，

比如channel.exchangeDeclare 、channel .queueDeclare 、channel.basicPublish 和channel.basicConsume 等方法。

RabbitMQ 相关的API 与AMQP紧密相连，比如channel.basicPublish 对应AMQP 的Basic.Publish 命令.


#### 2、Broker（服务节点）

Broker：简单来说就是消息队列服务器实体。中文意思：中间件。接受客户端连接，实现AMQP消息队列和路由功能的进程。一个broker里可以开设多个vhost，用作不同用户的权限分离。

![Broker](/images/broker.png)

#### 3、虚拟主机vhost

vhost：虚拟主机,一个broker里可以有多个vhost，用作不同用户的权限分离。

**业务隔离**

- 主要用于实现不同业务系统之间的消息队列的隔离，即可以部署一个RabbitMQ服务端，但是可以设置多个虚拟主机给多个不同的业务系统使用，这些虚拟主机对应的消息队列内部的数据是相互隔离的。所以多个虚拟主机也类似于同一套房子里面的多个租户，每个租户都自己做饭吃饭，而不会去其他租户家里做饭吃饭。

- 虚拟主机的概念相当于Java应用程序的命名空间namespace，不同虚拟主机内部可以包含相同名字的队列。

- RabbitMQ服务器默认包含一个虚拟主机，即“/”，如果需要创建其他的虚拟主机，可以在RabbitMQ控制台执行如下命令：通过rabbitmqctl add_vhost命令添加一个新的“test_host”虚拟主机。

```linux
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl list_vhosts
Listing vhosts
/
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl add_vhost test_host
Creating vhost "test_host"
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl list_vhosts
Listing vhosts
/
test_host
```

**用户与权限：以虚拟主机为单位进行权限分配**

- 一个RabbitMQ服务端可以包含多个虚拟主机，而这多个虚拟主机通常是对应多个不同的业务。所以为了保证不同业务不相互影响，则RabbitMQ中定义了用户和权限的概念。

- 在RabbitMQ中，权限控制是以虚拟主机vhost为单位的，即当创建一个用户时，该用户需要被授予对一个或者多个虚拟主机进行操作的权限，而操作的对象主要包括交换器，队列和绑定关系等，如添加，删除交换器、队列等操作。

- 创建用户和设置权限的相关命令主要在rabbitmqctl定义，RabbitMQ默认包含一个guest用户，密码也是guest，该用户的角色为管理员：

```linux
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl list_users
Listing users
guest	[administrator]
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl list_permissions -p /
Listing permissions in vhost "/"
guest	.*	.*	.*
xyzdeMacBook-Pro:plugins xyz$ rabbitmqctl list_permissions -p test_host
Listing permissions in vhost "test_host"
```


#### 4、Exchanger交换器

在RabbitMQ的设计当中，交换器主要用于分析生产者传递过来的消息，根据消息的路由信息，即路由键route key，和自身维护的和队列Queue的绑定信息来将将消息放到对应的队列中，或者如果没有匹配的队列，则丢弃该消息或者扔回给生产者。

![Broker](/images/exchange.png)

**交换机状态**

交换机有两种状态 ： 持久（durable）、暂存（transient）

持久化的交换机会在消息代理（broker）重启后依旧存在，而暂存的交换机则不会（它们需要在代理再次上线后重新被声明）。

并不是所有的应用场景都需要持久化的交换机。


**交换器类型**

在RabbitMQ的交换器设计当中，交换器主要包含四种类型，分别为fanout，direct，topic和headers。

- a. fanout：广播

  相当于广播类型，忽略生产者传递过来的消息的路由信息，将所有消息都广播到所有与这个交换器绑定的队列中。

- b. direct：精确匹配
  
  完全匹配，根据消息的路由键route key去完全匹配该交换器与队列的绑定键binding key，如果存在完全匹配的，则将该消息投递到该队列中；

- c. topic：模糊匹配

  模糊匹配或者正则匹配，交换器与队列之间使用正则表达式类型的绑定键，具体规则如下：
  - 1. 绑定键binding key和消息的路由键route key都是使用点号“.”分隔的字符串，如trade.alibaba.com为路由键，.alibaba.com为绑定键；
  - 2. 在绑定键中，可以包含星号“*”和井号“#”，其中井号 “ # ”表示匹配0个或者多个单词，星号“ * ”表示匹配一个单词。

  所以topic相对于direct能够匹配更多的消息，即topic类型的交换器可以成功投递更多的消息到其绑定的队列中。

- d. headers：消息头匹配

  headers类型不是基于消息的路由键来进行匹配的，而是基于消息的headers属性的键值对的，即首先交换器和队列之间基于一个键值对来建立绑定映射关系，当交换器接收到消息时，分析该消息headers属性的键值对是否与这个建立交换器和队列绑定关系的键值对完全匹配，是则投递到该队列。由于这种方式性能较低，故基本不会使用。


#### 5、Queue数据存储队列

用于存储消息

![Broker](/images/queue.png)

- 在RabbitMQ的设计当中，队列Queue是进行数据存放的地方，即交换器Exchanger其实只是一个映射关系而已，不会实际占用RabbitMQ服务器的资源。

- 队列Queue由于在消费者消费消息之前，需要临时存放生产者传递过来的消息，故需要占用服务器的内存和磁盘资源。

- 默认情况下，RabbitMQ的数据是存放在内存中的，当消费者消费队列的数据并发回了ACK确认时，RabbitMQ服务器才会将内存中的数据，即队列Queue中的数据，标记为删除，并在之后某个时刻进行实际删除。

- 不过RabbitMQ也会使用磁盘来存放消息：

  - 第一种场景是内存不够用时，RabbitMQ服务器会将内存中的数据临时换出到磁盘中存放，之后当内存充足或者消费者需要消费时，再换回内存；
  - 第二种场景是队列Queue和生产者发送过来的消息都是持久化类型的，其中队列Queue持久化需要在创建该队列时指定，而消息的持久化为通过设置消息的deliveryMode属性为2来提示RabbitMQ服务器持久化这条消息到磁盘。

**队列创建**

队列在声明（declare）后才能被使用。

如果一个队列尚不存在，声明一个队列会创建它。

如果声明的队列已经存在，并且属性完全相同，那么此次声明不会对原有队列产生任何影响。

如果声明中的属性与已存在队列的属性有差异，那么一个错误代码为 406 的通道级异常就会被抛出。

**队列持久化**

持久化队列（Durable queues）会被存储在磁盘上，当消息代理（broker）重启的时候，它依旧存在。没有被持久化的队列称作暂存队列（Transient queues）。并不是所有的场景和案例都需要将队列持久化。

持久化的队列并不会使得路由到它的消息也具有持久性。倘若消息代理挂掉了，重新启动，那么在重启的过程中持久化队列会被重新声明，无论怎样，只有经过持久化的消息才能被重新恢复。


> 如果RabbitMQ服务器是采用集群部署，如果没有开启镜像队列，则消息也是只存放在一个队列中的，这种情况下集群的目的主要是在不同的机器节点部署不同的队列Queue，从而来解决单机性能瓶颈，而不是解决数据的高可靠性。如果开启了镜像队列，则是基于Master-Slave的模式，将队列的数据复制到集群其他节点的队列中存放，从而实现数据高可用和高可靠。


#### 6、BindingKey：绑定

RabbitMQ通过绑定将交换器与队列关联起来，在绑定的时候一般会指定一个绑定键（BindingKey），这样RabbitMQ就知道如何正确的将消息路由到队列了。

![Broker](/images/bindingkey.png)

<!--
#### 7、RoutingKey：路由键

生产者将消息发送给交换器的时候，一般会指定一个RoutingKey，用来指定消息的路由规则，而这个RoutingKey需要与交换器类型和绑定键（BindingKey）联合使用才能最终生效。

在交换器类型和绑定键(BindingKey）固定的情况下，生产者可以发送消息给交换器时，通过指定RoutingKey来决定消息流向哪里。
-->

#### 7、生产者

生产者主要负责投递消息到RabbitMQ服务器broker，具体为首先建立与broker的一个TCP连接，然后创建一个或者多个虚拟连接channel，每个channel就是一个生产者，在channel指定需要投递的交换器，消息的路由键和消息内容，最后调用publish方法发布到这个交换器。

消息包含2部分：消息体（payload）和 标签(Label)

- 消息体：一般是一个带有业务逻辑结构的数据，比如一个JSON字符串。

- 标签：用来描述这条消息，比如一个交换器的名称和一个路由键。

**路由键route key**

- 生产者需要指定消息的路由键route key，路由键通常与broker的交换器和队列之间的绑定键binding key对应，然后结合交换器的类型，路由键和绑定键来决定投递给哪个队列，或者如果没有可以投递的队列，则丢失消息或者返回消息给生产者。

**消息确认机制：可靠性**

- 消息确认机制主要用于保证生产者投递的消息成功到达RabbitMQ服务器，具体为成功到达RabbitMQ服务器的交换器，如果此交换器没有匹配的队列，则也会丢失该消息。

- 如果要保证数据成功到达队列，则可以结合Java API的mandatory参数，即没有匹配的队列可投递，则返回该消息给生产者，有生产者设置回调来处理；或者转发给备份队列来处理。


#### 8、消费者

- 消费者用于消费队列中的数据，与生产者类似，消费者也是作为RabbitMQ服务器的一个客户端，即需要首先建立一个TCP连接，然后建立channel作为消费者，从而实现不同channel对应不同队列消费者。

- 在数据消费层面，RabbitMQ服务器会将同一个队列数据以轮询的负载均衡方式分发给消费这个队列的多个消费者，每个消息默认只会给到其中一个消费者，从而实现负载均衡和高可用，以及可拓展性，即如果一个队列有太多消息时，我们可以创建多个消费者（通常为每个消费者对应一个线程）来处理这个队列的消息。

**推模式和拉模式**

- 消费者消费队列中的数据可以基于推、拉两种模式，其中推模式为RabbitMQ服务器当对应的队列有数据时，主动推送给消费者channel；而拉模式是消费者channel主动发起获取数据请求，每发起一次则获取一次数据，不发起则不会获取数据。如果在一个while死循环中轮询，则相当于拉模式，不过这种方式很耗费资源，通常使用推模式代替。

**消息确认ACK与队列的消息删除**

- 在RabbitMQ的设计当中，RabbitMQ服务器是不会主动删除队列中的消息的，而是需要等到消费这条消息的消费者发送ACK确认时才会将队列的这条消息删除。注意，RabbitMQ服务器在等待消费者的ACK确认过程中，是没有超时的概念的，如果该消费者连接还存在且没有回传ACK，则这条消息一直保留在该队列中。如果该消费者连接断了且没有回传ACK，则RabbitMQ服务器将该消费发送给另外一个消费者。

- 消费者确认在使用Java API时，可以使用**自动确认**和**手动确认**，其中自动确认会存在消费者还没处理就崩溃的情况，此时出现数据丢失，是“至多一次”的场景；如果手动提交，存在处理完还没提交ACK，则消费者崩溃，此时RabbitMQ会重复投递给其他消费者，故是“至少一次”的场景，存在消费重复。

- 所以RabbitMQ在数据重复性和数据丢失方面，提供的是“至少一次”和“至多一次”的保证，不提供“恰好一次”的保证。即会存在重复消息和丢失消息。

>自动确认模式：当消息代理（broker）将消息发送给应用后立即删除。（使用 AMQP 方法：basic.deliver 或 basic.get-ok）)
> 
>显式确认模式：待应用（application）发送一个确认回执（acknowledgement）后再删除消息。（使用 AMQP 方法：basic.ack）

**3. 消息拒绝与重入队**

- 当消费者接收到RabbitMQ服务器发送过来的消息时，可以选择拒绝这条消息。消费者拒绝的时候，可以告诉RabbitMQ服务器是否将该消息重新入队，如果是，则RabbitMQ服务器会将该消息重新投递给其他消费者，否则丢弃这条消息。

参考：[RabbitMQ官方文档](https://www.rabbitmq.com/admin-guide.html)


### 四、RabbitMQ运转流程

#### 生产者发送消息的时候

(1) 生产者连接到RabbitMQ Broker ， 建立一个连接( Connection) ，开启一个信道(Channel)

(2) 生产者声明一个交换器，并设置相关属性，比如交换机类型、是否持久化等

(3) 生产者声明一个队列井设置相关属性，比如是否排他、是否持久化、是否自动删除等

( 4 ) 生产者通过路由键将交换器和队列绑定起来

( 5 ) 生产者发送消息至RabbitMQ Broker，其中包含路由键、交换器等信息

(6) 相应的交换器根据接收到的路由键查找相匹配的队列。

( 7 ) 如果找到，则将从生产者发送过来的消息存入相应的队列中。

(8) 如果没有找到，则根据生产者配置的属性选择丢弃还是回退给生产者

(9) 关闭信道。

(1 0) 关闭连接。

#### 消费者接收消息的过程:

(1)消费者连接到RabbitMQ Broker ，建立一个连接(Connection ) ，开启一个信道(Channel) 。

(2) 消费者向RabbitMQ Broker 请求消费相应队列中的消息，可能会设置相应的回调函数，
以及做一些准备工作

(3)等待RabbitMQ Broker 回应并投递相应队列中的消息， 消费者接收消息。

(4) 消费者确认( ack) 接收到的消息。

( 5) RabbitMQ 从队列中删除相应己经被确认的消息。

( 6) 关闭信道。

( 7) 关闭连接


### 五、消息机制

#### 消息属性

AMQP 模型中的消息（Message）对象是带有属性（Attributes）的。有些属性及其常见，以至于 AMQP 0-9-1 明确的定义了它们，并且应用开发者们无需费心思思考这些属性名字所代表的具体含义。例如：

- Content type（内容类型）

- Content encoding（内容编码）

- Routing key（路由键）

- Delivery mode (persistent or not)

- 投递模式（持久化 或 非持久化）

- Message priority（消息优先权）

- Message publishing timestamp（消息发布的时间戳）

- Expiration period（消息有效期）

- Publisher application id（发布应用的 ID）

有些属性是被 AMQP 代理所使用的，但是大多数是开放给接收它们的应用解释器用的。有些属性是可选的也被称作消息头（headers）。他们跟 HTTP 协议的 X-Headers 很相似。消息属性需要在消息被发布的时候定义。

#### 消息主体

AMQP 的消息除属性外，也含有一个有效载荷 - Payload（消息实际携带的数据），它被 AMQP 代理当作不透明的字节数组来对待。

消息代理不会检查或者修改有效载荷。消息可以只包含属性而不携带有效载荷。它通常会使用类似 JSON 这种序列化的格式数据，为了节省，协议缓冲器和 MessagePack 将结构化数据序列化，以便以消息的有效载荷的形式发布。AMQP 及其同行者们通常使用 “content-type” 和 “content-encoding” 这两个字段来与消息沟通进行有效载荷的辨识工作，但这仅仅是基于约定而已。

#### 消息持久化

消息能够以持久化的方式发布，AMQP 代理会将此消息存储在磁盘上。如果服务器重启，系统会确认收到的持久化消息未丢失。

简单地将消息发送给一个持久化的交换机或者路由给一个持久化的队列，并不会使得此消息具有持久化性质：它完全取决与消息本身的持久模式（persistence mode）。将消息以持久化方式发布时，会对性能造成一定的影响（就像数据库操作一样，健壮性的存在必定造成一些性能牺牲）。





