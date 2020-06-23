
RabbitMQ的五种工作模式的简单实现

参考：https://www.cnblogs.com/pomelo-lemon/p/11440368.html
https://blog.csdn.net/qq_43243541/article/details/83476002
https://blog.csdn.net/sinat_38570489/article/details/90726808
--------------------------------------------

### RabbitMQ消息模型

RabbitMQ提供了6种消息模型，但是第6种其实是RPC，并不是MQ，因此不予学习。那么也就剩下5种。但是其实3、4、5这三种都属于订阅模型，只不过进行路由的方式不同。

![RabbitMQ消息模型](/images/messagetype-1.png)


### 代码工具类

ConnectionUtil

```java
package com.lemon.rabbitmq.utils;

import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

/**
 * rabbit mq 工具类 ： 获取连接
 */
public class ConnectionUtil {
    public static Connection getConnection() throws Exception {
        //创建连接工厂
        ConnectionFactory connectionFactory = new ConnectionFactory();

        //主机地址;默认为 localhost
        connectionFactory.setHost("127.0.0.1");

        //连接端口;默认为 5672
        connectionFactory.setPort(5672);

        //虚拟主机名称;默认为 /
        connectionFactory.setVirtualHost("/lemon");

        //连接用户名；默认为guest
        connectionFactory.setUsername("lemon");

        //连接密码；默认为guest
        connectionFactory.setPassword("lemon");

        //创建连接
        Connection connection = connectionFactory.newConnection();
        return connection;
    }
}
```

ConsumerUtil

```java
package cn.lemon.rabbitmq.utils;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

import java.io.IOException;

/**
 * 消费者工具类：生产消息消费者，方便调用
 */
public class ConsumerUtil {

    public static DefaultConsumer getConsumer(Channel channel) {

        DefaultConsumer consumer = new DefaultConsumer(channel) {
            /**
             * consumerTag 消费者标签，在channel.basicConsume时候可以指定
             * envelope 消息包的内容，可从中获取消息id，路由key，交换机等信息
             * properties 消息属性信息
             * body 消息内容
             */
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

                //消息id
                System.out.println("消息id:  " + envelope.getDeliveryTag());
                //交换机
                System.out.println("交换机:  " + envelope.getExchange());
                //路由key
                System.out.println("路由key: " + envelope.getRoutingKey());
                //接受到的消息
                System.out.println("收到的消息:  " + new String(body, "utf-8"));

                System.out.println("---------------------------------");

            }
        };

        return consumer;
    }
}
```


### 1. 基本消息类型

不使用Exchange交换机（默认交换机）  


#### simple简单模式：一个生产者发送消息到队列中由一个消费者接收。

![simple简单模式](/images/message-type-2.png)

- P：生产者，也就是要发送消息的程序
- C：消费者：消息的接受者，会一直等待消息到来。
- queue：消息队列，图中红色部分。类似一个邮箱，可以缓存消息；生产者向其中投递消息，消费者从其中取出消息。

```java
package cn.lemon.rabbitmq.simple;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

/*
    消息模式，简单模式: 一个生产者、一个消费者，不需要设置交换机
 */
public class Producer {

    public static final String QUEUE_NAME = "simple_queue";

    public static void main(String[] args) throws Exception {

        //1. 获取连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        /**
         * 3. 声明（创建）队列
         * 参数1：队列名称
         * 参数2：是否定义持久化队列
         * 参数3：是否独占本次连接
         * 参数4：是否在不使用的时候自动删除队列
         * 参数5：队列其它参数
         */
        channel.queueDeclare(QUEUE_NAME, true, false, false, null);

        //4. 发送消息
        String message = "你好，小兔子";
        /**
         * 参数1：交换机名称，如果没有指定则使用默认Default Exchange
         * 参数2：路由key,简单模式可以传递队列名称
         * 参数3：消息其它属性
         * 参数4：消息内容
         */
        channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
        System.out.println("已发送消息：" + message);

        // 5. 关闭资源
        channel.close();
        connection.close();
    }

}
```

```java
package cn.lemon.rabbitmq.simple;


import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

//消息消费者
public class Consumer {

    public static void main(String[] args) throws Exception {

        //1. 调用工具类，获取连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        //3. 声明队列   这里可以不用申明队列，因为生产者哪里已经创建了
        // channel.queueDeclare(Producer.QUEUE_NAME,true,false,false,null);

        //4. 调用工具类，获取消费者，消费队列中的消息
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        //监听消息
        /**
         * 参数1：队列名称
         * 参数2：是否自动确认，设置为true为表示消息接收到自动向mq回复接收到了，
         *       mq接收到回复会删除消息，设置为false则需要手动确认
         * 参数3：消息接收到后回调
         */
        channel.basicConsume(Producer.QUEUE_NAME, true, consumer);

        //不关闭资源，应该一直监听消息

    }

}
```

#### work工作队列模式：一个生产者发送消息到队列中可由多个消费者接收；多个消费者之间消息是竞争接收。 

![work工作队列模式](/images/message-type-3.png)

- P：生产者：任务的发布者
- C1：消费者，领取任务并且完成任务，假设完成速度较慢
- C2：消费者2：领取任务并完成任务，假设完成速度快
- queue：消息队列，图中红色部分。类似一个邮箱，可以缓存消息；生产者向其中投递消息，消费者从其中取出消息。

```java
package cn.lemon.rabbitmq.work;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

/*
    消息生产者 : 发送30个消息到队列

    创建两个消费者去监听同一个队列，查看两个消费者接收到的消息是否存在重复。
 */
public class Producer {

    public static final String QUEUE_NAME = "simple_queue";

    public static void main(String[] args) throws Exception {
        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();
        //2. 创建频道
        Channel channel = connection.createChannel();
        //3. 声明队列
        channel.queueDeclare(QUEUE_NAME, true, false, false, null);

        //4. 发送消息
        for (int i = 1; i <= 30; i++) {
            String message = "你好，小兔子! " + i;
            channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
            System.out.println("已发送消息: " + message);
        }
        //5. 关闭资源
        channel.close();
        connection.close();
    }

}
```

```java
package cn.itcast.rabbitmq.work;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;


//消息消费者
public class Consumer1 {
    
    public static void main(String[] args) throws Exception {
        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        //3. 声明队列  队列已经存在，可以不用创建
        //channel.queueDeclare(Producer.QUEUE_NAME,true,false,false,null);

        //4. 创建消息消费者
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        //监听消息
        /**
         * 参数1：队列名称
         * 参数2：是否自动确认，设置为true为表示消息接收到自动向mq回复接收到了，
         *       mq接收到回复会删除消息，设置为false则需要手动确认
         * 参数3：消息接收到后回调
         */
        channel.basicConsume(Producer.QUEUE_NAME, true, consumer);

        //不关闭资源，应该一直监听消息
        
    }

}
```

```java
package cn.lemon.rabbitmq.work;


import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

//消息消费者
public class Consumer2 {

    public static void main(String[] args) throws Exception {

        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        //3. 声明队列 队列已经存在，不用在创建
        //channel.queueDeclare(Producer.QUEUE_NAME,true,false,false,null);

        //4. 创建消息消费者
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        //监听消息
        channel.basicConsume(Producer.QUEUE_NAME, true, consumer);

        //不关闭资源，应该一直监听消息


    }

}
```

### 2. 订阅模型分类

使用Exchange交换机,订阅模式（广播fanout，定向direct，通配符topic） 

#### 发布与订阅模式：使用了fanout类型的交换机，可以将一个消息发送到所有与交换机绑定的队列并被消费者接收。　

![fanout类型](/images/message-type-4.png)

- P：生产者，也就是要发送消息的程序，但是不再发送到队列中，而是发给X（交换机）
- C：消费者，消息的接受者，会一直等待消息到来。
- Queue：消息队列，接收消息、缓存消息。
- Exchange：交换机，图中的X。

1） 可以有多个消费者
2） 每个消费者有自己的queue（队列）
3） 每个队列都要绑定到Exchange（交换机）
4） 生产者发送的消息，只能发送到交换机，交换机来决定要发给哪个队列，生产者无法决定。
5） 交换机把消息发送给绑定过的所有队列
6） 队列的消费者都能拿到消息。实现一条消息被多个消费者消费


```java
package cn.lemon.rabbitmq.ps;


import cn.lemon.rabbitmq.utils.ConnectionUtil;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;


/*
    消息生产者：发布订阅模式
    发布订阅模式Publish/subscribe
        1.需要设置类型为fanout的交换机
        2.并且交换机和队列进行绑定，当发送消息到交换机后，交换机会将消息发送到绑定的队列
 */
public class Producer {

    // 交换机名称
    public static final String FANOUT_EXCHANGE = "fanout_exchange";
    // 队列名称1
    public static final String FANOUT_QUEUE_1 = "fanout_queue_1";
    // 队列名称2
    public static final String FANOUT_QUEUE_2 = "fanout_queue_2";

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();
        // 2.创建频道
        Channel channel = connection.createChannel();

        /**
         * 3.声明交换机
         * 参数1：交换机名称
         * 参数2：交换机类型：fanout、direct、topic、headers
         */
        channel.exchangeDeclare(FANOUT_EXCHANGE, BuiltinExchangeType.FANOUT);

        /**
         * 4.声明（创建）队列
         * 参数1：队列名称
         * 参数2：是否定义持久化队列
         * 参数3：是否独占本次连接
         * 参数4：是否在不使用的时候自动删除队列
         * 参数5：队列其它参数
         */
        channel.queueDeclare(FANOUT_QUEUE_1, true, false, false, null);
        channel.queueDeclare(FANOUT_QUEUE_2, true, false, false, null);

        // 5.队列绑定交换机
        channel.queueBind(FANOUT_QUEUE_1, FANOUT_EXCHANGE, "");
        channel.queueBind(FANOUT_QUEUE_2, FANOUT_EXCHANGE, "");

        // 6. 发送多个消息
        for (int i = 1; i <= 10; i++) {
            // 要发送的信息
            String message = "你好；小兔子！" + i;
            /**
             * 参数1：交换机名称，如果没有指定则使用默认Default Exchage
             * 参数2：路由key,简单模式可以传递队列名称
             * 参数3：消息其它属性
             * 参数4：消息内容
             */
            channel.basicPublish(FANOUT_EXCHANGE, "", null, message.getBytes());
            System.out.println("已发送消息：" + message);
        }
        // 7. 关闭资源
        channel.close();
        connection.close();

    }


}
```

```java
package cn.lemon.rabbitmq.ps;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

/**
 * 消息的消费者，通过设置监听自动获取队列中的消息，实现消费
 */
public class Consumer1 {

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();

        // 2.创建频道
        Channel channel = connection.createChannel();

        // 3.申明(创建)交换机
        // 队列绑定到交换机，只要在生产者绑定，消费者可以不用再绑定
        //channel.exchangeDeclare(Producer.FANOUT_EXCHANGE,BuiltinExchangeType.FANOUT);

        // 4.声明（创建）队列
        //channel.queueDeclare(Producer.FANOUT_QUEUE_1, true, false, false, null);

        // 5.队列绑定到交换机
        //channel.queueBind(Producer.FANOUT_QUEUE_1,Producer.FANOUT_EXCHANGE,"");

        // 6.创建消费者；并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.FANOUT_QUEUE_1, true, consumer);
    }
}
```

```java
package cn.lemon.rabbitmq.ps;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

/**
 * 消息的消费者，通过设置监听自动获取队列中的消息，实现消费
 */
public class Consumer2 {

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();

        // 2.创建频道
        Channel channel = connection.createChannel();

        // 3.创建交换机
        channel.exchangeDeclare(Producer.FANOUT_EXCHANGE,BuiltinExchangeType.FANOUT);

        // 4.声明（创建）队列
        channel.queueDeclare(Producer.FANOUT_QUEUE_2, true, false, false, null);

        // 5.队列绑定到交换机
        channel.queueBind(Producer.FANOUT_QUEUE_2,Producer.FANOUT_EXCHANGE,"");

        // 6.创建消费者；并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.FANOUT_QUEUE_2, true, consumer);
    }
}

```

#### b. 路由模式：使用了direct类型的交换机，可以将一个消息发送到routing key相关的队列并被消费者接收。

![direct类型](/images/message-type-5.png)

- P：生产者，向Exchange发送消息，发送消息时，会指定一个routing key。

- X：Exchange（交换机），接收生产者的消息，然后把消息递交给 与routing key完全匹配的队列

- C1：消费者，其所在队列指定了需要routing key 为 error 的消息

- C2：消费者，其所在队列指定了需要routing key 为 info、error、warning 的消息

在Direct模型下：

- 队列与交换机的绑定，不能是任意绑定了，而是要指定一个RoutingKey（路由key）

- 消息的发送方在 向 Exchange发送消息时，也必须指定消息的 RoutingKey。

- Exchange不再把消息交给每一个绑定的队列，而是根据消息的Routing Key进行判断，只有队列的Routingkey与消息的 Routing key完全一致，才会接收到消息


```java
package cn.lemon.rabbitmq.routing;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

/*
    路由消息生产者：消息发送到交换机
    生产者发送两个消息（路由key分别为：insert、update）
    创建两个消费者，分别绑定的队列中路由为（insert，update）
 */
public class Producer {

    //交换机名
    public static final String DIRECT_EXCHANGE = "direct_exchange";
    //队列名
    public static final String DIRECT_QUEUE_INSERT = "direct_queue_insert";
    public static final String DIRECT_QUEUE_UPDATE = "direct_queue_update";

    public static void main(String[] args) throws Exception {
        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();
        //2. 创建频道
        Channel channel = connection.createChannel();
        /**
         * 3.声明交换机
         * 参数1：交换机名称
         * 参数2：交换机类型：fanout、direct、topic、headers
         */
        channel.exchangeDeclare(DIRECT_EXCHANGE, BuiltinExchangeType.DIRECT);
        /**
         * 4.声明（创建）队列
         * 参数1：队列名称
         * 参数2：是否定义持久化队列
         * 参数3：是否独占本次连接
         * 参数4：是否在不使用的时候自动删除队列
         * 参数5：队列其它参数
         */
        channel.queueDeclare(DIRECT_QUEUE_INSERT, true, false, false, null);
        channel.queueDeclare(DIRECT_QUEUE_UPDATE, true, false, false, null);

        /**
         * 5.队列绑定交换机
         * 参数1：队列名
         * 参数2：交换机名
         * 参数3：路由key
         */
        channel.queueBind(DIRECT_QUEUE_INSERT, DIRECT_EXCHANGE, "insert");
        channel.queueBind(DIRECT_QUEUE_UPDATE, DIRECT_EXCHANGE, "update");

        // 6.发送消息
        String message = "新增了商品，路由模式；routing key 为 insert ";
        channel.basicPublish(DIRECT_EXCHANGE, "insert", null, message.getBytes());
        System.out.println("已发送消息：" + message);

        message = "修改了商品，路由模式；routing key 为 update ";
        channel.basicPublish(DIRECT_EXCHANGE, "update", null, message.getBytes());
        System.out.println("已发送消息：" + message);

        // 7.关闭资源
        channel.close();
        connection.close();
    }

}
```

```java
package cn.lemon.rabbitmq.routing;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

/**
 * 消息消费者: 消费队列中的消息
 * 消息路由为insert
 */
public class Consumer1 {

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();

        // 2.创建频道
        Channel channel = connection.createChannel();

        // 3.创建交换机  生产者已经创建了，可以不用在创建
        //channel.exchangeDeclare(Producer.DIRECT_EXCHANGE,BuiltinExchangeType.DIRECT);

        // 4.声明（创建）队列
        channel.queueDeclare(Producer.DIRECT_QUEUE_INSERT, true, false, false, null);

        // 5.队列绑定到交换机
        channel.queueBind(Producer.DIRECT_QUEUE_INSERT, Producer.DIRECT_EXCHANGE, "insert");

        // 6.创建消费者,并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.DIRECT_QUEUE_INSERT, true, consumer);
    }
}
```

```java
package cn.lemon.rabbitmq.routing;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

/**
 * 消息消费者: 消费队列中的消息
 * 消息路由为update
 */
public class Consumer2 {

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();

        // 2.创建频道
        Channel channel = connection.createChannel();

        // 3.创建交换机
        channel.exchangeDeclare(Producer.DIRECT_EXCHANGE, BuiltinExchangeType.DIRECT);

        // 4.声明（创建）队列
        channel.queueDeclare(Producer.DIRECT_QUEUE_UPDATE, true, false, false, null);

        // 5.队列绑定到交换机
        channel.queueBind(Producer.DIRECT_QUEUE_UPDATE, Producer.DIRECT_EXCHANGE, "update");

        // 6.创建消费者；并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.DIRECT_QUEUE_UPDATE, true, consumer);
    }
}
```

#### c. 通配符模式：使用了topic类型的交换机，可以将一个消息发送到routing key（*,#）相关的队列并被消费者接收。

![topic类型](/images/message-type-6.png)

- P：生产者，向Exchange发送消息，发送消息时，会指定一个routing key。
- X：Exchange（交换机），接收生产者的消息，然后把消息递交给 与routing key完全匹配的队列
- C1：消费者，其所在队列指定了需要routing key 为 error 的消息
- C2：消费者，其所在队列指定了需要routing key 为 info、error、warning 的消息

Topic类型的Exchange与Direct相比，都是可以根据RoutingKey把消息路由到不同的队列。只不过Topic类型Exchange可以让队列在绑定Routing key 的时候使用通配符！Topic类型的Routingkey 一般都是有一个或多个单词组成，多个单词之间以”.”分割，例如： item.insert

通配符规则：

`#：匹配一个或多个词，比如：audit.#：能够匹配audit.irs.corporate 或者 audit.irs`

`*：匹配不多不少恰好1个词，比如：audit.*：只能匹配audit.irs`

```java
package cn.lemon.rabbitmq.topic;


import cn.lemon.rabbitmq.utils.ConnectionUtil;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

/**
 * Topic通配符模型消息生产者：消息发送到交换机
 * 生产者：发送包含有item.insert，item.update，item.delete的3种路由key的消息
 * RoutingKey  一般都是有一个或多个单词组成，多个单词之间以”.”分割
 * 通配符规则：
 * # 匹配一个或多个词
 * * 匹配一个词
 */
public class Producer {

    // 交换机名称
    public static final String TOPIC_EXCHANGE = "topic_exchange";
    // 队列名称
    public static final String TOPIC_QUEUE_1 = "topic_queue_1";
    // 队列名称
    public static final String TOPIC_QUEUE_2 = "topic_queue_2";

    public static void main(String[] args) throws Exception {
        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        //3. 声明交换机  参数1(交换机名) 参数2(交换机类型)
        channel.exchangeDeclare(TOPIC_EXCHANGE, BuiltinExchangeType.TOPIC);

        //4. 声明队列  消费者已经声明，生产者可以不用声明
        //channel.queueDeclare(TOPIC_QUEUE_1, true, false, false, null);

        // 5.队列绑定到交换机  消费者已经绑定，生产者不用绑定
        //channel.queueBind(Producer.TOPIC_QUEUE_1, Producer.TOPIC_EXCHANGE,"item.*");

        //5.发送消息
        String message = "新增了商品，Topic模式，路由key为item.insert";
        channel.basicPublish(TOPIC_EXCHANGE, "item.insert", null, message.getBytes());
        System.out.println("已发送消息：" + message);

        message = "修改了商品，Topic模式，路由key为item.update";
        channel.basicPublish(TOPIC_EXCHANGE, "item.update", null, message.getBytes());
        System.out.println("已发送消息：" + message);

        message = "删除了商品，Topic模式，路由key为item.delete";
        channel.basicPublish(TOPIC_EXCHANGE, "item.delete", null, message.getBytes());
        System.out.println("已发送消息：" + message);

        // 6.关闭资源
        channel.close();
        connection.close();
    }

}
```

```java
package cn.lemon.rabbitmq.topic;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

public class Consumer1 {

    public static void main(String[] args) throws Exception {
        //1. 创建连接
        Connection connection = ConnectionUtil.getConnection();

        //2. 创建频道
        Channel channel = connection.createChannel();

        //3. 声明交换机  参数1(交换机名) 参数2(交换机类型)
        //channel.exchangeDeclare(Producer.TOPIC_EXCHANGE, BuiltinExchangeType.TOPIC);

        //4. 声明队列  生产者已经创建了，消费者可以不用创建
        channel.queueDeclare(Producer.TOPIC_QUEUE_1, true, false, false, null);

        // 5.队列绑定到交换机
        channel.queueBind(Producer.TOPIC_QUEUE_1, Producer.TOPIC_EXCHANGE, "item.*");

        // 6.创建消费者；并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.TOPIC_QUEUE_1, true, consumer);

    }
}
```

```java
package cn.lemon.rabbitmq.topic;

import cn.lemon.rabbitmq.utils.ConnectionUtil;
import cn.lemon.rabbitmq.utils.ConsumerUtil;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.DefaultConsumer;

/**
 * 消息消费者: 消费队列中的消息
 */
public class Consumer2 {

    public static void main(String[] args) throws Exception {
        // 1.创建连接
        Connection connection = ConnectionUtil.getConnection();

        // 2.创建频道
        Channel channel = connection.createChannel();

        // 3.创建交换机
        //channel.exchangeDeclare(Producer.TOPIC_EXCHANGE,BuiltinExchangeType.TOPIC);

        // 4.声明（创建）队列  消费者创建，生产者没有创建
        channel.queueDeclare(Producer.TOPIC_QUEUE_2, true, false, false, null);

        // 5.队列绑定到交换机
        channel.queueBind(Producer.TOPIC_QUEUE_2, Producer.TOPIC_EXCHANGE, "item.update");
        channel.queueBind(Producer.TOPIC_QUEUE_2, Producer.TOPIC_EXCHANGE, "item.delete");

        // 6.创建消费者；并设置消息处理
        DefaultConsumer consumer = ConsumerUtil.getConsumer(channel);

        // 7.监听消息
        channel.basicConsume(Producer.TOPIC_QUEUE_2, true, consumer);
    }
}
```




