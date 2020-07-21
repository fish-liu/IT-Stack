
参考文章：

https://www.cnblogs.com/lgg20/p/12531170.html


Dubbo


一致性hash  ： https://www.cnblogs.com/xhj123/p/9087532.html

dubbo负载均衡策略 ： https://www.cnblogs.com/wyq178/p/9822731.html

------------------------------------


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








