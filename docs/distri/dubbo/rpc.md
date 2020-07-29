
<h2>领域模型详解</h2>

参考：[Dubbo 源码分析](https://www.jianshu.com/p/a50129d2c1ff)

--------------------------------------


在 Dubbo 的核心领域模型中：

- Protocol 是服务域，它是 Invoker 暴露和引用的主功能入口，它负责 Invoker 的生命周期管理。

- Invoker 是实体域，它是 Dubbo 的核心模型，其它模型都向它靠扰，或转换成它，它代表一个可执行体，可向它发起 invoke 调用，它有可能是一个本地的实现，也可能是一个远程的实现，也可能一个集群实现。

- Invocation 是会话域，它持有调用过程中的变量，比如方法名，参数等。

> 该部分的源码均在 dubbo-rpc-api 目录下


### Protocol

Dubbo支持协议的顶层接口,Protocol 是服务域，它是 Invoker 暴露和引用的主功能入口。它负责 Invoker 的生命周期管理。

> com.alibaba.dubbo.rpc.Protocol 

```java
/**
 * Protocol. (API/SPI, Singleton, ThreadSafe)
 *
 * Dubbo 支持RPC协议的 顶层接口
 */
@SPI("dubbo")
public interface Protocol {

    /**
     * Get default port when user doesn't config the port.
     *
     * 定义 默认端口
     *
     * @return default port
     */
    int getDefaultPort();

    /**
     * Export service for remote invocation: <br>
     * 1. Protocol should record request source address after receive a request:
     * RpcContext.getContext().setRemoteAddress();<br>
     * 2. export() must be idempotent, that is, there's no difference between invoking once and invoking twice when
     * export the same URL<br>
     * 3. Invoker instance is passed in by the framework, protocol needs not to care <br>
     *
     * 暴露远程调用服务：
     * 1. 协议在接受请求时，应该记录请求的来源地址：RpcContext.getContext().setRemoteAddress();<br>
     * 2. export（）必须是幂等的，也就是说，在暴露服务时，一次调用和两次调用时没有区别的，
     * 3.传入的Invoker实例由框架实现并传入，协议无需关心。
     *
     * @param <T>     Service type 服务的类型
     * @param invoker Service invoker 服务的执行体
     * @return exporter reference for exported service, useful for unexport the service later
     * @throws RpcException thrown when error occurs during export the service, for example: port is occupied
     */
    @Adaptive
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;

    /**
     * Refer a remote service: <br> 引用远程服务
     * 1. When user calls `invoke()` method of `Invoker` object which's returned from `refer()` call, the protocol
     * needs to correspondingly execute `invoke()` method of `Invoker` object <br>
     * 2. It's protocol's responsibility to implement `Invoker` which's returned from `refer()`. Generally speaking,
     * protocol sends remote request in the `Invoker` implementation. <br>
     * 3. When there's check=false set in URL, the implementation must not throw exception but try to recover when
     * connection fails.
     *
     * 引用远程服务：
     * 1. 当用户调用Refer（）所返回的Invoker对象的invoke（）方法时，协议需要相应地执行Invoker对象的Invoke（）方法
     * 2. 实现由`refer（）`返回的`Invoker`是协议的责任。一般来说，协议在`Invoker`实现中发送远程请求。
     * 3. 当url中设置了 check = false时，连接失败时不能抛出异常，且只能内部消化。
     *
     * @param <T>  Service type 服务的类型
     * @param type Service class 服务的 class对象
     * @param url  URL address for the remote service 远程服务的url地址
     * @return invoker service's local proxy 服务的本地代理
     * @throws RpcException when there's any error while connecting to the service provider 当连接服务提供方失败时，抛出该异常。
     */
    @Adaptive
    <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException;

    /**
     * Destroy protocol: <br>
     * 1. Cancel all services this protocol exports and refers <br>
     * 2. Release all occupied resources, for example: connection, port, etc. <br>
     * 3. Protocol can continue to export and refer new service even after it's destroyed.
     *
     * 销毁/释放协议：
     * 1. 取消该协议所有已经暴露和引用的服务。<br>
     * 2. 释放协议所占用的所有资源，比如：连接，端口等等。。
     * 3. 协议即使销毁后也可以继续暴露并引用新服务。
     */
    void destroy();

}
```

#### 类图

![protocol](/images/dubbo-protocol.webp)



### Invoker

Invoker 是实体域，它是 Dubbo 的核心模型，其它模型都向它靠扰，或转换成它。

它代表一个可执行体，可向它发起 invoke 调用，它有可能是一个本地的实现，也可能是一个远程的实现，也可能一个集群实现。


```java
public interface Invoker<T> extends Node {

    /**
     * get service interface.
     *
     * #getInterface() 获取Service接口
     *
     * @return service interface.
     */
    Class<T> getInterface();

    /**
     * invoke.
     * 调用方法
     *
     * @param invocation
     * @return result
     * @throws RpcException
     */
    Result invoke(Invocation invocation) throws RpcException;

}
```

#### 详解Invoker

在dubbo中，万物皆是Invoker，即便是Exporter也是由Invoker进化而成的

由于Invoker在Dubbo领域模型中非常重要的一个概念，很多设计思路都是向它靠拢。这一思想渗透在整个实现代码里。

下面简单的说明Invoker的两种实现：服务提供的invoker和服务消费的invoker

![Invoker](/images/dubbo-invoker2.webp)

结合Dubbo demo中的 消费和提供者代码来理解上图。

服务消费者代码：

```java
public class DemoClientAction {
    
    private DemoServer demoServer;

    public void setDemoServer(DemoServer demoServer) {
        this.demoServer = demoServer;
    }

    public void start() {
        String hello = demoServer.sayHello("world");
    }
}
```

上面代码中的 DemoService 就是上图中服务消费端的 Proxy，用户代码通过这个 Proxy 调用其对应的 Invoker，而该 Invoker 实现了真正的远程服务调用。

服务提供者代码：

```java
public class DemoServiceImpl implements DemoService {

    public String sayHello(String name) throws RemoteException {
        return "Hello " + name;
    }
}
```

上面这个类会被封装成为一个 AbstractProxyInvoker 实例，并新生成一个 Exporter 实例。这样当网络通讯层收到一个请求后，会找到对应的 Exporter 实例，并调用它所对应的 AbstractProxyInvoker 实例，从而真正调用了服务提供者的代码。

#### Invoker 类图

上文所提到的，在Dubbo中invoker是一个非常重要的概念，既可以理解为万物皆为Invoker。所以在Dubbo中的实现类非常多。

![Invoker](/images/dubbo-invoker-class.webp)


####  Invoker监听器

invoker监听器 : com.alibaba.dubbo.rpc.InvokerListener 

```java
/**
 * InvokerListener. (SPI, Singleton, ThreadSafe)
 * Invoker 监听器
 */
@SPI
public interface InvokerListener {

    /**
     * The invoker referred
     *
     * 当服务引用完成
     *
     * @param invoker
     * @throws RpcException
     * @see com.alibaba.dubbo.rpc.Protocol#refer(Class, com.alibaba.dubbo.common.URL)
     */
    void referred(Invoker<?> invoker) throws RpcException;

    /**
     * The invoker destroyed.
     *
     * 当服务销毁引用完成
     *
     * @param invoker
     * @see com.alibaba.dubbo.rpc.Invoker#destroy()
     */
    void destroyed(Invoker<?> invoker);

}
```

### Exporter

> com.alibaba.dubbo.rpc.Exporter

Exporter，Invoker 暴露服务在Protocol上的对象。

```java
/**
 * Exporter. (API/SPI, Prototype, ThreadSafe)
 *
 * 暴露服务的 顶层接口
 *
 * @see com.alibaba.dubbo.rpc.Protocol#export(Invoker)
 * @see com.alibaba.dubbo.rpc.ExporterListener
 * @see com.alibaba.dubbo.rpc.protocol.AbstractExporter
 */
public interface Exporter<T> {

    /**
     * get invoker.
     *
     * 获取对应的Invoker
     *
     * @return invoker
     */
    Invoker<T> getInvoker();

    /**
     * unexport.
     *
     * 取消 暴露
     * <p>
     * <code>
     * getInvoker().destroy();
     * </code>
     */
    void unexport();

}
```

#### 类图

![Exporter](/images/dubbo-exporter.webp)

#### Exporter 监听器

Exporter 监听器  com.alibaba.dubbo.rpc.ExporterListener

```java
/**
 * ExporterListener. (SPI, Singleton, ThreadSafe)
 */
@SPI
public interface ExporterListener {

    /**
     * The exporter exported.
     *
     * 当服务暴露完成
     *
     * @param exporter
     * @throws RpcException
     * @see com.alibaba.dubbo.rpc.Protocol#export(Invoker)
     */
    void exported(Exporter<?> exporter) throws RpcException;

    /**
     * The exporter unexported.
     *
     * 当服务取消暴露完成
     *
     * @param exporter
     * @throws RpcException
     * @see com.alibaba.dubbo.rpc.Exporter#unexport()
     */
    void unexported(Exporter<?> exporter);

}
```



### ProxyFactory

代理工厂类 

> com.alibaba.dubbo.rpc.ProxyFactory

```java
/**
 * ProxyFactory. (API/SPI, Singleton, ThreadSafe)
 */
@SPI("javassist")
public interface ProxyFactory {

    /**
     * create proxy.
     *
     * 创建Proxy，在引用服务调用。
     *
     * @param invoker
     * @return proxy
     */
    @Adaptive({Constants.PROXY_KEY})
    <T> T getProxy(Invoker<T> invoker) throws RpcException;

    /**
     * create proxy.
     *
     * @param invoker
     * @return proxy
     */
    @Adaptive({Constants.PROXY_KEY})
    <T> T getProxy(Invoker<T> invoker, boolean generic) throws RpcException;

    /**
     * create invoker.
     *
     * 创建Invoker，在暴露服务时调用。
     *
     * @param <T>
     * @param proxy Service对象
     * @param type  Service接口类型
     * @param url   Service对应的Dubbo URL
     * @return invoker
     */
    @Adaptive({Constants.PROXY_KEY})
    <T> Invoker<T> getInvoker(T proxy, Class<T> type, URL url) throws RpcException;
}
```

服务消费者消费一个服务的详细过程

![protocol](/images/dubbo-rpc-refer.webp)

首先 ReferenceConfig 类的 init 方法调用 Protocol 的 refer 方法生成 Invoker 实例(如上图中的红色部分)，这是服务消费的关键。接下来把 Invoker 转换为客户端需要的接口(如：HelloWorld)。

- 从图中我们可以看出，方法的 invoker 参数，通过 Protocol 将 Service接口 创建出 Invoker 。
- 通过创建 Service 的 Proxy ，实现我们在业务代理调用 Service 的方法时，透明的内部转换成调用 Invoker 的 #invoke(Invocation) 方法
- 服务提供者暴露服务的 主过程 如下图：

首先 ServiceConfig 类拿到对外提供服务的实际类 ref(如：HelloWorldImpl),然后通过 ProxyFactory 类的 getInvoker 方法使用 ref 生成一个 AbstractProxyInvoker 实例，到这一步就完成具体服务到 Invoker 的转化。接下来就是 Invoker 转换到 Exporter 的过程。

从图中我们可以看出，该方法创建的 Invoker ，下一步会提交给 Protocol ，从 Invoker 转换到 Exporter 。

**Dubbo 的实现**

Dubbo 协议的 Invoker 转为 Exporter 发生在 DubboProtocol 类的 export 方法，它主要是打开 socket 侦听服务，并接收客户端发来的各种请求，通讯细节由 Dubbo 自己实现。

**RMI 的实现**

RMI 协议的 Invoker 转为 Exporter 发生在 RmiProtocol类的 export 方法，它通过 Spring 或 Dubbo 或 JDK 来实现 RMI 服务，通讯细节这一块由 JDK 底层来实现，这就省了不少工作量。

#### 类图

![protocol](/images/dubbo-proxyfactory.webp)

从类图可以看出，Dubbo支持Javassist和JDK Proxy两种方式生成代理。


### Invocation

Invocation 是会话域，它持有调用过程中的变量，比如方法名，参数等。

```java
public interface Invocation {

    /**
     * get method name.
     *
     * 获取方法名
     * @return method name.
     * @serial
     */
    String getMethodName();

    /**
     * get parameter types.
     *
     * 获取方法参数类型数组
     * @return parameter types.
     * @serial
     */
    Class<?>[] getParameterTypes();

    /**
     * get arguments.
     *
     * 获取方法参数数组
     * @return arguments.
     * @serial
     */
    Object[] getArguments();

    /**
     * get attachments.
     *
     * 获取隐式参数相关
     * @return attachments.
     * @serial
     */
    Map<String, String> getAttachments();

    /**
     * get attachment by key.
     *
     * @return attachment value.
     * @serial
     */
    String getAttachment(String key);

    /**
     * get attachment by key with default value.
     *
     * @return attachment value.
     * @serial
     */
    String getAttachment(String key, String defaultValue);

    /**
     * get the invoker in current context.
     *
     * 在当前上下文中获取调用者 invoker
     *
     * 获取对应的invoker对象
     *
     * @return invoker.
     * @transient
     */
    Invoker<?> getInvoker();

}
```

#### 类图

![invocation](/images/dubbo-invocation.webp)

DecodeableRpcInvocation：是Dubbo协议独有的。


### Result

Result 是会话域，它持有调用过程中返回值，异常等。 

> com.alibaba.dubbo.rpc.Result

```java
public interface Result {

    /**
     * Get invoke result.
     * <p>
     * 获取返回值
     *
     * @return result. if no result return null.
     */
    Object getValue();

    /**
     * Get exception.
     * <p>
     * 获取返回的异常
     *
     * @return exception. if no exception return null.
     */
    Throwable getException();

    /**
     * Has exception.
     * <p>
     * 判断是否存在异常
     *
     * @return has exception.
     */
    boolean hasException();

    /**
     * Recreate.
     * <p>
     * <code>
     * if (hasException()) {
     * throw getException();
     * } else {
     * return getValue();
     * }
     * </code>
     * <p>
     * com.alibaba.dubbo.rpc.RpcResult
     * RpcResult 中针对recreate() 的实现。
     *
     * @return result.
     * @throws if has exception throw it.
     * @see RpcResult // 具体实现
     */
    Object recreate() throws Throwable;

    /**
     * @see com.alibaba.dubbo.rpc.Result#getValue()
     * @deprecated Replace to getValue()
     */
    @Deprecated
    Object getResult();

    /**
     * 下面的getAttachments等方法 都是获取但会的隐式参数相关。
     */

    /**
     * get attachments.
     *
     * @return attachments.
     */
    Map<String, String> getAttachments();

    /**
     * get attachment by key.
     *
     * @return attachment value.
     */
    String getAttachment(String key);

    /**
     * get attachment by key with default value.
     *
     * @return attachment value.
     */
    String getAttachment(String key, String defaultValue);

}
```

#### 类图

![result](/images/dubbo-result.webp)


### Filter

过滤器接口，和我们平时理解的 javax.servlet.Filter 基本一致。

> com.alibaba.dubbo.rpc.Filter

```java
/**
 * Filter. (SPI, Singleton, ThreadSafe)
 */
@SPI
public interface Filter {

    /**
     * do invoke filter.
     执行invoker的过滤逻辑。
     * <p>
     * <code>
     * // before filter 自己实现
     * Result result = invoker.invoke(invocation);
     * // after filter 自己实现
     * return result;
     * </code>
     *
     * @param invoker    service
     * @param invocation invocation.
     * @return invoke result.
     * @throws RpcException
     * @see com.alibaba.dubbo.rpc.Invoker#invoke(Invocation)
     */
    Result invoke(Invoker<?> invoker, Invocation invocation) throws RpcException;

}
```

#### 类图

![filter](/images/dubbo-filter.webp)

