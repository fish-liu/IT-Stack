
zookeeper 实现分布式锁

参考文章：

[漫画：如何用Zookeeper实现分布式锁？](https://mp.weixin.qq.com/s/u8QDlrDj3Rl1YjY4TyKMCA)

https://blog.csdn.net/kongmin_123/article/details/82081953

https://blog.csdn.net/crazymakercircle/article/details/85956246

https://blog.csdn.net/hongtaolong/article/details/88898875



技术要点：

- zk的 有序临时节点

- Zookeeper节点的递增性，可以规定节点编号最小的那个获得锁。

- Zookeeper的节点监听机制，可以保障占有锁的方式有序而且高效。

------------------------------------------

### Zookeeper 相关知识点

让我们来回顾一下Zookeeper节点的概念：

![ZooKeeper节点](/images/zknode.png)

Zookeeper的数据存储结构就像一棵树，这棵树由节点组成，这种节点叫做Znode。


#### Znode分为四种类型：

1.持久节点 （PERSISTENT）

默认的节点类型。创建节点的客户端与zookeeper断开连接后，该节点依旧存在 。

2.持久节点顺序节点（PERSISTENT_SEQUENTIAL）

所谓顺序节点，就是在创建节点时，Zookeeper根据创建的时间顺序给该节点名称进行编号：

![ZooKeeper节点](/images/zknode1.png)

3.临时节点（EPHEMERAL） 

和持久节点相反，当创建节点的客户端与zookeeper断开连接后，临时节点会被删除。

![ZooKeeper节点](/images/zknode2.png)
![ZooKeeper节点](/images/zknode3.png)
![ZooKeeper节点](/images/zknode4.png)

4.临时顺序节点（EPHEMERAL_SEQUENTIAL） 
顾名思义，临时顺序节点结合和临时节点和顺序节点的特点：在创建节点时，Zookeeper根据创建的时间顺序给该节点名称进行编号；当创建节点的客户端与Zookeeper断开连接后，临时节点会被删除。


那临时顺序节点和Zookeeper的分布式锁有什么关系呢？


### Zookeeper 分布式锁的原理

Zookeeper分布式锁恰恰应用了临时顺序节点。


- 首先，Zookeeper的每一个节点，都是一个天然的顺序发号器。

在每一个节点下面创建子节点时，只要选择的创建类型是有序（EPHEMERAL_SEQUENTIAL 临时有序或者PERSISTENT_SEQUENTIAL 永久有序）类型，那么，新的子节点后面，会加上一个次序编号。这个次序编号，是上一个生成的次序编号加一

比如，创建一个用于发号的节点“/test/lock”，然后以他为父亲节点，可以在这个父节点下面创建相同前缀的子节点，假定相同的前缀为“/test/lock/seq-”，在创建子节点时，同时指明是有序类型。如果是第一个创建的子节点，那么生成的子节点为/test/lock/seq-0000000000，下一个节点则为/test/lock/seq-0000000001，依次类推，等等。

![ZooKeeper节点](/images/zklockseq.jpg)

- 其次，Zookeeper节点的递增性，可以规定节点编号最小的那个获得锁。

一个zookeeper分布式锁，首先需要创建一个父节点，尽量是持久节点（PERSISTENT类型），然后每个要获得锁的线程都会在这个节点下创建个临时顺序节点，由于序号的递增性，可以规定排号最小的那个获得锁。所以，每个线程在尝试占用锁之前，首先判断自己是排号是不是当前最小，如果是，则获取锁。

- 第三，Zookeeper的节点监听机制，可以保障占有锁的方式有序而且高效。

每个线程抢占锁之前，先抢号创建自己的ZNode。同样，释放锁的时候，就需要删除抢号的Znode。抢号成功后，如果不是排号最小的节点，就处于等待通知的状态。等谁的通知呢？不需要其他人，只需要等前一个Znode 的通知就可以了。当前一个Znode 删除的时候，就是轮到了自己占有锁的时候。第一个通知第二个、第二个通知第三个，击鼓传花似的依次向后。

- Zookeeper的节点监听机制，可以说能够非常完美的，实现这种击鼓传花似的信息传递。具体的方法是，每一个等通知的Znode节点，只需要监听linsten或者 watch 监视排号在自己前面那个，而且紧挨在自己前面的那个节点。 只要上一个节点被删除了，就进行再一次判断，看看自己是不是序号最小的那个节点，如果是，则获得锁。


**为什么说Zookeeper的节点监听机制，可以说是非常完美呢？**

- 1、一条龙式的首尾相接，后面监视前面，就不怕中间截断吗？比如，在分布式环境下，由于网络的原因，或者服务器挂了或则其他的原因，如果前面的那个节点没能被程序删除成功，后面的节点不就永远等待么？

其实，Zookeeper的内部机制，能保证后面的节点能够正常的监听到删除和获得锁。在创建取号节点的时候，尽量创建临时znode 节点而不是永久znode 节点，一旦这个 znode 的客户端与Zookeeper集群服务器失去联系，这个临时 znode 也将自动删除。排在它后面的那个节点，也能收到删除事件，从而获得锁。

- 2、说Zookeeper的节点监听机制，是非常完美的。还有一个原因。

Zookeeper这种首尾相接，后面监听前面的方式，可以**避免羊群效应**。所谓羊群效应就是每个节点挂掉，所有节点都去监听，然后做出反映，这样会给服务器带来巨大压力，所以有了临时顺序节点，当一个节点挂掉，只有它后面的那一个节点才做出反映。


#### 获取锁

- 首先，在Zookeeper当中创建一个持久节点ParentLock。当第一个客户端想要获得锁时，需要在ParentLock这个节点下面创建一个临时顺序节点 Lock1。

![ZooKeeper节点](/images/zklockget1.png)

- 之后，Client1查找ParentLock下面所有的临时顺序节点并排序，判断自己所创建的节点Lock1是不是顺序最靠前的一个。如果是第一个节点，则成功获得锁。 

![ZooKeeper节点](/images/zklockget2.png)

- 这时候，如果再有一个客户端 Client2 前来获取锁，则在ParentLock下载再创建一个临时顺序节点Lock2。 

![ZooKeeper节点](/images/zklockget3.png)

Client2查找ParentLock下面所有的临时顺序节点并排序，判断自己所创建的节点Lock2是不是顺序最靠前的一个，结果发现节点Lock2并不是最小的。

- 于是，Client2向排序仅比它靠前的节点Lock1注册Watcher，用于监听Lock1节点是否存在。这意味着Client2抢锁失败，进入了等待状态。 

![ZooKeeper节点](/images/zklockget4.png)

- 这时候，如果又有一个客户端Client3前来获取锁，则在ParentLock下载再创建一个临时顺序节点Lock3。 

![ZooKeeper节点](/images/zklockget5.png)

Client3查找ParentLock下面所有的临时顺序节点并排序，判断自己所创建的节点Lock3是不是顺序最靠前的一个，结果同样发现节点Lock3并不是最小的。

- 于是，Client3向排序仅比它靠前的节点Lock2注册Watcher，用于监听Lock2节点是否存在。这意味着Client3同样抢锁失败，进入了等待状态。

![ZooKeeper节点](/images/zklockget6.png)

这样一来，Client1得到了锁，Client2监听了Lock1，Client3监听了Lock2。这恰恰形成了一个等待队列，很像是Java当中ReentrantLock所依赖的AQS（AbstractQueuedSynchronizer）。


#### 释放锁

释放锁分为两种情况：

##### 1.任务完成，客户端显示释放

当任务完成时，Client1会显示调用删除节点Lock1的指令。

![ZooKeeper节点](/images/zklockremove1.png)


##### 2.任务执行过程中，客户端崩溃

- 获得锁的Client1在任务执行过程中，如果Duang的一声崩溃，则会断开与Zookeeper服务端的链接。根据临时节点的特性，相关联的节点Lock1会随之自动删除。

![ZooKeeper节点](/images/zklockremove2.png)

- 由于Client2一直监听着Lock1的存在状态，当Lock1节点被删除，Client2会立刻收到通知。这时候Client2会再次查询ParentLock下面的所有节点，确认自己创建的节点Lock2是不是目前最小的节点。如果是最小，则Client2顺理成章获得了锁。 

![ZooKeeper节点](/images/zklockremove3.png)

- 同理，如果Client2也因为任务完成或者节点崩溃而删除了节点Lock2，那么Client3就会接到通知。 

![ZooKeeper节点](/images/zklockremove4.png)

- 最终，Client3成功得到了锁。

![ZooKeeper节点](/images/zklockremove5.png)


### Zookeeper实现分布式锁


首先定义了一个锁的接口，很简单，一个加锁方法，一个解锁方法。

```
/**
 * create by 
 **/
public interface Lock {

    boolean lock() throws Exception;

    boolean unlock();
}
```

使用zookeeper实现分布式锁的算法流程，大致如下：

（1）如果锁空间的根节点不存在，首先创建Znode根节点。这里假设为“/test/lock”。这个根节点，代表了一把分布式锁。

（2）客户端如果需要占用锁，则在“/test/lock”下创建临时的且有序的子节点。

这里，尽量使一个有意义的子节点前缀，比如“/test/lock/seq-”。则第一个客户端对应的子节点为“/test/lock/seq-000000000”，第二个为 “/test/lock/seq-000000001”，以此类推。

如果前缀为“/test/lock/”，则第一个客户端对应的子节点为“/test/lock/000000000”，第二个为 “/test/lock/000000001” ，以此类推，也非常直观。

（3）客户端如果需要占用锁，还需要判断，判断自己创建的子节点是否为当前子节点列表中序号最小的子节点。如果是则认为获得锁，否则监听前一个Znode子节点变更消息，获得子节点变更通知后重复此步骤直至获得锁；

（4）获取锁后，开始处理业务流程。完成业务流程后，删除对应的子节点，完成释放锁的工作。以便后面的节点获得分布式锁。


加锁的实现

lock方法的具体算法是，首先尝试着去加锁，如果加锁失败就去等待，然后再重复。

```
@Override
public boolean lock() {

   try {
        boolean locked = false;

        locked = tryLock();

        if (locked) {
            return true;
        }
        while (!locked) {

            await();


            if (checkLocked()) {
                locked=true;
            }
        }
        return true;
    } catch (Exception e) {
        e.printStackTrace();
        unlock();
    }

    return false;
}
```

尝试加锁的tryLock方法是关键。做了两件重要的事情：

（1）创建临时顺序节点，并且保存自己的节点路径

（2）判断是否是第一个，如果是第一个，则加锁成功。如果不是，就找到前一个Znode节点，并且保存其路径到prior_path。

tryLock方法代码节选如下：
```
private boolean tryLock() throws Exception {
        //创建临时Znode
        List<String> waiters = getWaiters();
        locked_path = ZKclient.instance
                .createEphemeralSeqNode(LOCK_PREFIX);
        if (null == locked_path) {
            throw new Exception("zk error");
        }
        locked_short_path = getShorPath(locked_path);

        //获取等待的子节点列表，判断自己是否第一个
        if (checkLocked()) {
            return true;
        }

        // 判断自己排第几个
        int index = Collections.binarySearch(waiters, locked_short_path);
        if (index < 0) { // 网络抖动，获取到的子节点列表里可能已经没有自己了
            throw new Exception("节点没有找到: " + locked_short_path);
        }

        //如果自己没有获得锁，则要监听前一个节点
        prior_path = ZK_PATH + "/" + waiters.get(index - 1);

        return false;
    }
```

创建临时顺序节点后，其完整路径存放在 locked_path 成员中。另外还截取了一个后缀路径，放在 locked_short_path 成员中。 这个后缀路径，是一个短路径，只有完整路径的最后一层。在和取到的远程子节点列表中的其他路径进行比较时，需要用到短路径。因为子节点列表的路径，都是短路径，只有最后一层。

然后，调用checkLocked方法，判断是否是锁定成功。如果是则返回。如果自己没有获得锁，则要监听前一个节点。找出前一个节点的路径，保存在 prior_path 成员中，供后面的await 等待方法，去监听使用。

在进入await等待方法的介绍前，先说下checkLocked 锁定判断方法。

在checkLocked方法中，判断是否可以持有锁。判断规则很简单：当前创建的节点，是否在上一步获取到的子节点列表的第一个位置：

如果是，说明可以持有锁，返回true，表示加锁成功；

如果不是，说明有其他线程早已先持有了锁，返回false。

checkLocked方法的代码如下：
```
  private boolean checkLocked() {
        //获取等待的子节点列表

        List<String> waiters = getWaiters();
        //节点按照编号，升序排列
        Collections.sort(waiters);

        // 如果是第一个，代表自己已经获得了锁
        if (locked_short_path.equals(waiters.get(0))) {
            log.info("成功的获取分布式锁,节点为{}", locked_short_path);
            return true;
        }
        return false;
    }
```

checkLocked方法比较简单，就是获取到所有子节点列表，并且从小到大根据节点名称进行排序，主要依靠后10位数字，因为前缀都是一样的。

排序的结果，如果自己的locked_short_path位置在第一个，代表自己已经获得了锁。

现在正式进入等待方法await的介绍。

等待方法await，表示在争夺锁失败以后的等待逻辑。那么此处该线程应该做什么呢？

```
 private void await() throws Exception {

        if (null == prior_path) {
            throw new Exception("prior_path error");
        }

        final CountDownLatch latch = new CountDownLatch(1);


        //订阅比自己次小顺序节点的删除事件
        Watcher w = new Watcher() {
            @Override
            public void process(WatchedEvent watchedEvent) {
                System.out.println("监听到的变化 watchedEvent = " + watchedEvent);
                log.info("[WatchedEvent]节点删除");

                latch.countDown();
            }
        };

        client.getData().usingWatcher(w).forPath(prior_path);
      
        latch.await(WAIT_TIME, TimeUnit.SECONDS);
    }
```

首先添加一个watcher监听，而监听的地址正是上面一步返回的prior_path 成员。这里，仅仅会监听自己前一个节点的变动，而不是父节点下所有节点的变动。然后，调用latch.await，进入等待状态，等到latch.countDown()被唤醒。

一旦prior_path节点发生了变动，那么就将线程从等待状态唤醒，重新一轮的锁的争夺。

至此，关于加锁的算法基本完成。但是，上面还没有实现锁的可重入。

什么是可重入呢？

​ 只需要保障同一个线程进入加锁的代码，可以重复加锁成功即可。

```
修改前面的lock方法，在前面加上可重入的判断逻辑。代码如下：

  public boolean lock() {
     synchronized (this) {
        if (lockCount.get() == 0) {
            thread = Thread.currentThread();
            lockCount.incrementAndGet();
        } else {
            if (!thread.equals(Thread.currentThread())) {
                return false;
            }
            lockCount.incrementAndGet();
            return true;
        }
    }
    
   //...
   }
```

为了变成可重入，在代码中增加了一个加锁的计数器lockCount ，计算重复加锁的次数。如果是同一个线程加锁，只需要增加次数，直接返回，表示加锁成功。

释放锁的实现

释放锁主要有两个工作：

（1）减少重入锁的计数，如果不是0，直接返回，表示成功的释放了一次；

（2）如果计数器为0，移除Watchers监听器，并且删除创建的Znode临时节点；

代码如下：
```
@Override
    public boolean unlock() {

        if (!thread.equals(Thread.currentThread())) {
            return false;
        }

        int newLockCount = lockCount.decrementAndGet();

        if (newLockCount < 0) {
            throw new IllegalMonitorStateException("Lock count has gone negative for lock: " + locked_path);
        }

        if (newLockCount != 0) {
            return true;
        }
        try {
            if (ZKclient.instance.isNodeExist(locked_path)) {
                client.delete().forPath(locked_path);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }
```

这里，为了尽量保证线程安全，可重入计数器的类型，不是int类型，而是Java并发包中的原子类型——AtomicInteger。


#### 分布式锁的应用场景

前面的实现，主要的价值是展示一下分布式锁的基础开发和原理。实际的开发中，如果需要使用到分布式锁，并不需要自己造轮子，可以直接使用curator客户端中的各种官方实现的分布式锁，比如其中的InterProcessMutex 可重入锁。

InterProcessMutex 可重入锁的使用实例如下：

```
@Test
public void testzkMutex() throws InterruptedException {

    CuratorFramework client=ZKclient.instance.getClient();
    final InterProcessMutex zkMutex =
            new InterProcessMutex(client,"/mutex");  ;
    for (int i = 0; i < 10; i++) {
        FutureTaskScheduler.add(() -> {

            try {
                zkMutex.acquire();

                for (int j = 0; j < 10; j++) {

                    count++;
                }
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                log.info("count = " + count);
                zkMutex.release();

            } catch (Exception e) {
                e.printStackTrace();
            }

        });
    }

    Thread.sleep(Integer.MAX_VALUE);
}
```

#### 总结

Zookeeper分布式锁，能有效的解决分布式问题，不可重入问题，实现起来较为简单。

但是，Zookeeper实现的分布式锁其实存在一个缺点，那就是性能并不太高。因为每次在创建锁和释放锁的过程中，都要动态创建、销毁瞬时节点来实现锁功能。ZK中创建和删除节点只能通过Leader服务器来执行，然后Leader服务器还需要将数据同不到所有的Follower机器上。

所以，在高性能，高并发的场景下，不建议使用Zk的分布式锁。

目前分布式锁，比较成熟、主流的方案是基于redis及基于zookeeper的二种方案。这两种锁，应用场景不同。而 zookeeper只是其中的一种。Zk的分布式锁的应用场景，主要高可靠，而不是太高并发的场景下。

在并发量很高，性能要求很高的场景下，推荐使用基于redis的分布式锁。


### ZK分布式锁与Redis分布式锁比较

![ZooKeeper节点](/images/lockcompare.png)

有人说Zookeeper实现的分布式锁支持可重入，Redis实现的分布式锁不支持可重入，这是错误的观点。两者都可以在客户端实现可重入逻辑。




