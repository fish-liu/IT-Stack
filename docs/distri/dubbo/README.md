
参考文章：

https://www.cnblogs.com/lgg20/p/12531170.html


Dubbo


一致性hash  ： https://www.cnblogs.com/xhj123/p/9087532.html

dubbo负载均衡策略 ： https://www.cnblogs.com/wyq178/p/9822731.html

------------------------------------


**dubbo的源码分析基于 dubbo-2.6.4 版本， 2.7.5版本改动比较大，官方的文档还没更新。**



Dubbo :是一个RPC框架，SOA框架

Dubbo缺省协议采用单一长连接和NIO异步通讯，适合于小数据量大并发的服务调用，以及服务消费者机器数远大于服务提供者机器数的情况。

作为RPC：支持各种传输协议，如dubbo,hession,json,fastjson，底层采用mina,netty长连接进行传输！典型的provider和cusomer模式!
作为SOA：具有服务治理功能，提供服务的注册和发现！用zookeeper实现注册中心！启动时候服务端会把所有接口注册到注册中心，并且订阅configurators,服务消费端订阅provide，configurators,routers,订阅变更时，zk会推送providers,configuators，routers,启动时注册长连接，进行通讯！proveider和provider启动后，后台启动定时器，发送统计数据到monitor（监控中心）！提供各种容错机制和负载均衡策略！！

Dubbog工作原理

![Dubbo架构图](/images/dubbo.png)



调用流程

![Dubbo架构图](/images/dubbosample.png)

 1、client一个线程调用远程接口，生成一个唯一的ID（比如一段随机字符串，UUID等），Dubbo是使用AtomicLong从0开始累计数字的
 
 2、将打包的方法调用信息（如调用的接口名称，方法名称，参数值列表等），和处理结果的回调对象callback，全部封装在一起，组成一个对象object
 
 3、向专门存放调用信息的全局ConcurrentHashMap里面put(ID, object)
 
 4、将ID和打包的方法调用信息封装成一对象connRequest，使用IoSession.write(connRequest)异步发送出去

 5、当前线程再使用callback的get()方法试图获取远程返回的结果，在get()内部，则使用synchronized获取回调对象callback的锁， 再先检测是否已经获取到结果，如果没有，然后调用callback的wait()方法，释放callback上的锁，让当前线程处于等待状态。

 6、服务端接收到请求并处理后，将结果（此结果中包含了前面的ID，即回传）发送给客户端，客户端socket连接上专门监听消息的线程收到消息，分析结果，取到ID，再从前面的ConcurrentHashMap里面get(ID)，从而找到callback，将方法调用结果设置到callback对象里。

 7、监听线程接着使用synchronized获取回调对象callback的锁（因为前面调用过wait()，那个线程已释放callback的锁了），再notifyAll()，唤醒前面处于等待状态的线程继续执行（callback的get()方法继续执行就能拿到调用结果了），至此，整个过程结束。


<font color='red'> 当前线程怎么让它“暂停”，等结果回来后，再向后执行？</font>

答：先生成一个对象obj，在一个全局map里put(ID,obj)存放起来，再用synchronized获取obj锁，再调用obj.wait()让当前线程处于等待状态，然后另一消息监听线程等到服 务端结果来了后，再map.get(ID)找到obj，再用synchronized获取obj锁，再调用obj.notifyAll()唤醒前面处于等待状态的线程。

<font color='red'> 正如前面所说，Socket通信是一个全双工的方式，如果有多个线程同时进行远程方法调用，这时建立在client server之间的socket连接上会有很多双方发送的消息传递，前后顺序也可能是乱七八糟的，server处理完结果后，将结果消息发送给client，client收到很多消息，怎么知道哪个消息结果是原先哪个线程调用的？</font>

答：使用一个ID，让其唯一，然后传递给服务端，再服务端又回传回来，这样就知道结果是原先哪个线程的了。



### 服务暴露和消费的详细过程 

#### （1）服务提供者暴露一个服务的详细过程

服务提供者暴露服务的主过程：

![provider](/images/provider.png)

首先ServiceConfig类拿到对外提供服务的实际类ref(如：HelloWorldImpl),然后通过ProxyFactory类的getInvoker方法使用ref生成一个AbstractProxyInvoker实例，

到这一步就完成具体服务到Invoker的转化。接下来就是Invoker转换到Exporter的过程。

Dubbo处理服务暴露的关键就在Invoker转换到Exporter的过程(如上图中的红色部分)，下面我们以Dubbo和RMI这两种典型协议的实现来进行说明：

Dubbo的实现：

Dubbo协议的Invoker转为Exporter发生在DubboProtocol类的export方法，它主要是打开socket侦听服务，并接收客户端发来的各种请求，通讯细节由Dubbo自己实现。

RMI的实现：

RMI协议的Invoker转为Exporter发生在RmiProtocol类的export方法，
它通过Spring或Dubbo或JDK来实现RMI服务，通讯细节这一块由JDK底层来实现，这就省了不少工作量。




服务治理手段包括节点管理、负载均衡、服务路由、服务容错等，下面这张图给出了 Dubbo 框架服务治理的具体实现。

![dubbo](/images/dubbo-001.webp)

图中的 Invoker 是对服务提供者节点的抽象，Invoker 封装了服务提供者的地址以及接口信息。

～节点管理：Directory 负责从注册中心获取服务节点列表，并封装成多个 Invoker，可以把它看成“List<Invoker>” ，它的值可能是动态变化的，比如注册中心推送变更时需要更新。

～负载均衡：LoadBalance 负责从多个 Invoker 中选出某一个用于发起调用，选择时可以采用多种负载均衡算法，比如 Random、RoundRobin、LeastActive 等。

～服务路由：Router 负责从多个 Invoker 中按路由规则选出子集，比如读写分离、机房隔离等。

～服务容错：Cluster 将 Directory 中的多个 Invoker 伪装成一个 Invoker，对上层透明，伪装过程包含了容错逻辑，比如采用 Failover 策略的话，调用失败后，会选择另一个 Invoker，重试请求。



一次服务调用的流程

![dubbo](/images/dubbo-002.webp)





https://segmentfault.com/a/1190000012925521

<h2>Dubbo核心功能</h2>
<p>1、Remoting：远程通讯，提供对多种NIO框架抽象封装，包括“同步转异步”和“请求-响应”模式的信息交换方式。<br>2、Cluster：服务框架，提供基于接口方法的透明远程过程调用，包括多协议支持，以及软负载均衡，失败容错，地址路由，动态配置等集群支持。<br>3、Registry：服务注册，基于注册中心目录服务，使服务消费方能动态的查找服务提供方，使地址透明，使服务提供方可以平滑增加或减少机器。</p>
<h2>Dubbo组件角色</h2>
<p><span class="img-wrap"><img referrerpolicy="no-referrer" data-src="/img/bVbg2z5?w=639&amp;h=334" src="https://cdn.segmentfault.com/v-5f0a9217/global/img/squares.svg" alt="clipboard.png" title="clipboard.png"></span></p>
<p>Provider: 暴露服务的服务提供方。<br>Consumer: 调用远程服务的服务消费方。<br>Registry: 服务注册与发现的注册中心。<br>Monitor: 统计服务的调用次调和调用时间的监控中心。<br>Container: 服务运行容器，常见的容器有Spring容器。</p>
<p>调用关系说明：</p>
<ol>
<li>服务容器负责启动，加载，运行服务提供者。</li>
<li>服务提供者在启动时，向注册中心注册自己提供的服务。</li>
<li>服务消费者在启动时，向注册中心订阅自己所需的服务。</li>
<li>注册中心返回服务提供者地址列表给消费者，如果有变更，注册中心将基于长连接推送变更数据给消费者。</li>
<li>服务消费者，从提供者地址列表中，基于软负载均衡算法，选一台提供者进行调用，如果调用失败，再选另一台调用。</li>
<li>服务消费者和提供者，在内存中累计调用次数和调用时间，定时每分钟发送一次统计数据到监控中心Monitor。</li>
</ol>
<h2>Dubbo总体架构</h2>
<p>上面介绍给出的都是抽象层面的组件关系，可以说是纵向的以服务模型的组件分析，其实Dubbo最大的特点是按照分层的方式来架构，使用这种方式可以使各个层之间解耦合（或者最大限度地松耦合）。所以，我们横向以分层的方式来看下Dubbo的架构，如图所示：</p>
<p><span class="img-wrap"><img referrerpolicy="no-referrer" data-src="/img/bVbg2Be?w=1000&amp;h=752" src="https://cdn.segmentfault.com/v-5f0a9217/global/img/squares.svg" alt="clipboard.png" title="clipboard.png"></span><br>Dubbo框架设计一共划分了10个层，而最上面的Service层是留给实际想要使用Dubbo开发分布式服务的开发者实现业务逻辑的接口层。图中左边淡蓝背景的为服务消费方使用的接口，右边淡绿色背景的为服务提供方使用的接口， 位于中轴线上的为双方都用到的接口。</p>
<p>下面，结合Dubbo官方文档，我们分别理解一下框架分层架构中，各个层次的设计要点：</p>
<p>服务接口层（Service）：与实际业务逻辑相关的，根据服务提供方和服务消费方的 业务设计对应的接口和实现。<br>配置层（Config）：对外配置接口，以ServiceConfig和ReferenceConfig为中心，可以直接new配置类，也可以通过Spring解析配置生成配置类。<br>服务代理层（Proxy）：服务接口透明代理，生成服务的客户端Stub和服务器端Skeleton，以ServiceProxy为中心，扩展接口为ProxyFactory。<br>服务注册层（Registry）：封装服务地址的注册与发现，以服务URL为中心，扩展接口为RegistryFactory、Registry和RegistryService。可能没有服务注册中心，此时服务提供方直接暴露服务。<br>集群层（Cluster）：封装多个提供者的路由及负载均衡，并桥接注册中心，以Invoker为中心，扩展接口为Cluster、Directory、Router和LoadBalance。将多个服务提供方组合为一个服务提供方，实现对服务消费方来透明，只需要与一个服务提供方进行交互。<br>监控层（Monitor）：RPC调用次数和调用时间监控，以Statistics为中心，扩展接口为MonitorFactory、Monitor和MonitorService。<br>远程调用层（Protocol）：封将RPC调用，以Invocation和Result为中心，扩展接口为Protocol、Invoker和Exporter。Protocol是服务域，它是Invoker暴露和引用的主功能入口，它负责Invoker的生命周期管理。Invoker是实体域，它是Dubbo的核心模型，其它模型都向它靠扰，或转换成它，它代表一个可执行体，可向它发起invoke调用，它有可能是一个本地的实现，也可能是一个远程的实现，也可能一个集群实现。<br>信息交换层（Exchange）：封装请求响应模式，同步转异步，以Request和Response为中心，扩展接口为Exchanger、ExchangeChannel、ExchangeClient和ExchangeServer。<br>网络传输层（Transport）：抽象mina和netty为统一接口，以Message为中心，扩展接口为Channel、Transporter、Client、Server和Codec。<br>数据序列化层（Serialize）：可复用的一些工具，扩展接口为Serialization、 ObjectInput、ObjectOutput和ThreadPool。<br>从上图可以看出，Dubbo对于服务提供方和服务消费方，从框架的10层中分别提供了各自需要关心和扩展的接口，构建整个服务生态系统（服务提供方和服务消费方本身就是一个以服务为中心的）。</p>
<p><strong>根据官方提供的，对于上述各层之间关系的描述，如下所示：</strong><br>1、在RPC中，Protocol是核心层，也就是只要有Protocol + Invoker + Exporter就可以完成非透明的RPC调用，然后在Invoker的主过程上Filter拦截点。</p>
<p>2、图中的Consumer和Provider是抽象概念，只是想让看图者更直观的了解哪些分类属于客户端与服务器端，不用Client和Server的原因是Dubbo在很多场景下都使用Provider、Consumer、Registry、Monitor划分逻辑拓普节点，保持概念统一。</p>
<p>3、而Cluster是外围概念，所以Cluster的目的是将多个Invoker伪装成一个Invoker，这样其它人只要关注Protocol层Invoker即可，加上Cluster或者去掉Cluster对其它层都不会造成影响，因为只有一个提供者时，是不需要Cluster的。</p>
<p>4、Proxy层封装了所有接口的透明化代理，而在其它层都以Invoker为中心，只有到了暴露给用户使用时，才用Proxy将Invoker转成接口，或将接口实现转成Invoker，也就是去掉Proxy层RPC是可以Run的，只是不那么透明，不那么看起来像调本地服务一样调远程服务。<br>5、而Remoting实现是Dubbo协议的实现，如果你选择RMI协议，整个Remoting都不会用上，Remoting内部再划为Transport传输层和Exchange信息交换层，Transport层只负责单向消息传输，是对Mina、Netty、Grizzly的抽象，它也可以扩展UDP传输，而Exchange层是在传输层之上封装了Request-Response语义。</p>
<p>6、Registry和Monitor实际上不算一层，而是一个独立的节点，只是为了全局概览，用层的方式画在一起。</p>
<h2>服务调用流程</h2>
<p><span class="img-wrap"><img referrerpolicy="no-referrer" data-src="/img/bVbg2Da?w=800&amp;h=738" src="https://cdn.segmentfault.com/v-5f0a9217/global/img/squares.svg" alt="clipboard.png" title="clipboard.png"></span></p>




#### （2）服务消费者消费一个服务的详细过程

服务消费的主过程：

![consumer](/images/consumer.png)

首先ReferenceConfig类的init方法调用Protocol的refer方法生成Invoker实例(如上图中的红色部分)，这是服务消费的关键。

接下来把Invoker转换为客户端需要的接口(如：HelloWorld)。


Dubbo可扩展机制实战
http://dubbo.apache.org/zh-cn/blog/introduction-to-dubbo-spi.html


Dubbo篇之(一)：实现原理及架构详解
http://crazyfzw.github.io/2018/06/10/dubbo-architecture/


https://www.jianshu.com/p/292fcdcfe41e


dubbo系列
https://manzhizhen.iteye.com/category/353261








