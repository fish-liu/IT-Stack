
<h2>Dubbo的架构设计</h2>

本文主要基于[《Dubbo 开发指南 —— 框架设计》](http://dubbo.apache.org/zh-cn/docs/dev/design.html)  参考[Dubbo 源码分析 —— 核心流程一览](https://www.jianshu.com/p/a50129d2c1ff)

---------------------------------------

dubbo 相关知识的整理


| 特性 | 描述 |
|---|---|
| 透明远程调用 | 就像调用本地方法一样调用远程方法；只需简单配置，没有任何API侵入； |
| 负载均衡机制 | Client端LB，可在内网替代F5等硬件负载均衡器； |
| 容错重试机制 | 服务Mock数据，重试次数、超时机制等； |
| 自动注册发现 | 注册中心基于接口名查询服务提 供者的IP地址，并且能够平滑添加或删除服务提供者； |
| 性能日志监控 | Monitor统计服务的调用次调和调用时间的监控中心； |
| 服务治理中心 | 路由规则，动态配置，服务降级，访问控制，权重调整，负载均衡，等手动配置。|
| 自动治理中心 | 无，比如：熔断限流机制、自动权重调整等； |



### 框架设计

#### Dubbo结构图

Dubbo核心功能

- Remoting：远程通讯，提供对多种NIO框架抽象封装，包括“同步转异步”和“请求-响应”模式的信息交换方式。

- Cluster：服务框架，提供基于接口方法的透明远程过程调用，包括多协议支持，以及软负载均衡，失败容错，地址路由，动态配置等集群支持。

- Registry：服务注册，基于注册中心目录服务，使服务消费方能动态的查找服务提供方，使地址透明，使服务提供方可以平滑增加或减少机器。


![整体设计](/images/dubbo-relation.jpg)

图例说明：

- 图中小方块 Protocol, Cluster, Proxy, Service, Container, Registry, Monitor 代表层或模块，蓝色的表示与业务有交互，绿色的表示只对 Dubbo 内部交互。

- 图中背景方块 Consumer, Provider, Registry, Monitor 代表部署逻辑拓扑节点。

- 图中蓝色虚线为初始化时调用，红色虚线为运行时异步调用，红色实线为运行时同步调用。

- 图中只包含 RPC 的层，不包含 Remoting 的层，Remoting 整体都隐含在 Protocol 中。

**节点角色说明：**

对于以上的3个核心功能，Dubbo有涉及到哪些组件角色，来协作完成分布式治理的呢？

- Consumer（服务消费者）：服务消费者启动后，会从注册中心查找服务提供者列表，并tcp连接到提供者服务器；当应用调用RPC接口时，服务消费者通过一定的路由算法，选择某个服务提供者进行通信，调用对应接口获取数据。同时，消费者会向注册中心订阅需要的服务，当订阅的服务有更新时，注册中心将通知对应的消费者。消费者也会定时向监控中心报告状态及统计数据等信息，以备监控中心进行监控统计等。

- Provider（服务提供者）：服务提供者启动之后，会将提供的服务信息注册到注册中心；其同时接受消费者的服务请求并定时将状态及统计信息同步到监控中心。

- Container（服务容器）：服务运行容器。

- Register（注册中心）：服务提供者先启动start，然后注册register服务。消费订阅subscribe服务，如果没有订阅到自己想获得的服务，它会不断的尝试订阅。新的服务注册到注册中心以后，注册中心会将这些服务通过notify到消费者。

- Monitor（监控中心）：这是一个监控，图中虚线表明Consumer 和Provider通过异步的方式发送消息至Monitor，Consumer和Provider会将信息存放在本地磁盘，平均1min会发送一次信息。Monitor在整个架构中是可选的（图中的虚线并不是可选的意思），Monitor功能需要单独配置，不配置或者配置以后，Monitor挂掉并不会影响服务的调用。

**调用关系说明：**

- 0：服务容器负责启动，加载，运行服务提供者。
- 1：服务提供者在启动时，向注册中心注册自己提供的服务。
- 2：服务消费者在启动时，向注册中心订阅自己所需的服务。
- 3：注册中心返回服务提供者地址列表给消费者，如果有变更，注册中心将基于长连接推送变更数据给消费者。
- 4：服务消费者，从提供者地址列表中，基于软负载均衡算法，选一台提供者进行调用，如果调用失败，再选另一台调用。
- 5：服务消费者和提供者，在内存中累计调用次数和调用时间，定时每分钟发送一次统计数据到监控中心。

![整体设计](/images/dubbo-relation1.webp)

#### 整体设计

![整体设计](/images/dubbo-framework.jpg)

图例说明：

- 图中左边淡蓝背景的为服务消费方使用的接口，右边淡绿色背景的为服务提供方使用的接口，位于中轴线上的为双方都用到的接口。

- 图中从下至上分为十层，各层均为单向依赖，右边的黑色箭头代表层之间的依赖关系，每一层都可以剥离上层被复用，其中，Service 和 Config 层为 API，其它各层均为 SPI。

- 图中绿色小块的为扩展接口，蓝色小块为实现类，图中只显示用于关联各层的实现类。

- 图中蓝色虚线为初始化过程，即启动时组装链，红色实线为方法调用过程，即运行时调时链，紫色三角箭头为继承，可以把子类看作父类的同一个节点，线上的文字为调用的方法。

> Dubbo框架设计一共划分了10个层，最上面的Service层是留给实际想要使用Dubbo开发分布式服务的开发者实现业务逻辑的接口层。图中左边淡蓝背景的为服务消费方使用的接口，右边淡绿色背景的为服务提供方使用的接口， 位于中轴线上的为双方都用到的接口。


**各层说明**

- config 配置层：对外配置接口，以 ServiceConfig, ReferenceConfig 为中心，可以直接初始化配置类，也可以通过 spring 解析配置生成配置类

- proxy 服务代理层：服务接口透明代理，生成服务的客户端 Stub 和服务器端 Skeleton, 以 ServiceProxy 为中心，扩展接口为 ProxyFactory

- registry 注册中心层：封装服务地址的注册与发现，以服务 URL 为中心，扩展接口为 RegistryFactory, Registry, RegistryService

- cluster 路由层：封装多个提供者的路由及负载均衡，并桥接注册中心，以 Invoker 为中心，扩展接口为 Cluster, Directory, Router, LoadBalance

- monitor 监控层：RPC 调用次数和调用时间监控，以 Statistics 为中心，扩展接口为 MonitorFactory, Monitor, MonitorService

- protocol 远程调用层：封装 RPC 调用，以 Invocation, Result 为中心，扩展接口为 Protocol, Invoker, Exporter

- exchange 信息交换层：封装请求响应模式，同步转异步，以 Request, Response 为中心，扩展接口为 Exchanger, ExchangeChannel, ExchangeClient, ExchangeServer

- transport 网络传输层：抽象 mina 和 netty 为统一接口，以 Message 为中心，扩展接口为 Channel, Transporter, Client, Server, Codec

- serialize 数据序列化层：可复用的一些工具，扩展接口为 Serialization, ObjectInput, ObjectOutput, ThreadPool


**关系说明**

- 在 RPC 中，Protocol 是核心层，也就是只要有 Protocol + Invoker + Exporter 就可以完成非透明的 RPC 调用，然后在 Invoker 的主过程上 Filter 拦截点。

- dubbo-rpc 模块可以独立完成该功能

  - 图中的 Consumer 和 Provider 是抽象概念，只是想让看图者更直观的了解哪些类分属于客户端与服务器端，不用 Client 和 Server 的原因是 Dubbo 在很多场景下都使用 Provider, Consumer, Registry, Monitor 划分逻辑拓普节点，保持统一概念。

  - 而 Cluster 是外围概念，所以 Cluster 的目的是将多个 Invoker 伪装成一个 Invoker，这样其它人只要关注 Protocol 层 Invoker 即可，加上 Cluster 或者去掉 Cluster 对其它层都不会造成影响，因为只有一个提供者时，是不需要 Cluster 的。

- dubbo-cluster 模块提供的是非必需的功能，移除不会影响到其它模块。RPC模块也可以正常运行。

  - Proxy 层封装了所有接口的透明化代理，而在其它层都以 Invoker 为中心，只有到了暴露给用户使用时，才用 Proxy 将 Invoker 转成接口，或将接口实现转成 Invoker，也就是去掉 Proxy 层 RPC 是可以 Run 的，只是不那么透明，不那么看起来像调本地服务一样调远程服务。

- 简单粗暴的说，Proxy 会拦截 service.doSomething(args) 的调用，“转发”给该 Service 对应的 Invoker ，从而实现透明化的代理。

  - 而 Remoting 实现是 Dubbo 协议的实现，如果你选择 RMI 协议，整个 Remoting 都不会用上，Remoting 内部再划为 Transport 传输层和 Exchange 信息交换层，Transport 层只负责单向消息传输，是对 Mina, Netty, Grizzly 的抽象，它也可以扩展 UDP 传输，而 Exchange 层是在传输层之上封装了 Request-Response 语义。

  - Registry 和 Monitor 实际上不算一层，而是一个独立的节点，只是为了全局概览，用层的方式画在一起。


#### 模块分包

![模块分包](/images/dubbo-modules.jpg)

模块说明：

- dubbo-common 公共逻辑模块：包括 Util 类和通用模型。
- dubbo-remoting 远程通讯模块：相当于 Dubbo 协议的实现，如果 RPC 用 RMI协议则不需要使用此包。
- dubbo-rpc 远程调用模块：抽象各种协议，以及动态代理，只包含一对一的调用，不关心集群的管理。
- dubbo-cluster 集群模块：将多个服务提供方伪装为一个提供方，包括：负载均衡, 容错，路由等，集群的地址列表可以是静态配置的，也可以是由注册中心下发。
- dubbo-registry 注册中心模块：基于注册中心下发地址的集群方式，以及对各种注册中心的抽象。
- dubbo-monitor 监控模块：统计服务调用次数，调用时间的，调用链跟踪的服务。
- dubbo-config 配置模块：是 Dubbo 对外的 API，用户通过 Config 使用Dubbo，隐藏 Dubbo 所有细节。
- dubbo-container 容器模块：是一个 Standlone 的容器，以简单的 Main 加载 Spring 启动，因为服务通常不需要 Tomcat/JBoss 等 Web 容器的特性，没必要用 Web 容器去加载服务。

整体上按照分层结构进行分包，与分层的不同点在于：

- container 为服务容器，用于部署运行服务，没有在层中画出。
- protocol 层和 proxy 层都放在 rpc 模块中，这两层是 rpc 的核心，在不需要集群也就是只有一个提供者时，可以只使用这两层完成 rpc 调用。
- transport 层和 exchange 层都放在 remoting 模块中，为 rpc 调用的通讯基础。
- serialize 层放在 common 模块中，以便更大程度复用。


### 核心流程

#### 调用链

展开总设计图的红色调用链，如下：

![调用链](/images/dubbo-extension.jpg)

- 垂直分层如下：

  - 下方 淡蓝背景( Consumer )：服务消费方使用的接口
  - 上方 淡绿色背景( Provider )：服务提供方使用的接口
  - 中间 粉色背景( Remoting )：通信部分的接口
  
- 自 LoadBalance 向上，每一行分成了多个相同的 Interface ，指的是负载均衡后，向 Provider 发起调用。

- 左边 括号 部分，代表了垂直部分更细化的分层，依次是：Common、Remoting、RPC、Interface 。

- 右边 蓝色虚线( Init ) 为初始化过程，通过对应的组件进行初始化。例如，ProxyFactory 初始化出 Proxy 。


#### 暴露服务时序

展开总设计图左边服务提供方暴露服务的蓝色初始化链，时序图如下：

![暴露服务时序](/images/dubbo-export.jpg)

#### 引用服务时序

展开总设计图右边服务消费方引用服务的蓝色初始化链，时序图如下：

![引用服务时序](/images/dubbo-refer.jpg)


#### 领域模型

在 Dubbo 的核心领域模型中：

- Protocol 是服务域，它是 Invoker 暴露和引用的主功能入口，它负责 Invoker 的生命周期管理。

- Invoker 是实体域，它是 Dubbo 的核心模型，其它模型都向它靠扰，或转换成它，它代表一个可执行体，可向它发起 invoke 调用，它有可能是一个本地的实现，也可能是一个远程的实现，也可能一个集群实现。

- Invocation 是会话域，它持有调用过程中的变量，比如方法名，参数等。


#### 基本设计原则

- 采用 Microkernel + Plugin 模式，Microkernel 只负责组装 Plugin，Dubbo 自身的功能也是通过扩展点实现的，也就是 Dubbo 的所有功能点都可被用户自定义扩展所替换。

- 采用 URL 作为配置信息的统一格式，所有扩展点都通过传递 URL 携带配置信息。



dubbo架构有以下特点

- 连通性：

  - 注册中心负责服务地址的注册与查找，相当于目录服务，服务提供者和消费者只在启动时与注册中心交互，注册中心不转发请求，压力较小
  - 监控中心负责统计各服务调用次数，调用时间等，统计先在内存汇总后每分钟一次发送到监控中心服务器，并以报表展示
  - 服务提供者向注册中心注册其提供的服务，并汇报调用时间到监控中心，此时间不包含网络开销
  - 服务消费者向注册中心获取服务提供者地址列表，并根据负载算法直接调用提供者，同时汇报调用时间到监控中心，此时间包含网络开销
  - 注册中心，服务提供者，服务消费者三者之间均为长连接，监控中心除外
  - 注册中心通过长连接感知服务提供者的存在，服务提供者宕机，注册中心将立即推送事件通知消费者
  - 注册中心和监控中心全部宕机，不影响已运行的提供者和消费者，消费者在本地缓存了提供者列表
  - 注册中心和监控中心都是可选的，服务消费者可以直连服务提供者

- 健壮性：

  - 监控中心宕掉不影响使用，只是丢失部分采样数据
  - 数据库宕掉后，注册中心仍能通过缓存提供服务列表查询，但不能注册新服务
  - 注册中心对等集群，任意一台宕掉后，将自动切换到另一台
  - 注册中心全部宕掉后，服务提供者和服务消费者仍能通过本地缓存通讯
  - 服务提供者无状态，任意一台宕掉后，不影响使用
  - 服务提供者全部宕掉后，服务消费者应用将无法使用，并无限次重连等待服务提供者恢复

- 伸缩性：

  - 注册中心为对等集群，可动态增加机器部署实例，所有客户端将自动发现新的注册中心
  - 服务提供者无状态，可动态增加机器部署实例，注册中心将推送新的服务提供者信息给消费者

- 升级性：

当服务集群规模进一步扩大，带动IT治理结构进一步升级，需要实现动态部署，进行流动计算，现有分布式服务架构不会带来阻力。下图是未来可能的一种架构：

![升级性](/images/dubbo-shengji.webp)


1、 架构的整体设计



2、 集群容错



3、 负载均衡

四种负载均衡策略

4、 线程模型

5、 协议

6、 特性

7、 注册中心

8、 配置









