
<h2>dubbo的一些默认变量</h2>

参考文章：[dubbo的一些默认变量](https://blog.csdn.net/u013076044/article/details/78261656)

------------------------------------

dubbo默认变量表

| 变量名 | 描述 | 默认值 | 用途 |
|---|---|---|---|
| DEFAULT_IO_THREADS | 默认IO线程 | Math.min(Runtime.getRuntime().availableProcessors() + 1, 32) | 创建NettyServer和MinaServer时 |
| DEFAULT_PROXY | 默认代理， | javassist | 通过生成字节码代替反射 |
| DEFAULT_PAYLOAD | 默认最大数据大小 | 	8 * 1024 * 1024/8M | 在从通道获取数据进行编码时判断大小 |
| DEFAULT_CLUSTER | 默认集群容错方案 | failover |  |	
| DEFAULT_DIRECTORY | 默认集群目录服务 | dubbo	 | |
| DEFAULT_LOADBALANCE | 默认负载均衡方案 | random（随机） |  |
| DEFAULT_PROTOCOL | 默认协议 | dubbo	 | |
| DEFAULT_EXCHANGER | 默认信息交换方式 | header |  | 
| DEFAULT_TRANSPORTER | 默认传输方式 | netty(netty3)	|   |
| DEFAULT_REMOTING_SERVER | 默认远程客户端 | netty(netty3)	 |   |
| DEFAULT_REMOTING_CODEC | 默认协议编码 | dubbo |  |	
| DEFAULT_REMOTING_SERIALIZATION | 默认远程调用序列化方案 | hessian2 |  |	
| DEFAULT_HTTP_CLIENT | protocol为hession时的默认客户端类型 | jdk |  | 
| DEFAULT_HTTP_SERIALIZATION | http类型默认序列化方案 | json |   |
| DEFAULT_CHARSET | 默认字符集 | UTF-8 |  |	
| DEFAULT_WEIGHT | 服务默认权重 | 1000 |   |	
| DEFAULT_FORKS | 默认并行请求数 | 2 |   |
| DEFAULT_THREAD_NAME | 默认线程名 | Dubbo |  |	
| DEFAULT_CORE_THREADS | 默认核心线程数 | 0 |  |
| DEFAULT_THREADS | 线程池默认线程数 | 200	|  |
| DEFAULT_QUEUES | 默认队列数 | 0	 |  |
| DEFAULT_IDLE_TIMEOUT | 默认空闲时间 | 600 * 1000(10分钟) |   |	
| DEFAULT_ALIVE | 连接默认存活时间 | 60 * 1000（1分钟） |  |	
| DEFAULT_CONNECTIONS| 默认连接 | 0 |  |
| DEFAULT_ACCEPTS | 默认接收 | 0 |  |	
| DEFAULT_HEARTBEAT | 默认心跳时间 | 60 * 1000（1分钟）	 |
| DEFAULT_TIMEOUT | 请求执行默认超时时间 | 	1s |  |
| DEFAULT_CONNECT_TIMEOUT | 连接默认超时时间 | 3s |  |	
| DEFAULT_RETRIES | 默认重试次数 | 2	|  |
| DEFAULT_BUFFER_SIZE | 默认缓冲区大小 | 8 * 1024（8K） |  |



