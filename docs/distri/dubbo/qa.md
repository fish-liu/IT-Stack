
面试题收集于网上的一些文章：[阿里面试，请一定看完这26道dubbo面试题](https://www.jianshu.com/p/0b4fea213ce5) [2019年Dubbo你掌握的如何？快看看这30道高频面试题！](https://www.jianshu.com/p/ba8f3bf1cd57)

[DUBBO原理及相关面试题](https://www.jianshu.com/p/48d3b63723ed)

**问题：Dubbo中zookeeper做注册中心，如果注册中心集群都挂掉，发布者和订阅者之间还能通信吗？**

可以通信的；启动dubbo时，消费者会从zk拉取注册的生产者的地址、接口等数据，缓存在本地。每次调用时，按照本地存储的地址进行调用；注册中心的集群，任意一台宕机后，将会切换到另一台；
注册中心全部宕机后，服务的提供者和消费者仍能通过本地缓存通讯。服务提供者无状态，任一台宕机后，不影响使用；服务提供者全部宕机，服务消费者会无法使用，并无限次重连等待服务者恢复；
挂掉是不要紧的，但前提是你没有增加新的服务，如果你要调用新的服务，则是不能办到的。 

**问题：dubbo服务负载均衡策略？**

当服务提供方是集群的时候，为了避免大量请求一直落到一个或几个服务提供方机器上，从而使这些机器负载很高，甚至打死，需要做一定的负载均衡策略。Dubbo提供了多种均衡策略，缺省为random，也就是每次随机调用一台服务提供者的机器。

- 1、Random LoadBalance ：随机策略。按照概率设置权重，比较均匀，并且可以动态调节提供者的权重（权重可以在dubbo 管控台配置）。

- 2、RoundRobin LoadBalance ：轮询策略。轮询，按公约后的权重设置轮询比率。会存在执行比较慢的服务提供者堆积请求的情况，比如一个机器执行的非常慢，但是机器没有挂调用（如果挂了，那么当前机器会从Zookeeper的服务列表删除），当很多新的请求到达该机器后，由于之前的请求还没有处理完毕，会导致新的请求被堆积，久而久之，所有消费者调用这台机器上的请求都被阻塞。

- 3、LeastActive LoadBalance ： 最少活跃调用数。如果每个提供者的活跃数相同，则随机选择一个。在每个服务提供者里面维护者一个活跃数计数器，用来记录当前同时处理请求的个数，也就是并发处理任务的个数。所以如果这个值越小说明当前服务提供者处理的速度很快或者当前机器的负载比较低，所以路由选择时候就选择该活跃度最小的机器。如果一个服务提供者处理速度很慢，由于堆积，那么同时处理的请求就比较多，也就是活跃调用数目越大，这也使得慢的提供者收到更少请求，因为越慢的提供者的活跃度越来越大。

- 4、ConsistentHash LoadBalance ： 一致性Hash策略。一致性Hash，可以保证相同参数的请求总是发到同一提供者，当某一台提供者挂了时，原本发往该提供者的请求，基于虚拟节点，平摊到其他提供者，不会引起剧烈变动。


**问题：Dubbo的集群容错策略？**

正常情况下，当我们进行系统设计时候，不仅要考虑正常逻辑下代码该如何走，还要考虑异常情况下代码逻辑应该怎么走。当服务消费方调用服务提供方的服务出现错误时候，Dubbo提供了多种容错方案，缺省模式为failover，也就是失败重试。

Dubbo提供的集群容错模式：

- 1、Failover Cluster：失败重试。当服务消费方调用服务提供者失败后自动切换到其他服务提供者服务器进行重试。这通常用于读操作或者具有幂等的写操作，需要注意的是重试会带来更长延迟。可通过 retries="2" 来设置重试次数（不含第一次）。

- 2、Failfast Cluster：快速失败。 当服务消费方调用服务提供者失败后，立即报错，也就是只调用一次。通常这种模式用于非幂等性的写操作。

- 3、Failsafe Cluster：失败安全。 当服务消费者调用服务出现异常时，直接忽略异常。这种模式通常用于写入审计日志等操作。

- 4、Failback Cluster：失败自动恢复。 当服务消费端用服务出现异常后，在后台记录失败的请求，并按照一定的策略后期再进行重试。这种模式通常用于消息通知操作。

- 5、Forking Cluster：并行调用 。当消费方调用一个接口方法后，Dubbo Client会并行调用多个服务提供者的服务，只要一个成功即返回。这种模式通常用于实时性要求较高的读操作，但需要浪费更多服务资源。可通过 forks="2" 来设置最大并行数。

- 6、Broadcast Cluster：广播调用 。当消费者调用一个接口方法后，Dubbo Client会逐个调用所有服务提供者，任意一台调用异常则这次调用就标志失败。这种模式通常用于通知所有提供者更新缓存或日志等本地资源信息。


**问题：Dubbo在安全机制方面是如何解决的？**

Dubbo 通过Token令牌防止用户绕过注册中心直连，然后在注册中心上管理授权。Dubbo还提供服务黑白名单，来控制服务所允许的调用方。


**问题：Dubbo连接注册中心和直连的区别？**



**问题：Dubbo支持的协议？**

dubbo协议、RMI协议、Hessian协议、http协议、webservice协议、Thrif 协议

**问题：dubbo 协议的理解？**


0、Dubbo是什么？

Dubbo 是一个分布式、高性能、透明化的 RPC 服务框架，提供服务自动注册、自动发现等高效服务治理方案， 可以和 Spring 框架无缝集成。

RPC 指的是远程调用协议，也就是说两个服务器交互数据。


1、为什么要用 Dubbo？

随着服务化的进一步发展，服务越来越多，服务之间的调用和依赖关系也越来越复杂，诞生了面向服务的架构体系(SOA)，也因此衍生出了一系列相应的技术，如对服务提供、服务调用、连接处理、通信协议、序列化方式、服务发现、服务路由、日志输出等行为进行封装的服务框架。就这样为分布式系统的服务治理框架就出现了，Dubbo 也就这样产生了。


2、Dubbo 的整体架构设计有哪些分层?

![dubbo](/images/dubbo-003.webp)

- 接口服务层（Service）：该层与业务逻辑相关，根据 provider 和 consumer 的业务设计对应的接口和实现

- 配置层（Config）：对外配置接口，以 ServiceConfig 和 ReferenceConfig 为中心

- 服务代理层（Proxy）：服务接口透明代理，生成服务的客户端 Stub 和 服务端的 Skeleton，以 ServiceProxy 为中心，扩展接口为 ProxyFactory

- 服务注册层（Registry）：封装服务地址的注册和发现，以服务 URL 为中心，扩展接口为 RegistryFactory、Registry、RegistryService

- 路由层（Cluster）：封装多个提供者的路由和负载均衡，并桥接注册中心，以Invoker 为中心，扩展接口为 Cluster、Directory、Router 和 LoadBlancce

- 监控层（Monitor）：RPC 调用次数和调用时间监控，以 Statistics 为中心，扩展接口为 MonitorFactory、Monitor 和 MonitorService

- 远程调用层（Protocal）：封装 RPC 调用，以 Invocation 和 Result 为中心，扩展接口为 Protocal、Invoker 和 Exporter

- 信息交换层（Exchange）：封装请求响应模式，同步转异步。以 Request 和Response 为中心，扩展接口为 Exchanger、ExchangeChannel、ExchangeClient 和 ExchangeServer

- 网络 传输 层（Transport）：抽象 mina 和 netty 为统一接口，以 Message 为中心，扩展接口为 Channel、Transporter、Client、Server 和 Codec

- 数据序列化层（Serialize）：可复用的一些工具，扩展接口为 Serialization、ObjectInput、ObjectOutput 和 ThreadPool


3、默认使用的是什么通信框架，还有别的选择吗?

默认也推荐使用 netty 框架，还有 mina。

4、服务调用是阻塞的吗？

默认是阻塞的，可以异步调用，没有返回值的可以这么做。Dubbo 是基于 NIO 的非阻塞实现并行调用，客户端不需要启动多线程即可完成并行调用多个远程服务，相对多线程开销较小，异步调用会返回一个 Future 对象。

异步调用流程图如下。

![dubbo-invoker](/images/dubbo-invoker.webp)

5、一般使用什么注册中心？还有别的选择吗？

推荐使用 Zookeeper 作为注册中心，还有 Redis、Multicast、Simple 注册中心，但不推荐。

- Multicast注册中心：Multicast注册中心不需要任何中心节点，只要广播地址，就能进行服务注册和发现。基于网络中组播传输实现；

- Zookeeper注册中心： 基于分布式协调系统Zookeeper实现，采用Zookeeper的watch机制实现数据变更；

- redis注册中心： 基于redis实现，采用key/Map存储，key存储服务名和类型，Map中key存储服务URL，value服务过期时间。基于redis的发布/订阅模式通知数据变更；

- Simple注册中心

6、默认使用什么序列化框架，你知道的还有哪些？

推荐使用 Hessian 序列化，还有 Duddo、FastJson、Java 自带序列化。

7、服务提供者能实现失效踢出是什么原理？

服务失效踢出基于 zookeeper 的临时节点原理。

8、服务上线怎么不影响旧版本？

采用多版本开发，不影响旧版本。

9、如何解决服务调用链过长的问题？

可以结合 zipkin 实现分布式服务追踪。Dubbo 可以使用 Pinpoint 和 Apache Skywalking(Incubator) 实现分布式服务追踪，当然还有其他很多方案。

10、说说核心的配置有哪些？

![dubbo-config](/images/dubbo-config.webp)

配置之间的关系见下图。

![dubbo-config](/images/dubbo-config1.webp)

![dubbo-config](/images/dubbo-config2.png)

11、Dubbo 推荐用什么协议？ 每种协议的应用场景，优缺点？

- dubbo（推荐）： 单一长连接和NIO异步通信，适合大并发小数据量的服务调用，以及消费者远大于提供者。传输协议tcp，异步，hessian序列化

- rmi ： 采用JDK标准的rmi协议实现，传输参数和返回值对象需要实现Serializable接口，使用java标准序列化机制，使用阻塞式短链接，传输数据包大小混合，消费者和提供者个数查不多，可传文件，传输协议 tcp，多个短连接，tcp协议传输，同步传输，适用常规的远程服务调用和rmi互操作。在依赖低版本的Common-Collections包，java序列化存在安全漏洞；

- hessian ： 集成hessian服务，基于http通讯，采用servlet暴露服务，Dubbo内嵌jetty作为服务器时默认实现，提供与hessian服务互操作，多个短链接，同步http传输，hessian序列化，传入参数较大，提供者大于消费者，提供者压力较大，可传文件。

- http ： 基于http表单提交的远程调用协议，适用spring的HttpInvoker实现。多个短连接传输协议http，传入参数大小混合，提供者个数对于消费者，需要给应用程序和浏览器js适用。

- webservice ： 基于webservice的远程调用协议，继承cxf实现，提供和原生webservice的互操作。多个短连接基于http传输，同步传输，适用系统集成和跨语言调用。

- thrift ： 当前dubbo支持的thrift协议是对thrift原生协议的扩展，在原生协议的基础上添加了一些额外的头信息，比如service name，magic number等。

- memcached ： 基于memcached实现的rpc协议

- redis ： 基于redis实现的rpc协议

- rest

12、同一个服务多个注册的情况下可以直连某一个服务吗？

可以点对点直连，修改配置即可，也可以通过 telnet 直接某个服务。

13、画一画服务注册与发现的流程图？

![dubbo-register](/images/dubbo-register.webp)

1）Provider: 暴露服务的服务提供方。

2）Consumer: 调用远程服务的服务消费方。

3）Registry: 服务注册与发现的注册中心。

4）Monitor: 统计服务的调用次调和调用时间的监控中心。

5）Container: 服务运行容器。

调用关系说明：

1）服务容器负责启动，加载，运行服务提供者。

2）服务提供者在启动时，向注册中心注册自己提供的服务。

3）服务消费者在启动时，向注册中心订阅自己所需的服务。

4）注册中心返回服务提供者地址列表给消费者，如果有变更，注册中心将基于长连接推送变更数据给消费者。

5）服务消费者，从提供者地址列表中，基于软负载均衡算法，选一台提供者进行调用，如果调用失败，再选另一台调用。

6）服务消费者和提供者，在内存中累计调用次数和调用时间，定时每分钟发送一次统计数据到监控中心。

设计的原因：

Consumer 与Provider 解偶，双方都可以横向增减节点数。

注册中心对本身可做对等集群，可动态增减节点，并且任意一台宕掉后，将自动切换到另一台

去中心化，双方不直接依懒注册中心，即使注册中心全部宕机短时间内也不会影响服务的调用

服务提供者无状态，任意一台宕掉后，不影响使用



14、Dubbo 集群容错有几种方案？

![dubbo-fail](/images/dubbo-fail.webp)

- failover cluster：失败自动切换，自动重试其他服务器（默认）

- failfast cluster：快速失败，立即报错，只发起一次调用

- failsafe cluster：失败安全，出现异常时，直接忽略

- failback cluster：失败自动恢复，记录失败请求，定时重发

- forking cluster：并行调用多个服务器，只要有一个成功即返回

- broadcast cluster：广播逐个调用所有提供者，任意一个报错则报错

15、Dubbo 服务降级，失败重试怎么做？

可以通过 dubbo:reference 中设置 mock="return null"。mock 的值也可以修改为 true，然后再跟接口同一个路径下实现一个 Mock 类，命名规则是 “接口名称+Mock” 后缀。然后在 Mock 类里实现自己的降级逻辑


16、Dubbo 使用过程中都遇到了些什么问题？

在注册中心找不到对应的服务,检查 service 实现类是否添加了@service 注解无法连接到注册中心,检查配置文件中的对应的测试 ip 是否正确

Dubbo 的设计目的是为了满足高并发小数据量的 rpc 调用，在大数据量下的性能表现并不好，建议使用 rmi 或 http 协议。

17、Dubbo Monitor 实现原理？

Consumer 端在发起调用之前会先走 filter 链；provider 端在接收到请求时也是先走 filter 链，然后才进行真正的业务逻辑处理。默认情况下，在 consumer 和 provider 的 filter 链中都会有 Monitorfilter。

- 1、MonitorFilter 向 DubboMonitor 发送数据
- 2、DubboMonitor 将数据进行聚合后（默认聚合 1min 中的统计数据）暂存到ConcurrentMap<Statistics, AtomicReference> statisticsMap，然后使用一个含有 3 个线程（线程名字：DubboMonitorSendTimer）的线程池每隔 1min 钟，调用 SimpleMonitorService 遍历发送 statisticsMap 中的统计数据，每发送完毕一个，就重置当前的 Statistics 的 AtomicReference
- 3、SimpleMonitorService 将这些聚合数据塞入 BlockingQueue queue 中（队列大写为 100000）
- 4、SimpleMonitorService 使用一个后台线程（线程名为：DubboMonitorAsyncWriteLogThread）将 queue 中的数据写入文件（该线程以死循环的形式来写）
- 5、SimpleMonitorService 还会使用一个含有 1 个线程（线程名字：DubboMonitorTimer）的线程池每隔 5min 钟，将文件中的统计数据画成图表


18、Dubbo 用到哪些设计模式？

Dubbo 框架在初始化和通信过程中使用了多种设计模式，可灵活控制类加载、权限控制等功能。

- 工厂模式

Provider 在 export 服务时，会调用 ServiceConfig 的 export 方法。ServiceConfig中有个字段：

```
private static final Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();
```

Dubbo 里有很多这种代码。这也是一种工厂模式，只是实现类的获取采用了 JDKSPI 的机制。这么实现的优点是可扩展性强，想要扩展实现，只需要在 classpath下增加个文件就可以了，代码零侵入。另外，像上面的 Adaptive 实现，可以做到调用时动态决定调用哪个实现，但是由于这种实现采用了动态代理，会造成代码调试比较麻烦，需要分析出实际调用的实现类。

- 装饰器模式

Dubbo 在启动和调用阶段都大量使用了装饰器模式。以 Provider 提供的调用链为例，具体的调用链代码是在 ProtocolFilterWrapper 的 buildInvokerChain 完成的，具体是将注解中含有 group=provider 的 Filter 实现，按照 order 排序，最后的调用顺序是：

```
EchoFilter -> ClassLoaderFilter -> GenericFilter -> ContextFilter ->
ExecuteLimitFilter -> TraceFilter -> TimeoutFilter -> MonitorFilter ->ExceptionFilter
```

更确切地说，这里是装饰器和责任链模式的混合使用。例如，EchoFilter 的作用是判断是否是回声测试请求，是的话直接返回内容，这是一种责任链的体现。而像ClassLoaderFilter 则只是在主功能上添加了功能，更改当前线程的 ClassLoader，这是典型的装饰器模式。

- 观察者模式

Dubbo 的 Provider 启动时，需要与注册中心交互，先注册自己的服务，再订阅自己的服务，订阅时，采用了观察者模式，开启一个 listener。注册中心会每 5 秒定时检查是否有服务更新，如果有更新，向该服务的提供者发送一个 notify 消息，provider 接受到 notify 消息后，运行 NotifyListener 的 notify 方法，执行监听器方法。

- 动态代理模式

Dubbo 扩展 JDK SPI 的类 ExtensionLoader 的 Adaptive 实现是典型的动态代理实现。Dubbo 需要灵活地控制实现类，即在调用阶段动态地根据参数决定调用哪个实现类，所以采用先生成代理类的方法，能够做到灵活的调用。生成代理类的代码是 ExtensionLoader 的 createAdaptiveExtensionClassCode 方法。代理类主要逻辑是，获取 URL 参数中指定参数的值作为获取实现类的 key。



19、Dubbo 配置文件是如何加载到 Spring 中的？

Spring 容器在启动的时候，会读取到 Spring 默认的一些 schema 以及 Dubbo 自定义的 schema，每个 schema 都会对应一个自己的 NamespaceHandler，NamespaceHandler 里面通过 BeanDefinitionParser 来解析配置信息并转化为需要加载的 bean 对象！


20、Dubbo SPI 和 Java SPI 区别？

JDK SPI：

JDK 标准的 SPI 会一次性加载所有的扩展实现，如果有的扩展加载很耗时，但也没用上，很浪费资源。所以只希望加载某个的实现，就不现实了

DUBBO SPI：

1、对 Dubbo 进行扩展，不需要改动 Dubbo 的源码

2、延迟加载，可以一次只加载自己想要加载的扩展实现。

3、增加了对扩展点 IOC 和 AOP 的支持，一个扩展点可以直接 setter 注入其它扩展点。

4、Dubbo 的扩展机制能很好的支持第三方 IoC 容器，默认支持 Spring Bean。


21、Dubbo 支持分布式事务吗？

目前暂时不支持，可与通过 tcc-transaction 框架实现

介绍：tcc-transaction 是开源的 TCC 补偿性分布式事务框架

TCC-Transaction 通过 Dubbo 隐式传参的功能，避免自己对业务代码的入侵。


22、Dubbo 可以对结果进行缓存吗？

为了提高数据访问的速度。Dubbo 提供了声明式缓存，以减少用户加缓存的工作量  `<dubbo:reference cache="true" />`

其实比普通的配置文件就多了一个标签 cache="true"


23、服务上线怎么兼容旧版本？

可以用版本号（version）过渡，多个不同版本的服务注册到注册中心，版本号不同的服务相互间不引用。这个和服务分组的概念有一点类似。

24、Dubbo 必须依赖的包有哪些？

Dubbo 必须依赖 JDK，其他为可选。

25、Dubbo telnet 命令能做什么？

dubbo 服务发布之后，我们可以利用 telnet 命令进行调试、管理。Dubbo2.0.5 以上版本服务提供端口支持 telnet 命令

连接服务

telnet localhost 20880 //键入回车进入 Dubbo 命令模式。

查看服务列表

```
dubbo>ls
com.test.TestService
dubbo>ls com.test.TestService
create
delete
query
```

· ls (list services and methods)

· ls : 显示服务列表。

· ls -l : 显示服务详细信息列表。

· ls XxxService：显示服务的方法列表。

· ls -l XxxService：显示服务的方法详细信息列表。


26、Dubbo 支持服务降级吗？

以通过 dubbo:reference 中设置 mock="return null"。mock 的值也可以修改为 true，然后再跟接口同一个路径下实现一个 Mock 类，命名规则是 “接口名称+Mock” 后缀。然后在 Mock 类里实现自己的降级逻辑


27、Dubbo 如何优雅停机？

Dubbo 是通过 JDK 的 ShutdownHook 来完成优雅停机的，所以如果使用kill -9 PID 等强制关闭指令，是不会执行优雅停机的，只有通过 kill PID 时，才会执行。

28、Dubbo 和 Dubbox 之间的区别？

Dubbox 是继 Dubbo 停止维护后，当当网基于 Dubbo 做的一个扩展项目，如加了服务可 Restful 调用，更新了开源组件等。

29、Dubbo 和 Spring Cloud 的区别？

Dubbo是 SOA 时代的产物，它的关注点主要在于服务的调用，流量分发、流量监控和熔断。而 Spring Cloud诞生于微服务架构时代，考虑的是微服务治理的方方面面，另外由于依托了 Spirng、Spirng Boot的优势之上，两个框架在开始目标就不一致，Dubbo 定位服务治理、Spirng Cloud 是一个生态。

最大的区别：Dubbo底层是使用Netty这样的NIO框架，是基于TCP协议传输的，配合以Hession序列化完成RPC通信。

而SpringCloud是基于Http协议+Rest接口调用远程过程的通信，相对来说，Http请求会有更大的报文，占的带宽也会更多。但是REST相比RPC更为灵活，服务提供方和调用方的依赖只依靠一纸契约，不存在代码级别的强依赖，这在强调快速演化的微服务环境下，显得更为合适，至于注重通信速度还是方便灵活性，具体情况具体考虑。

![dubbo-spring](/images/dubbo-spring.webp)


30、你还了解别的分布式框架吗？

别的还有 spring 的 spring cloud，facebook 的 thrift，twitter 的 finagle 等


31、Dubbo需要 Web 容器吗？

不需要，如果硬要用Web 容器，只会增加复杂性，也浪费资源。

32、Dubbo内置了哪几种服务容器？

Spring Container

Jetty Container

Log4j Container

Dubbo 的服务容器只是一个简单的 Main 方法，并加载一个简单的 Spring 容器，用于暴露服务。

33、Dubbo里面有哪几种节点角色？

- provider ：暴露服务的服务提供方
- consumer ：调用远程服务的服务消费者
- registry ：服务注册与发现的注册中心
- monitor ：统计服务的调用次数和调用时间的监控中心
- container ：服务运行器


34、Dubbo有哪几种配置方式？

1）Spring 配置方式

2）Java API 配置方式


35、在 Provider 上可以配置的 Consumer 端的属性有哪些？

1）timeout：方法调用超时

2）retries：失败重试次数，默认重试 2 次

3）loadbalance：负载均衡算法，默认随机

4）actives 消费者端，最大并发调用限制


36、Dubbo启动时如果依赖的服务不可用会怎样？

Dubbo 缺省会在启动时检查依赖的服务是否可用，不可用时会抛出异常，阻止 Spring 初始化完成，默认 check="true"，可以通过 check="false" 关闭检查。


37、Dubbo有哪几种负载均衡策略，默认是哪种？

![dubbo-loadbalance](/images/dubbo-loadbalance.webp)

- Random LoadBalance ：随机，按权重设置随机概率（默认）
- RoundRobin LoadBalance ：轮询，按公约后的权重设置轮询比率
- LeastActive LoadBalance ： 最少活跃调用数，相同活跃数的随机
- ConsistentHash LoadBalance ：一致性hash，相同参数的请求总是发到同一服务提供者。


38、Dubbo支持服务多协议吗？

Dubbo 允许配置多协议，在不同服务上支持不同协议或者同一服务上同时支持多种协议。


39、注册了多个同一样的服务，如何测试指定的某一个服务呢？

可以配置环境点对点直连，绕过注册中心，将以服务接口为单位，忽略注册中心的提供者列表。


40、当一个服务接口有多种实现时怎么做？

当一个接口有多种实现时，可以用 group 属性来分组，服务提供方和消费方都指定同一个 group 即可。



41、服务读写推荐的容错策略是怎样的？

读操作建议使用 Failover 失败自动切换，默认重试两次其他服务器。

写操作建议使用 Failfast 快速失败，发一次调用失败就立即报错。


42、Dubbo的管理控制台能做什么？

管理控制台主要包含：路由规则，动态配置，服务降级，访问控制，权重调整，负载均衡，等管理功能。

43、说说 Dubbo 服务暴露的过程。

Dubbo 会在 Spring 实例化完 bean 之后，在刷新容器最后一步发布 ContextRefreshEvent 事件的时候，通知实现了 ApplicationListener 的 ServiceBean 类进行回调 onApplicationEvent 事件方法，Dubbo
会在这个方法中调用 ServiceBean 父类 ServiceConfig 的 export方法，而该方法真正实现了服务的（异步或者非异步）发布。

44、你觉得用 Dubbo 好还是 Spring Cloud 好？

扩展性的问题，没有好坏，只有适合不适合，不过我好像更倾向于使用 Dubbo, Spring Cloud 版本升级太快，组件更新替换太频繁，配置太繁琐，还有很多我觉得是没有 Dubbo 顺手的地方……

45、zookeeper的原理。

ZooKeeper 是以 Fast Paxos 算法为基础的，Paxos 算法存在活锁的问题，即当有多个 proposer 交错提交时，有可能互相排斥导致没有一个 proposer 能提交成功，而 Fast Paxos 作了一些优化，通过选举产生一个 leader (领导者)，只有 leader 才能提交 proposer，具体 算法可见 Fast Paxos。因此，要想弄懂 ZooKeeper 首先得对 Fast Paxos 有所了解。

ZooKeeper 的基本运转流程:1、选举 Leader。2、同步数据。3、选举 Leader 过程中算法有很多，但要达到的选举标准是一致的。 4、Leader 要具有最高的执行 ID，类似 root 权限。 5、集群中大多数的机器得到响应并 follow 选出的 Leader。


46、Zookeeper和Eureka区别

在Eureka中，如果有服务器宕掉，Eureka不会有像Zookeeper的选举leader的过程，客户端请求会自动切换新的Eureka的节点中，当宕掉的服务器重新恢复后，Eureka会再次回调管理中。

- Eureka服务节点在短时间里丢失了大量的心跳连接，Eureka节点会进入”自我保护模式“同时保留”好数据“与”坏数据。

- ZooKeeper下所有节点不可能保证任何时候都能缓存所有的服务注册信息

- zookeeper是保证cp的一致性

- Eureka是保证ap的可用性

注意 CAP定理（C-数据一致性；A-服务可用性；P-服务对网络分区故障的容错性）


47、Dubbo的核心功能？

主要就是如下3个核心功能：

Remoting：网络通信框架，提供对多种NIO框架抽象封装，包括“同步转异步”和“请求-响应”模式的信息交换方式。

Cluster：服务框架，提供基于接口方法的透明远程过程调用，包括多协议支持，以及软负载均衡，失败容错，地址路由，动态配置等集群支持。

Registry：服务注册，基于注册中心目录服务，使服务消费方能动态的查找服务提供方，使地址透明，使服务提供方可以平滑增加或减少机器。


48、Dubbo的服务调用流程？

![dubbo-invoker1](/images/dubbo-invoker1.webp)


49、Dubbo的注册中心集群挂掉，发布者和订阅者之间还能通信么？

可以的，启动dubbo时，消费者会从zookeeper拉取注册的生产者的地址接口等数据，缓存在本地。

每次调用时，按照本地存储的地址进行调用。

50、Dubbo超时时间怎样设置？

Dubbo超时时间设置有两种方式：

服务提供者端设置超时时间，在Dubbo的用户文档中，推荐如果能在服务端多配置就尽量多配置，因为服务提供者比消费者更清楚自己提供的服务特性。

服务消费者端设置超时时间，如果在消费者端设置了超时时间，以消费者端为主，即优先级更高。因为服务调用方设置超时时间控制性更灵活。如果消费方超时，服务端线程不会定制，会产生警告。

51、服务调用超时问题怎么解决？

dubbo在调用服务不成功时，默认是会重试两次的。


52、Dubbo在安全机制方面是如何解决？

Dubbo通过Token令牌防止用户绕过注册中心直连，然后在注册中心上管理授权。Dubbo还提供服务黑白名单，来控制服务所允许的调用方。


53、Dubbo 的使用场景有哪些？

- 透明化的远程方法调用：就像调用本地方法一样调用远程方法，只需简单配置，没有任何API侵入。

- 软负载均衡及容错机制：可在内网替代 F5 等硬件负载均衡器，降低成本，减少单点。

- 服务自动注册与发现：不再需要写死服务提供方地址，注册中心基于接口名查询服务提供者的IP地址，并且能够平滑添加或删除服务提供者。


54、dubbo监控平台能够动态改变接口的一些设置,其原理是怎样的?

改变注册在zookeeper上的节点信息，从而zookeeper通知重新生成invoker(这些具体细节在zookeeper创建节点,zookeeper连接,zookeeper订阅中：https://www.jianshu.com/p/73224a6c07bb)。


55、怎么通过dubbo实现服务降级的,降级的方式有哪些,又有什么区别?

当网站处于高峰期时，并发量大，服务能力有限，那么我们只能暂时屏蔽边缘业务，这里面就要采用服务降级策略了。首先dubbo中的服务降级分成两个：屏蔽(mock=force)、容错(mock=fail)。

mock=force:return+null 表示消费方对该服务的方法调用都直接返回 null 值，不发起远程调用。用来屏蔽不重要服务不可用时对调用方的影响。

mock=fail:return+null 表示消费方对该服务的方法调用在失败后，再返回 null 值，不抛异常。用来容忍不重要服务不稳定时对调用方的影响。

要生效需要在dubbo后台进行配置的修改



谈谈dubbo中的负载均衡算法及特点？最小活跃数算法中是如何统计活跃数的？简单谈谈一致性哈希算法



既然你提到了dubbo的服务引用中封装通信细节是用到了动态代理,那请问创建动态代理常用的方式有哪些,他们又有什么区别?dubbo中用的是哪一种?(高频题)

jdk、cglib还有javasisit，JDK的动态代理代理的对象必须要实现一个接口，而针对于没有接口的类，则可用CGLIB。要明白两者区别必须要了解原理，明白了原理自然一通百通，CGLIB其原理也很简单，对指定的目标类生成一个子类，并覆盖其中方法实现增强，但由于采用的是继承，所以不能对final修饰的类进行代理。除了以上两种大家都很熟悉的方式外，其实还有一种方式，就是javassist生成字节码来实现代理（dubbo多处用到了javassist）。


什么是本地暴露和远程暴露,他们的区别？

在dubbo中我们一个服务可能既是Provider,又是Consumer,因此就存在他自己调用自己服务的情况,如果再通过网络去访问,那自然是舍近求远,因此他是有本地暴露服务的这个设计.从这里我们就知道这个两者的区别

- 本地暴露是暴露在JVM中,不需要网络通信.

- 远程暴露是将ip,端口等信息暴露给远程客户端,调用时需要网络通信.


服务发布过程中做了哪些事？

暴露本地服务、暴露远程服务、启动netty、连接zookeeper、到zookeeper注册、监听zookeeper



Restful api与RPC的区别

Restful API: 面向资源的架构；
核心特点：资源、统一接口、URI和无状态
统一接口--> RESTful架构风格规定，数据的元操作，即CRUD(Create，Read，Update和Delete，即数据的增删查改)操作，分别对应于HTTP方法：GET用来获取资源，POST用来新建资源(也可以用于更新资源)，PUT用来更新资源，DELETE用来删除资源，这样就统一了数据操作的接口，仅通过HTTP方法，就可以完成对数据的所有增删查改工作。
URL--> 可以用一个URI(统一资源定位符)指向资源，即每个URI都对应一个特定的资源。
无状态--> 所谓无状态的，即所有的资源，都可以通过URI定位，而且这个定位与其他资源无关，也不会因为其他资源的变化而改变。要获取这个资源，访问它的 URI 就可以，因此 URI 就成了每一个资源的地址或识别符。

Restful API与RPC对比：
面向对象不同：RPC侧重于动作；REST的主体是资源
传输效率：RPC传输效率更高，使用自定义的TCP协议，让请求报文体积更小，或者使用HTTP2协议，也可以有效的减小报文体积
复杂度：RPC的复杂度更高
灵活性：REST灵活性更高

服务提供者暴露一个服务的详细过程：

首先ServiceConfig类拿到对外提供服务的实际类ref(如：HelloWorldImpl),然后通过ProxyFactory类的getInvoker方法使用ref生成一个AbstractProxyInvoker实例，到这一步就完成具体服务到Invoker的转化。
Dubbo处理服务暴露的关键就在Invoker转换到Exporter的过程，Invoker通过调用Protocol的export方法创建Exporter。
以Dubbo和RMI这两种典型协议的实现来进行说明：

Dubbo的实现：Dubbo协议的Invoker转为Exporter发生在DubboProtocol类的export方法，它主要是打开socket侦听服务，并接收客户端发来的各种请求，通讯细节由Dubbo自己实现。
RMI的实现：RMI协议的Invoker转为Exporter发生在RmiProtocol类的export方法，它通过Spring或Dubbo或JDK来实现RMI服务，通讯细节这一块由JDK底层来实现，这就省了不少工作量。
Proxyfactory的实现包括：javassistProxyFactory、jdkProxyFactory
Protocol的实现包括（对应dubbo支持的通讯协议）：DubboProtocol、HessianProtocol、InjvmProtocol、RmiProtocol、WebServiceProtocol

服务消费者消费一个服务的详细过程：
把远程服务转换为invoker（protocol的refer方法），然后把invoker转换为客户端需要的接口
首先ReferenceConfig类的init方法调用Protocol的refer方法生成Invoker实例(如上图中的红色部分)，这是服务消费的关键。接下来把Invoker转换为客户端需要的接口(如：HelloWorld)。


你是否了解SPI，讲一讲什么是SPI，为什么要使用SPI?

SPI具体约定：当服务的提供者，提供了服务接口的一种实现之后，在jar包的META-INF/services/目录里同时创建一个以服务接口命名的文件。该文件里就是实现该服务接口的具体实现类。而当外部程序装配这个模块的时候，就能通过该jar包META-INF/services/里的配置文件找到具体的实现类名，并装载实例化，完成模块的注入（从使用层面来说，就是运行时，动态给接口添加实现类）。 基于这样一个约定就能很好的找到服务接口的实现类，而不需要再代码里制定（不需要在代码里写死）。

这样做的好处：java设计出SPI目的是为了实现在模块装配的时候能不在程序里动态指明，这就需要一种服务发现机制。这样程序运行的时候，该机制就会为某个接口寻找服务的实现，有点类似IOC的思想，就是将装配的控制权移到程序之外，在模块化设计中这个机制尤其重要。例如，JDBC驱动，可以加载MySQL、Oracle、或者SQL Server等，目前有不少框架用它来做服务的扩张发现。
回答这个问题可以延伸一下和API的对比，API是将方法封装起来给调用者使用的，SPI是给扩展者使用的。

2、对类加载机制了解吗,说一下什么是双亲委托模式,他有什么弊端,这个弊端有没有什么我们熟悉的案例,解决这个弊端的原理又是怎么样的?

java类加载机制分为：

全盘负责：当一个类加载器加载某个Class时，该Class所依赖和引用的其它Class也将由该类加载器负责载入，除非显式的使用另外一个类加载器来载入。
双亲委派：当一个类加载器收到了类加载请求，它会把这个请求委派给父（parent）类加载器去完成，依次递归，因此所有的加载请求最终都被传送到顶层的启动类加载器中。只有在父类加载器无法加载该类时子类才尝试从自己类的路径中加载该类。（注意：类加载器中的父子关系并不是类继承上的父子关系，而是类加载器实例之间的关系。）
缓存机制：缓存机制会保证所有加载过的Class都会被缓存，当程序中需要使用某个类时，类加载器先从缓冲区中搜寻该类，若搜寻不到将读取该类的二进制数据，并转换成Class对象存入缓冲区中。这就是为什么修改了Class后需重启JVM才能生效的原因。
双亲委托模式的弊端：

判断类是否加载的时候,应用类加载器会顺着双亲路径往上判断,直到启动类加载器.但是启动类加载器不会往下询问,这个委托路线是单向的,即顶层的类加载器,无法访问底层的类加载器所加载的类。
启动类加载器中的类为系统的核心类,比如,在系统类中,提供了一个接口,并且该接口还提供了一个工厂方法用于创建该接口的实例,但是该接口的实现类在应用层中,接口和工厂方法在启动类加载器中,就会出现工厂方法无法创建由应用类加载器加载的应用实例问题。
拥有这样问题的组件有很多,比如JDBC、Xml parser等.JDBC本身是java连接数据库的一个标准,是进行数据库连接的抽象层,由java编写的一组类和接口组成，接口的实现由各个数据库厂商来完成。
双亲委托模式的补充：
在Java中,把核心类(rt.jar)中提供外部服务,可由应用层自行实现的接口,这种方式成为spi.
<在启动类加载器中,访问由应用类加载器实现spi接口的原理>
Thread类中有两个方法
public ClassLoader getContextClassLoader()//获取线程中的上下文加载器
public void setContextClassLoader(ClassLoader cl)//设置线程中的上下文加载器
通过这两个方法,可以把一个ClassLoader置于一个线程的实例之中,使该ClassLoader成为一个相对共享的实例.这样即使是启动类加载器中的代码也可以通过这种方式访问应用类加载器中的类了。

3、Dubbo的SPI和JDK的SPI有区别吗？有的话，究竟有什么区别？

Dubbo的扩展点加载是基于JDK标准的SPI扩展点发现机制增强而来的，Dubbo改进了JDK标准的SPI的以下问题：

JDK标准的SPI会一次性实例化扩展点所有实现，如果有扩展实现初始化很耗时，但如果没用上也加载，会很浪费资源。
增加了对扩展点IoC和AOP的支持，一个扩展点可以直接setter注入其它扩展点。
4、Dubbo中SPI也增加了IoC，先讲讲Spring的IoC，然后再讲讲Dubbo里面又是怎么做的
IOC：控制反转，是一种机制。IOC的实现方式有，依赖注入（DI）、工厂模式、服务定位器
DI的java标准化方式：JSR-330，仅提供DI的接口和注解，实现方式由IOC容器实现者具体定义
IOC的特点：松耦合、可测性、更强的内聚性、可重用的组件、更轻盈的代码

5、Dubbo中SPI也增加了AOP，那你讲讲这用到了什么设计模式，Dubbo又是如何做的.
AOP(Aspect Oriented Programming)：面向切面编程，通过预编译方式和运行期动态代理实现程序功能的统一维护的一种技术。AOP是OOP的延续，是软件开发中的一个热点，也是Spring框架中的一个重要内容，是函数式编程的一种衍生范型。利用AOP可以对业务逻辑的各个部分进行隔离，从而使得业务逻辑各部分之间的耦合度降低，提高程序的可重用性，同时提高了开发的效率。

4&5 详细参考：https://www.jianshu.com/p/189c8a0708be



dubbo选javassist作为缺省动态代理原因

https://blog.csdn.net/shaolong1013/article/details/103376300


Dubbo（二二）：动态代理（一）之 Javassist
https://msd.misuland.com/pd/3545776840385760682?page=1


