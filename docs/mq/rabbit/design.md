
<h2>RabbitMQ的架构设计与核心组件</h2>
文章参考：https://blog.csdn.net/u010013573/article/details/90761429 及 https://blog.csdn.net/n950814abc/article/details/98219335

[RabbitMQ](https://www.jianshu.com/p/64357bf35808)

----------------------------------------


### 一、概念

RabbitMQ是基于erlang语言开发的一个消息队列系统，是对AMQP协议的实现，其中AMQP的全称为Advanced Message Queuing Protocol，即高级消息队列协议，该协议主要用于制定基于队列进行消息传递的一个开放标准。

Erlang是一门动态类型的函数式编程语言，它也是一门解释型语言，由Erlang虚拟机解释执行。从语言模型上说，Erlang是基于Actor模型的实现。在Actor模型里面，万物皆Actor，每个Actor都封装着内部状态，Actor相互之间只能通过消息传递这一种方式来进行通信。对应到Erlang里，每个Actor对应着一个Erlang进程，进程之间通过消息传递进行通信。相比共享内存，进程间通过消息传递来通信带来的直接好处就是消除了直接的锁开销(不考虑Erlang虚拟机底层实现中的锁应用)。


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


RabbitMQ中间件分为服务端（RabbitMQ Server）和客户端（RabbitMQ Client），服务端可以理解为是一个消息的代理消费者，客户端又分为消息生产者（Producer）和消息消费者（Consumer）。

- 消息生产者（Producer）：主要生产消息并将消息基于TCP协议，通过建立Connection和Channel，将消息传输给RabbitMQ Server，对于Producer而言基本就完成了工作。

- 服务端（RabbitMQ Server）：主要负责处理消息路由、分发、入队列、缓存和出列。主要由三部分组成：Exchange、RoutingKey、Queue。

- 消息消费者（Consumer）：主要负责消费Queue的消息，同样基于TCP协议，通过建立Connection和Channel与Queue传输消息，一个消息可以给多个Consumer消费；



### 三、 核心组件介绍

#### 1、Connection连接与Channel信道

- 在高并发系统设计当中，需要尽量减少服务器的连接数，因为每个连接都需要占用服务器的一个文件句柄，而服务器的文件句柄数量是有限的，具体可以通过ulimit命令查看。

- 在Rabbit中，无论是生产者还是消费者都可以看做客户端，都需要和RabbitMQ Broker 建立连接，这个连接就是一条TCP 连接，也就是Connection 。

- 为了减少连接的数量，AMQP 协议抽象了信道 Channel 的概念，一个客户端与 RabbitMQ 服务器建立一个 TCP 连接，在客户端可以使用多个Channel，每个信道都会被指派一个唯一的ID。这多个 Channel 共用这条TCP连接来进行与服务端之间的数据传输；信道是建立在Connection 之上的虚拟连接， RabbitMQ 处理的每条AMQP 指令都是通过信道完成的。

![connection](/images/connection.png)

![RabbitMQ的核心架构示意图](/images/rabbit-001.webp)

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

![RabbitMQ的核心架构示意图](/images/rabbit-002.webp)

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

![Exchanger交换器](/images/exchange.png)

**交换机状态**

交换机有两种状态 ： 持久（durable）、暂存（transient）

持久化的交换机会在消息代理（broker）重启后依旧存在，而暂存的交换机则不会（它们需要在代理再次上线后重新被声明）。

并不是所有的应用场景都需要持久化的交换机。


**交换器类型**

在RabbitMQ的交换器设计当中，交换器主要包含四种类型，分别为fanout，direct，topic和headers。

- a. fanout：广播

  ![Exchanger交换器](/images/rabbit-004.webp)

  相当于广播类型，忽略生产者传递过来的消息的路由信息，将所有消息都广播到所有与这个交换器绑定的队列中。（消息从客户端发出，只要queue与exchange有绑定，那么他不管你的Routingkey是什么他都会将消息分发给所有与该exchang绑定的队列中。）

- b. direct：精确匹配
  
  ![Exchanger交换器](/images/rabbit-003.webp)
  
  完全匹配，根据消息的路由键route key去完全匹配该交换器与队列的绑定键binding key，如果存在完全匹配的，则将该消息投递到该队列中；

- c. topic：模糊匹配

  ![Exchanger交换器](/images/rabbit-005.webp)

  模糊匹配或者正则匹配，交换器与队列之间使用正则表达式类型的绑定键，具体规则如下：
  - 1. 绑定键binding key和消息的路由键route key都是使用点号“.”分隔的字符串，如trade.alibaba.com为路由键，.alibaba.com为绑定键；
  - 2. 在绑定键中，可以包含星号“*”和井号“#”，其中井号 “ # ”表示匹配0个或者多个单词，星号“ * ”表示匹配一个单词。
  
  > `*`，代表任意的一个词。例如topic.zlh.*，他能够匹配到，topic.zlh.one ,topic.zlh.two ,topic.zlh.abc, ....
  > 
  > `#`，代表任意多个词。例如topic.#，他能够匹配到，topic.zlh.one ,topic.zlh.two ,topic.zlh.abc, ....
  
  所以topic相对于direct能够匹配更多的消息，即topic类型的交换器可以成功投递更多的消息到其绑定的队列中。

- d. headers：消息头匹配

  headers类型不是基于消息的路由键来进行匹配的，而是基于消息的headers属性的键值对的，即首先交换器和队列之间基于一个键值对来建立绑定映射关系，当交换器接收到消息时，分析该消息headers属性的键值对是否与这个建立交换器和队列绑定关系的键值对完全匹配，是则投递到该队列。由于这种方式性能较低，故基本不会使用。


**声明Exchange**

在Rabbit MQ中，声明一个Exchange需要三个参数：ExchangeName，ExchangeType和Durable。

- ExchangeName是该Exchange的名字，该属性在创建Binding和生产者通过publish推送消息时需要指定。
- ExchangeType，指Exchange的类型，在RabbitMQ中，有三种类型的Exchange：direct ，fanout和topic，不同的Exchange会表现出不同路由行为。
- Durable是该Exchange的持久化属性


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

**声明Queue**

在Rabbit MQ中，声明一个Queue需要五个参数：QUEUE_NAME，Durable，Exclusive，Auto-delete和其他选项。

```
/**
 * 3. 声明（创建）队列
 * 参数1：队列名称
 * 参数2：是否定义持久化队列
 * 参数3：是否独占本次连接
 * 参数4：是否在不使用的时候自动删除队列
 * 参数5：队列其它参数
 */
channel.queueDeclare(QUEUE_NAME, true, false, false, null);
```

a) Durable:持久化

b) Exclusive：排他队列，如果一个队列被声明为排他队列，该队列仅对首次声明它的连接可见，并在连接断开时自动删除。这里需要注意三点：

其一，排他队列是基于连接（Connection）可见的，同一连接的不同信道是可以同时访问同一个连接创建的排他队列的。
其二，“首次”，如果一个连接已经声明了一个排他队列，其他连接是不允许建立同名的排他队列的，这个与普通队列不同。
其三，即使该队列是持久化的，一旦连接关闭或者客户端退出，该排他队列都会被自动删除的。这种队列适用于只限于一个客户端发送读取消息的应用场景。

c) Auto-delete:自动删除，如果该队列没有任何订阅的消费者的话，该队列会被自动删除。这种队列适用于临时队列。

d) 其他选项，例如如果用户仅仅想查询某一个队列是否已存在，如果不存在，不想建立该队列，仍然可以调用queue.declare，只不过需要将参数passive设为true，传给queue.declare，如果该队列已存在，则会返回true；如果不存在，则会返回Error，但是不会创建新的队列。


**临时队列**

首先，无论我们什么时候链接rabbit，我们需要一个新鲜的的，空的队列。为了达到这个目的，我们可能用一个随机的名字来创建一个队列，更好的情况下是让server为我们选择一个随机的队列。

其次，一旦我们不再链接消费者之后，队列应该立刻被删除。

在java的client中，我们使用无参数的queueDeclare()，我们创建一个不持久化的，单独的，自动删除的队列。
> String queueName = channel.queueDeclare().getQueue();


#### 6、BindingKey：绑定

RabbitMQ通过绑定将交换器与队列关联起来，在绑定的时候一般会指定一个绑定键（BindingKey），这样RabbitMQ就知道如何正确的将消息路由到队列了。

![Broker](/images/bindingkey.png)

> channel.queueBind("queueName1", "exchangeName", "routingKey1");    

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


**事务**

对事务的支持是AMQP协议的一个重要特性。假设当生产者将一个持久化消息发送给服务器时，因为consume命令本身没有任何Response返回，所以即使服务器崩溃，没有持久化该消息，生产者也无法获知该消息已经丢失。如果此时使用事务，即通过txSelect()开启一个事务，然后发送消息给服务器，然后通过txCommit()提交该事务，即可以保证，如果txCommit()提交了，则该消息一定会持久化，如果txCommit()还未提交即服务器崩溃，则该消息不会服务器就收。当然Rabbit MQ也提供了txRollback()命令用于回滚某一个事务。

**生产者消息投递可靠性-Confirm机制**

使用事务固然可以保证只有提交的事务，才会被服务器执行。但是这样同时也将客户端与消息服务器同步起来，这背离了消息队列解耦的本质。

Rabbit MQ提供了一个更加轻量级的机制来保证生产者可以感知服务器消息是否已被路由到正确的队列中——Confirm。

如果设置channel为confirm状态，则通过该channel发送的消息都会被分配一个唯一的ID，然后一旦该消息被正确的路由到匹配的队列中后，服务器会返回给生产者一个Confirm，该Confirm包含该消息的ID，这样生产者就会知道该消息已被正确分发。对于持久化消息，只有该消息被持久化后，才会返回Confirm。

Confirm机制的最大优点在于异步，生产者在发送消息以后，即可继续执行其他任务。而服务器返回Confirm后，会触发生产者的回调函数，生产者在回调函数中处理Confirm信息。如果消息服务器发生异常，导致该消息丢失，会返回给生产者一个nack，表示消息已经丢失，这样生产者就可以通过重发消息，保证消息不丢失。Confirm机制在性能上要比事务优越很多。但是Confirm机制，无法进行回滚，就是一旦服务器崩溃，生产者无法得到Confirm信息，生产者其实本身也不知道该消息吃否已经被持久化，只有继续重发来保证消息不丢失，但是如果原先已经持久化的消息，并不会被回滚，这样队列中就会存在两条相同的消息，系统需要支持去重。



#### 8、消费者

- 消费者用于消费队列中的数据，与生产者类似，消费者也是作为RabbitMQ服务器的一个客户端，即需要首先建立一个TCP连接，然后建立channel作为消费者，从而实现不同channel对应不同队列消费者。

- 在数据消费层面，RabbitMQ服务器会将同一个队列数据以轮询的负载均衡方式分发给消费这个队列的多个消费者，每个消息默认只会给到其中一个消费者，从而实现负载均衡和高可用，以及可拓展性，即如果一个队列有太多消息时，我们可以创建多个消费者（通常为每个消费者对应一个线程）来处理这个队列的消息。

> 使用basicQos方法来设置为1.这会告诉rabbitmq每次不要给消费者超过一个的消息。换句话说，在消费者处理并应答上条消息之前不要为其分发新的任务消息。这样，他就会分配给下一个不在忙碌的worker。
  

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


#### RabbitMQ的transaction、confirm、ack三个概念的解释

RabbitMQ是采用的AMQP协议，AMQP协议定义了”确认”（acknowledgement）,它是从consumer到RabbitMQ的确认，表示一条消息已经被客户端正确处理。RabbitMQ扩展了AMQP协议，定义了从broker到publisher的”确认”，但将其称之为confirm。所以RabbitMQ的确认有2种，叫不同的名字，一个consumer acknowledgement，一个叫publisher confirm。

> 如果采用标准的 AMQP 协议，则唯一能够保证消息不会丢失的方式是利用事务机制 -- 令 channel 处于 transactional 模式、向其 publish 消息、执行 commit 动作。在这种方式下，事务机制会带来大量的多余开销，并会导致吞吐量下降 250% 。为了补救事务带来的问题，引入了 confirmation 机制（即 Publisher Confirm）。

根据AMQP协议规定，consumer acknowledgemenet是通过basic.ack方法实现的，consumer在收到一条消息后，可以向broker发送basic.ack方法，确认一条消息已经收到。在默认的情况下，consumer acknowledgement模式是开启的，如果不想发送basic.ack，可以在发送basic.consume方法时指定no-ack参数，关闭consumer acknowledgement模式。

Publisher confirm并没有在AMQ协议的基础上添加新的确认方法，而是复用了basic.ack方法。但是publisher confirm模式并不是默认打开的，需要调用confirm.select方法将channel设置成confirm模式。当开启了confirm模式之后，只有当一条消息被所有的mirrors接受之后，publisher才会收到这条消息的confirm，也就是一个basic.ack方法。

RabbitMQ支持事务(transaction)。事务模式也不是默认开启的，需要调用tx.select方法开启事务模式。当开启了事务模式后，只有当一个事务被所有的mirrors接受之后，tx.commit-ok才会返回给客户端。confirm模式和开启事务模式都可以保证”被所有的mirrors接受”，那么，开启confirm模式和开启事务模式有什么区别吗？不同点在于confirm是针对一条消息的，而事务是可以针对多条消息的（当然是针对同一个queue的多条消息）。另外就是，confirm模式只是针对publisher的设置，而事务模式即可以针对publisher，也可以针对consumer。如果针对publisher设置事务模式，则我们可以将多个basic.publish方法放在一个事务中，当所有的publish的消息被所有的mirrors接受后，publisher client会收到tx.commit-ok的方法。如果针对consumer设置事务模式，则我们可以将多个basic.ack方法放在一个事务中，收到tx.commit-ok时表示这些消息都被确认了。


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

Message: 由Header和Body组成，Header是由生产者添加的各种属性的集合，包括Message是否被持久化、由哪个Message Queue接受、优先级是多少等。而Body是真正需要传输的APP数据。

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


**消息什么时候需要持久化？**

RabbitMQ在两种情况下会将消息写入磁盘：

- 消息本身在publish的时候就要求消息写入磁盘；

- 内存紧张，需要将部分内存中的消息转移到磁盘；

**消息什么时候会刷到磁盘？**

- 数据在写入文件时，首先会写入到这个Buffer，如果Buffer已满，则会将Buffer写入到文件（未必刷到磁盘）；

- 有个固定的刷盘时间：25ms，也就是不管Buffer满不满，每隔25ms，Buffer里的数据及未刷新到磁盘的文件内容必定会刷到磁盘；

- 每次消息写入后，如果没有后续写入请求，则会直接将已写入的消息刷到磁盘：使用Erlang的receive x after 0来实现，只要进程的信箱里没有消息，则产生一个timeout消息，而timeout会触发刷盘操作。

**消息在磁盘文件中的格式**

消息保存于$MNESIA/msg_store_persistent/x.rdq文件中，其中x为数字编号，从1开始，每个文件最大为16M（16777216），超过这个大小会生成新的文件，文件编号加1。消息以以下格式存在于文件中：
<<Size:64, MsgId:16/binary, MsgBody>>

MsgId为RabbitMQ通过rabbit_guid:gen()每一个消息生成的GUID，MsgBody会包含消息对应的exchange，routing_keys，消息的内容，消息对应的协议版本，消息内容格式（二进制还是其它）等等。

**文件何时删除？**

- 阈值合并文件：当所有文件中的垃圾消息（已经被删除的消息）比例大于阈值（GARBAGE_FRACTION = 0.5）时，会触发文件合并操作（至少有三个文件存在的情况下），以提高磁盘利用率。

- 删除文件：publish消息时写入内容，ack消息时删除内容（更新该文件的有用数据大小），当一个文件的有用数据等于0时，删除该文件。

**消息索引什么时候需要持久化？**

索引的持久化与消息的持久化类似，也是在两种情况下需要写入到磁盘中：

- 要么本身需要持久化，

- 要么因为内存紧张，需要释放部分内存。

#### 深入持久化

在RabbitMQ中，MessageQueue主要由两部分组成，一个为AMQQueue，主要负责实现AMQP协议的逻辑功能。另外一个是用来存储消息的BackingQueue，本文重点关注的是BackingQueue的设计。

![MessageQueue](/images/rabbit-006.webp)

在RabbitMQ中BackingQueue又由5个子队列组成：Q1、Q2、Delta、Q3和Q4。RabbitMQ中的消息一旦进入队列，不是固定不变的，它会随着系统的负载在队列中不断流动，消息的状态不断发生变化。RabbitMQ中的消息一共有5种状态：

- a)Alpha：消息的内容和消息索引都保存在内存中；

- b)Beta：消息内容保存在磁盘上，消息索引保存在内存中；

- c)Gamma：消息内容保存在磁盘上，消息索引在磁盘和内存都有；

- d)Delta：消息内容和索引都在磁盘上；

> 注意：对于持久化的消息，消息内容和消息索引都必须先保存到磁盘上，才会处于上述状态中的一种，而Gamma状态的消息只有持久化的消息才会有该状态。

- BackingQueue中的5个子队列中的消息状态，Q1和Q4对应的是Alpha状态，Q2和Q3是Beta状态，Delta对应的是Delta状态。上述就是RabbitMQ的多层队列结构的设计，我们可以看出从Q1到Q4，基本经历的是由RAM到DISK，再到RAM的设计。这样的设计的好处就是当队列负载很高的情况下，能够通过将一部分消息由磁盘保存来节省内存空间，当负载降低的时候，这部分消息又渐渐回到内存，被消费者获取，使得整个队列有很好的弹性。下面我们就来看一下，整个消息队列的工作流程。

- 引起消息流动主要有两方面的因素：其一是消费者获取消息；其二是由于内存不足，引起消息的换出到磁盘上（Q1-.>Q2、Q2->Delta、Q3->Delta、Q4->Q3）。RabbitMQ在系统运行时会根据消息传输的速度计算一个当前内存中能够保存的最大消息数量（Target_RAM_Count），当内存中的消息数量大于该值时，就会引起消息的流动。进入队列的消息，一般会按着Q1->Q2->Delta->Q3->Q4的顺序进行流动，但是并不是每条消息都一定会经历所有的状态，这个取决于当时系统的负载状况。

- 当消费者获取消息时，首先会从Q4队列中获取消息，如果Q4获取成功，则返回，如果Q4为空，则尝试从Q3获取消息；首先，系统会判断Q3队列是否为空，如果为空，则直接返回队列为空，即此时队列中无消息（后续会论证）。如果不为空，则取出Q3的消息，然后判断此时Q3和Delta队列的长度，如果都为空，则可认为Q2、Delta、Q3和Q4全部为空(后续说明)，此时将Q1中消息直接转移到Q4中，下次直接从Q4中获取消息。如果Q3为空，Delta不空，则将Delta中的消息转移到Q3中；如果Q3非空，则直接下次从Q3中获取消息。在将Delta转移到Q3的过程中，RabbitMQ是按照索引分段读取的，首先读取某一段，直到读到的消息非空为止，然后判断读取的消息个数与Delta中的消息个数是否相等，如果相等，则断定此时Delta中已无消息，则直接将Q2和刚读到的消息一并放入Q3中。如果不相等，则仅将此次读到的消息转移到Q3中。这就是消费者引起的消息流动过程。

![MessageQueue](/images/rabbit-007.webp)


- 下面我们分析一下由于内存不足引起的消息换出。消息换出的条件是内存中保存的消息数量+等待ACK的消息的数量>Target_RAM_Count。当条件触发时，系统首先会判断如果当前进入等待ACK的消息的速度大于进入队列的消息的速度时，会先处理等待ACK的消息。步骤基本上Q1->Q2或者Q3移动，取决于Delta队列是否为空。Q4->Q3移动，Q2和Q3向Delta移动。

- 最后，我们来分析一下前面遗留的两个问题，一个是为什么Q3队列为空即可认定整个队列为空。试想如果Q3为空，Delta不空，则在Q3取出最后一条消息时，Delta上的消息就会被转移到Q3上，与Q3空矛盾。如果Q2不空，则在Q3取出最后一条消息，如果Delta为空时，会将Q2的消息并入Q3，与Q3为空矛盾。如果Q1不空，则在Q3取出最后一条消息，如果Delta和Q3均为空时，则将Q1的消息转移到Q4中，与Q4为空矛盾。这也解释了另外一个问题，即为什么Q3和Delta为空，Q2就为空。

- 上述就是整个消息在RabbitMQ队列中流动过程。从上述流程可以看出，消息如果能够被尽早消费掉，就不需要经历持久化的过程，因为这样会加系统的开销。如果消息被消费的速度过慢，RabbitMQ通过换出内存的方式，防止内存溢出。


<br/>


