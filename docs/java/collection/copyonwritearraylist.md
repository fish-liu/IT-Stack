
本文转载自：https://www.jianshu.com/p/5227288a850b

CopyOnWriteArrayList的原理与应用

---------------------------------------

Copy-On-Write简称COW，是一种用于程序设计中的优化策略。其基本思路是，从一开始大家都在共享同一个内容，当某个人想要修改这个内容的时候，才会真正把内容Copy出去形成一个新的内容然后再改，这是一种延时懒惰策略。从JDK1.5开始Java并发包里提供了两个使用CopyOnWrite机制实现的并发容器,它们是CopyOnWriteArrayList和CopyOnWriteArraySet。CopyOnWrite容器非常有用，可以在非常多的并发场景中使用到。

#### 一. 什么是CopyOnWrite容器

CopyOnWrite容器即写时复制的容器。通俗的理解是当我们往一个容器添加元素的时候，不直接往当前容器添加，而是先将当前容器进行Copy，复制出一个新的容器，然后新的容器里添加元素，添加完元素之后，再将原容器的引用指向新的容器。这样做的好处是我们可以对CopyOnWrite容器进行并发的读，而不需要加锁，因为当前容器不会添加任何元素。所以CopyOnWrite容器也是一种读写分离的思想，读和写不同的容器。


#### 二. 证明CopyOnWriteArrayList是线程安全的

ReadThread.java:从List中读取数据的线程

```java
import java.util.List;

/**
 * <Description> <br>
 *
 * @author Sunny<br>
 * @version 1.0<br>
 * @taskId: <br>
 * @createDate 2018/08/27 13:14 <br>
 */
public class ReadThread implements Runnable {
    private List<Integer> list;

    public ReadThread(List<Integer> list) {
        this.list = list;
    }

    @Override
    public void run() {
        for (Integer ele : list) {
            System.out.println("ReadThread:"+ele);
        }
    }
}
```

WriteThread.java:向List中写数据的线程；

```java
/**
 * <Description> <br>
 *
 * @author Sunny<br>
 * @version 1.0<br>
 * @taskId: <br>
 * @createDate 2018/08/27 13:14 <br>
 */
public class WriteThread implements Runnable {
    private List<Integer> list;

    public WriteThread(List<Integer> list) {
        this.list = list;
    }

    @Override
    public void run() {
        Integer num = new Random().nextInt(10);
        this.list.add(num);
        System.out.println("Write Thread:" + num);
    }
}
```

TestCopyOnWriteArrayList .java：实现两个方法，一个使用ArrayList容器，一个使用CopyOnWriteArrayList容器，来进行多线程的读写操作；

```java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * <Description> 证明CopyOnWriteArrayList是线程安全的<br>
 *
 * @author Sunny<br>
 * @version 1.0<br>
 * @taskId: <br>
 * @createDate 2018/08/27 13:14 <br>
 * @see com.sunny.jdk.concurrent.cow.copyonwritearraylist <br>
 */
public class TestCopyOnWriteArrayList {
    private void testCopyOnWriteArrayList() {
        //1、初始化CopyOnWriteArrayList
        List<Integer> tempList = Arrays.asList(new Integer [] {1,2});
        CopyOnWriteArrayList<Integer> copyList = new CopyOnWriteArrayList<>(tempList);


        //2、模拟多线程对list进行读和写
        ExecutorService executorService = Executors.newFixedThreadPool(10);
        executorService.execute(new ReadThread(copyList));
        executorService.execute(new WriteThread(copyList));
        executorService.execute(new WriteThread(copyList));
        executorService.execute(new WriteThread(copyList));
        executorService.execute(new ReadThread(copyList));
        executorService.execute(new WriteThread(copyList));
        executorService.execute(new ReadThread(copyList));
        executorService.execute(new WriteThread(copyList));
        executorService.shutdown();

        System.out.println("copyList size:"+copyList.size());
    }
    private void testArrayList() {
        //1、初始化CopyOnWriteArrayList
        List<Integer> arrList = new ArrayList();
        arrList.add(1);
        arrList.add(2);


        //2、模拟多线程对list进行读和写
        ExecutorService executorService = Executors.newFixedThreadPool(10);
        executorService.execute(new ReadThread(arrList));
        executorService.execute(new WriteThread(arrList));
        executorService.execute(new WriteThread(arrList));
        executorService.execute(new WriteThread(arrList));
        executorService.execute(new ReadThread(arrList));
        executorService.execute(new WriteThread(arrList));
        executorService.execute(new ReadThread(arrList));
        executorService.execute(new WriteThread(arrList));
        executorService.shutdown();

        System.out.println("arrList size:"+ arrList.size());
    }


    public static void main(String[] args) {
        TestCopyOnWriteArrayList tcowal = new TestCopyOnWriteArrayList();
        //tcowal.testCopyOnWriteArrayList();
        tcowal.testArrayList();
    }
}
```

如果调用tcowal.testCopyOnWriteArrayList();方法，则会打印如下：

```
ReadThread:1
ReadThread:2
copyList size:2
ReadThread:1
ReadThread:2
ReadThread:1
ReadThread:2
Write Thread:5
Write Thread:5
Write Thread:0
Write Thread:2
Write Thread:5

Process finished with exit code 0
```

如果调用tcowal.testArrayList();方法，则会打印如下：

```
ReadThread:1
ReadThread:2
arrList size:2
ReadThread:1
Write Thread:8
Write Thread:9
Write Thread:8
ReadThread:1
ReadThread:2
Write Thread:6
Write Thread:9
Exception in thread "pool-1-thread-5" Exception in thread "pool-1-thread-7" java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:901)
    at java.util.ArrayList$Itr.next(ArrayList.java:851)
    at com.sunny.jdk.concurrent.cow.copyonwritearraylist.ReadThread.run(ReadThread.java:23)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
    at java.lang.Thread.run(Thread.java:748)
java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:901)
    at java.util.ArrayList$Itr.next(ArrayList.java:851)
    at com.sunny.jdk.concurrent.cow.copyonwritearraylist.ReadThread.run(ReadThread.java:23)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
    at java.lang.Thread.run(Thread.java:748)

Process finished with exit code 0
```

说明了CopyOnWriteArrayList并发多线程的环境下，仍然能很好的工作。


#### 三. CopyOnWriteArrayList的实现原理

现在我们来通过看源码的方式来理解CopyOnWriteArrayList，实际上CopyOnWriteArrayList内部维护的就是一个数组，如下：

```
/** The array, accessed only via getArray/setArray. */
    private transient volatile Object[] array;
```

并且该数组引用是被volatile修饰，注意这里仅仅是修饰的是数组引用，关于volatile很重要的一条性质是它能够够保证可见性，对list来说，我们自然而然最关心的就是读写的时候，分别为get和add方法的实现。

**get方法实现原理**

get方法源码如下：

```
/**
 * Gets the array.  Non-private so as to also be accessible
 * from CopyOnWriteArraySet class.
 */
final Object[] getArray() {
    return array;
}

@SuppressWarnings("unchecked")
private E get(Object[] a, int index) {
    return (E) a[index];
}

/**
 * {@inheritDoc}
 *
 * @throws IndexOutOfBoundsException {@inheritDoc}
 */
public E get(int index) {
    return get(getArray(), index);
}
```

可以看出来get方法实现非常简单，几乎就是一个单线程程序，没有对多线程添加任何的线程安全控制，也没有加锁也没有CAS操作等等，原因是，所有的读线程只是会读取数据容器中的数据，并不会进行修改。

**add方法实现原理**

add方法源码如下：

```
/**
 * Appends the specified element to the end of this list.
 *
 * @param e element to be appended to this list
 * @return {@code true} (as specified by {@link Collection#add})
 */
public boolean add(E e) {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        Object[] elements = getArray();
        int len = elements.length;
        Object[] newElements = Arrays.copyOf(elements, len + 1);
        newElements[len] = e;
        setArray(newElements);
        return true;
    } finally {
        lock.unlock();
    }
}

/**
 * Inserts the specified element at the specified position in this
 * list. Shifts the element currently at that position (if any) and
 * any subsequent elements to the right (adds one to their indices).
 *
 * @throws IndexOutOfBoundsException {@inheritDoc}
 */
public void add(int index, E element) {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        Object[] elements = getArray();
        int len = elements.length;
        if (index > len || index < 0)
            throw new IndexOutOfBoundsException("Index: "+index+
                                                ", Size: "+len);
        Object[] newElements;
        int numMoved = len - index;
        if (numMoved == 0)
            newElements = Arrays.copyOf(elements, len + 1);
        else {
            newElements = new Object[len + 1];
            System.arraycopy(elements, 0, newElements, 0, index);
            System.arraycopy(elements, index, newElements, index + 1,
                             numMoved);
        }
        newElements[index] = element;
        setArray(newElements);
    } finally {
        lock.unlock();
    }
}
```

add方法的逻辑也比较容易理解，请看上面的注释。需要注意这么几点：

- 采用ReentrantLock，保证同一时刻只有一个写线程正在进行数组的复制，否则的话内存中会有多份被复制的数据；

- 前面说过数组引用是volatile修饰的，因此将旧的数组引用指向新的数组，根据volatile的happens-before规则，写线程对数组引用的修改对读线程是可见的。

- 由于在写数据的时候，是在新的数组中插入数据的，从而保证读写是在两个不同的数据容器中进行操作。

这里还有这样一个问题： 为什么需要复制呢？ 如果将array数组设定为volatile的， 对volatile变量写happens-before读，读线程不是能够感知到volatile变量的变化。

原因是，这里volatile的修饰的仅仅只是数组引用，数组中的元素的修改是不能保证可见性的。因此COW采用的是新旧两个数据容器，通过setArray(newElements);这一行代码将数组引用指向新的数组。


#### 四. CopyOnWrite的使用场景

CopyOnWrite并发容器用于读多写少的并发场景。比如白名单，黑名单，商品类目的访问和更新场景，假如我们有一个搜索网站，用户在这个网站的搜索框中，输入关键字搜索内容，但是某些关键字不允许被搜索。这些不能被搜索的关键字会被放在一个黑名单当中，黑名单每天晚上更新一次。当用户搜索时，会检查当前关键字在不在黑名单当中，如果在，则提示不能搜索。实现代码如下：

```java
import java.util.Map;

import com.ifeve.book.forkjoin.CopyOnWriteMap;

/**
 * 黑名单服务
 */
public class BlackListServiceImpl {

    private static CopyOnWriteMap<String, Boolean> blackListMap = new CopyOnWriteMap<String, Boolean>(
            1000);

    public static boolean isBlackList(String id) {
        return blackListMap.get(id) == null ? false : true;
    }

    public static void addBlackList(String id) {
        blackListMap.put(id, Boolean.TRUE);
    }

    /**
     * 批量添加黑名单
     *
     * @param ids
     */
    public static void addBlackList(Map<String,Boolean> ids) {
        blackListMap.putAll(ids);
    }

}
```

代码很简单，但是使用CopyOnWriteMap需要注意两件事情：

- 减少扩容开销。根据实际需要，初始化CopyOnWriteMap的大小，避免写时CopyOnWriteMap扩容的开销。

- 使用批量添加。因为每次添加，容器每次都会进行复制，所以减少添加次数，可以减少容器的复制次数。如使用上面代码里的addBlackList方法。


#### 五. CopyOnWriteArrayList的缺点

CopyOnWrite容器有很多优点，但是同时也存在两个问题，即内存占用问题和数据一致性问题。所以在开发的时候需要注意一下。

**内存占用问题**

因为CopyOnWrite的写时复制机制，所以在进行写操作的时候，内存里会同时驻扎两个对象的内存，旧的对象和新写入的对象（注意:在复制的时候只是复制容器里的引用，只是在写的时候会创建新对象添加到新容器里，而旧容器的对象还在使用，所以有两份对象内存）。如果这些对象占用的内存比较大，比如说200M左右，那么再写入100M数据进去，内存就会占用300M，那么这个时候很有可能造成频繁的Yong GC和Full GC。之前我们系统中使用了一个服务由于每晚使用CopyOnWrite机制更新大对象，造成了每晚15秒的Full GC，应用响应时间也随之变长。

针对内存占用问题，可以通过压缩容器中的元素的方法来减少大对象的内存消耗，比如，如果元素全是10进制的数字，可以考虑把它压缩成36进制或64进制。或者不使用CopyOnWrite容器，而使用其他的并发容器，如ConcurrentHashMap

**数据一致性问题**

CopyOnWrite容器只能保证数据的最终一致性，不能保证数据的实时一致性。所以如果你希望写入的的数据，马上能读到，请不要使用CopyOnWrite容器。


#### 六. 对比Collections.synchronizedList

CopyOnWriteArrayList和Collections.synchronizedList是实现线程安全的列表的两种方式。两种实现方式分别针对不同情况有不同的性能表现。

- 因为CopyOnWriteArrayList的写操作不仅有lock锁，还在内部进行了数组的copy，所以性能比Collections.synchronizedList要低。

- 而读操作CopyOnWriteArrayList直接取的数组的值，Collections.synchronizedList却有synchronized修饰，所以读性能CopyOnWriteArrayList略胜一筹。

- 因此在不同的应用场景下，应该选择不同的多线程安全实现类。


#### 七. COW vs 读写锁

**相同点：**

1. 两者都是通过读写分离的思想实现；

2. 读线程间是互不阻塞的

**不同点：**

对读线程而言，为了实现数据实时性，在写锁被获取后，读线程会等待或者当读锁被获取后，写线程会等待，从而解决“脏读”等问题。也就是说如果使用读写锁依然会出现读线程阻塞等待的情况。而COW则完全放开了牺牲数据实时性而保证数据最终一致性，即读线程对数据的更新是延时感知的，因此读线程不会存在等待的情况。


#### 八. CopyOnWriteArrayList透露的思想

如上面的分析CopyOnWriteArrayList表达的一些思想：

- 读写分离，读和写分开

- 最终一致性

- 使用另外开辟空间的思路，来解决并发冲突