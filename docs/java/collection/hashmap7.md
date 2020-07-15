
<h2>HashMap(JDK1.7)<h2>

参考：[图解HashMap原理](https://www.jianshu.com/p/dde9b12343c1)

------------------------------

### 使用与实现

#### 1. 基本使用

HashMap很方便地为我们提供了key-value的形式存取数据，使用put方法存数据，get方法取数据。

```
Map<String, String> hashMap = new HashMap<String, String>();
hashMap.put("name", "josan");
String name = hashMap.get("name");
```

#### 2. 定义

HashMap继承了Map接口，实现了Serializable等接口。

```
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable
{
    /**
     * The table, resized as necessary. Length MUST Always be a power of two.
     */
    transient Entry<K,V>[] table;
     
    .... 
    
}    
```

其实HashMap的数据是存在table数组中的，它是一个Entry数组，Entry是HashMap的一个静态内部类，看看它的定义。

```
static class Entry<K,V> implements Map.Entry<K,V> {
    final K key;
    V value;
    Entry<K,V> next;
    int hash;

    ....
        
}        
```

可见，Entry其实就是封装了key和value，也就是我们put方法参数的key和value会被封装成Entry，然后放到table这个Entry数组中。但值得注意的是，它有一个类型为Entry的next，它是用于指向下一个Entry的引用，所以table中存储的是Entry的单向链表。

默认参数的HashMap结构如下图所示：

![HashMap结构](/images/hashmap7-1.webp)

#### 3. 构造方法

HashMap一共有四个构造方法，我们只看默认的构造方法。

```
/**
 * Constructs an empty <tt>HashMap</tt> with the default initial capacity
 * (16) and the default load factor (0.75).
 */
public HashMap() {
    this(DEFAULT_INITIAL_CAPACITY, DEFAULT_LOAD_FACTOR);
}


public HashMap(int initialCapacity, float loadFactor) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal initial capacity: " +
                                           initialCapacity);
    if (initialCapacity > MAXIMUM_CAPACITY)
        initialCapacity = MAXIMUM_CAPACITY;
    if (loadFactor <= 0 || Float.isNaN(loadFactor))
        throw new IllegalArgumentException("Illegal load factor: " +
                                           loadFactor);

    // 找到第一个大于等于initialCapacity的2的平方的数
    int capacity = 1; 
    while (capacity < initialCapacity)
        capacity <<= 1;

    this.loadFactor = loadFactor;
    // HashMap扩容的阀值，值为HashMap的当前容量 * 负载因子，默认为12 = 16 * 0.75
    threshold = (int)Math.min(capacity * loadFactor, MAXIMUM_CAPACITY + 1);
    // 初始化table数组，这是HashMap真实的存储容器
    table = new Entry[capacity];
    useAltHashing = sun.misc.VM.isBooted() &&
            (capacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);
    // 该方法为空实现，主要是给子类去实现
    init();
}
```

- initialCapacity是HashMap的初始化容量(即初始化table时用到)，默认为16。

- loadFactor为负载因子，默认为0.75。

- threshold是HashMap进行扩容的阀值，当HashMap的存放的元素个数超过该值时，会进行扩容，它的值为HashMap的容量乘以负载因子。比如，HashMap的默认阀值为16*0.75，即12。

HashMap提供了指定HashMap初始容量和负载因子的构造函数，这时候会首先找到第一个大于等于initialCapacity的2的平方数，用于作为初始化table。至于为什么HashMap的容量总是2的平方数，后面会说到。

继续看HashMap构造方法，init是个空方法，主要给子类实现，比如LinkedHashMap在init初始化头部节点，这里暂时先不介绍。

#### 4. put方法

```
public V put(K key, V value) {
    // 对key为null的处理
    if (key == null)
        return putForNullKey(value);
    // 根据key算出hash值
    int hash = hash(key);
    // 根据hash值和HashMap容量算出在table中应该存储的下标i
    int i = indexFor(hash, table.length);
    for (Entry<K,V> e = table[i]; e != null; e = e.next) {
        Object k;
        // 先判断hash值是否一样，如果一样，再判断key是否一样
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }

    modCount++;
    addEntry(hash, key, value, i);
    return null;
}
```

首先，如果key为null调用putForNullKey来处理，我们暂时先不关注，后面会讲到。然后调用hash方法，根据key来算得hash值，得到hash值以后，调用indexFor方法，去算出当前值在table数组的下标，
我们可以来看看indexFor方法：

```
static int indexFor(int h, int length) {
    return h & (length-1);
}
```

这其实就是mod取余的一种替换方式，相当于h%(lenght-1)，其中h为hash值，length为HashMap的当前长度。而&是位运算，效率要高于%。至于为什么是跟length-1进行&的位运算，是因为length为2的幂次方，即一定是偶数，偶数减1，即是奇数，这样保证了（length-1）在二进制中最低位是1，而&运算结果的最低位是1还是0完全取决于hash值二进制的最低位。如果length为奇数，则length-1则为偶数，则length-1二进制的最低位横为0，则&位运算的结果最低位横为0，即横为偶数。这样table数组就只可能在偶数下标的位置存储了数据，浪费了所有奇数下标的位置，这样也更容易产生hash冲突。这也是HashMap的容量为什么总是2的平方数的原因。我们来用表格对比length=15和length=16的情况

![HashMap结构](/images/hashmap7-2.webp)

我们再回到put方法中，我们已经根据key得到hash值，然后根据hash值算出在table的存储下标了，接着就是这段for代码了：

```
for (Entry<K,V> e = table[i]; e != null; e = e.next) {
    Object k;
    // 先判断hash值是否一样，如果一样，再判断key是否一样
    if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
        V oldValue = e.value;
        e.value = value;
        e.recordAccess(this);
        return oldValue;
    }
}
```

首先取出table中下标为i的Entry，然后判断该Entry的hash值和key是否和要存储的hash值和key相同，如果相同，则表示要存储的key已经存在于HashMap，这时候只需要替换已存的Entry的value值即可。如果不相同，则取e.next继续判断，其实就是遍历table中下标为i的Entry单向链表，找是否有相同的key已经在HashMap中，如果有，就替换value为最新的值，所以HashMap中只能存储唯一的key。

**关于需要同时比较hash值和key有以下两点需要注意**

> - 为什么比较了hash值还需要比较key：因为不同对象的hash值可能一样
> - 为什么不只比较equal：因为equal可能被重写了，重写后的equal的效率要低于hash的直接比较

假设我们是第一次put，则整个for循环体都不会执行，我们继续往下看put方法。

```
modCount++;
addEntry(hash, key, value, i);
return null;
```

这里主要看addEntry方法，它应该就是把key和value封装成Entry，然后加入到table中的实现。来看看它的方法体：

```
void addEntry(int hash, K key, V value, int bucketIndex) {
    // 当前HashMap存储元素的个数大于HashMap扩容的阀值，则进行扩容
    if ((size >= threshold) && (null != table[bucketIndex])) {
        resize(2 * table.length);
        hash = (null != key) ? hash(key) : 0;
        bucketIndex = indexFor(hash, table.length);
    }
    // 使用key、value创建Entry并加入到table中
    createEntry(hash, key, value, bucketIndex);
}
```

这里牵涉到了HashMap的扩容，我们先不讨论扩容，后面会讲到。然后调用了createEntry方法，它的实现如下：

```
void createEntry(int hash, K key, V value, int bucketIndex) {
    // 取出table中下标为bucketIndex的Entry
    Entry<K,V> e = table[bucketIndex];
    // 利用key、value来构建新的Entry
    // 并且之前存放在table[bucketIndex]处的Entry作为新Entry的next
    // 把新创建的Entry放到table[bucketIndex]位置
    table[bucketIndex] = new Entry<>(hash, key, value, e);
    // HashMap当前存储的元素个数size自增
    size++;
}
```

这里其实就是根据hash、key、value以及table中下标为bucketIndex的Entry去构建一个新的Entry，其中table中下标为bucketIndex的Entry作为新Entry的next，这也说明了，当hash冲突时，采用的拉链法来解决hash冲突的，并且是**把新元素是插入到单边表的表头**。如下所示：

![HashMap结构](/images/hashmap7-3.webp)

#### 5. 扩容

如果当前HashMap中存储的元素个数达到扩容的阀值，且当前要存在的值在table中要存放的位置已经有存值时，怎么处理的？我们再来看看addEntry方法中的扩容相关代码：

```
if ((size >= threshold) && (null != table[bucketIndex])) {
    // 将table表的长度增加到之前的两倍
    resize(2 * table.length);
    // 重新计算哈希值
    hash = (null != key) ? hash(key) : 0;
    // 从新计算新增元素在扩容后的table中应该存放的index
    bucketIndex = indexFor(hash, table.length);
}
```

接下来我们看看resize是如何将table增加长度的：

```
 void resize(int newCapacity) {
    // 保存老的table和老table的长度
    Entry[] oldTable = table;
    int oldCapacity = oldTable.length;
    if (oldCapacity == MAXIMUM_CAPACITY) {
        threshold = Integer.MAX_VALUE;
        return;
    }
    // 创建一个新的table，长度为之前的两倍
    Entry[] newTable = new Entry[newCapacity];
    // hash有关
    boolean oldAltHashing = useAltHashing;
    useAltHashing |= sun.misc.VM.isBooted() &&
            (newCapacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);
    // 这里进行异或运算，一般为true
    boolean rehash = oldAltHashing ^ useAltHashing;
    // 将老table的原有数据，从新存储到新table中
    transfer(newTable, rehash);
    // 使用新table
    table = newTable;
    // 扩容后的HashMap的扩容阀门值
    threshold = (int)Math.min(newCapacity * loadFactor, MAXIMUM_CAPACITY + 1);
}
```

再来看看transfer方法是如何将把老table的数据，转到扩容后的table中的：

```
 void transfer(Entry[] newTable, boolean rehash) {
    int newCapacity = newTable.length;
    // 遍历老的table数组
    for (Entry<K,V> e : table) {
        // 遍历老table数组中存储每条单项链表
        while(null != e) {
            // 取出老table中每个Entry
            Entry<K,V> next = e.next;
            if (rehash) {
                //重新计算hash
                e.hash = null == e.key ? 0 : hash(e.key);
            }
            // 根据hash值，算出老table中的Entry应该在新table中存储的index
            int i = indexFor(e.hash, newCapacity);
            // 让老table转移的Entry的next指向新table中它应该存储的位置
            // 即插入到了新table中index处单链表的表头
            e.next = newTable[i];
            // 将老table取出的entry，放入到新table中
            newTable[i] = e;
            // 继续取老talbe的下一个Entry
            e = next;
        }
    }
}
```

从上面易知，扩容就是先创建一个长度为原来2倍的新table，然后通过遍历的方式，将老table的数据，重新计算hash并存储到新table的适当位置，最后使用新的table，并重新计算HashMap的扩容阀值。

#### 6. get方法

```
public V get(Object key) {
    // 当key为null, 这里不讨论，后面统一讲
    if (key == null)
        return getForNullKey();
    // 根据key得到key对应的Entry
    Entry<K,V> entry = getEntry(key);
    // 
    return null == entry ? null : entry.getValue();
}
```

然后我们看看getEntry是如果通过key取到Entry的：

```
final Entry<K,V> getEntry(Object key) {
    // 根据key算出hash
    int hash = (key == null) ? 0 : hash(key);
    // 先算出hash在table中存储的index，然后遍历table中下标为index的单向链表
    for (Entry<K,V> e = table[indexFor(hash, table.length)];
         e != null;
         e = e.next) {
        Object k;
        // 如果hash和key都相同，则把Entry返回
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k))))
            return e;
    }
    return null;
}
```

取值，最简单粗暴的方式肯定是遍历table，并且遍历table中存放的单向链表，这样的话，get的时间复杂度就是O(n的平方)，但是HashMap的put本身就是有规律的存储，所以，取值时，可以按照规律去降低时间复杂度。上面的代码比较简单，其实节约的就是遍历table的过程，因为我们可以用key的hash值算出key对应的Entry所在链表在在table的下标。这样，我们只要遍历单向链表就可以了，时间复杂度降低到O(n)。

get方法的取值过程如下图所示：

![HashMap结构](/images/hashmap7-4.webp)

#### 7. 使用entrySet取数据

HashMap除了提供get方法，通过key来取数据的方式，还提供了entrySet方法来遍历HashMap的方式取数据。如下：

```
Map<String, String> hashMap = new HashMap<String, String>();
hashMap.put("name1", "josan1");
hashMap.put("name2", "josan2");
hashMap.put("name3", "josan3");
Set<Entry<String, String>> set = hashMap.entrySet();
Iterator<Entry<String, String>> iterator = set.iterator();
while(iterator.hasNext()) {
    Entry entry = iterator.next();
    String key = (String) entry.getKey();
    String value = (String) entry.getValue();
    System.out.println("key:" + key + ",value:" + value);
}
```

![HashMap结构](/images/hashmap7-5.webp)

结果可知，HashMap存储数据是无序的。

我们这里主要是讨论，它是如何来完成遍历的。HashMap重写了entrySet。

```
public Set<Map.Entry<K,V>> entrySet() {
    return entrySet0();
}

private Set<Map.Entry<K,V>> entrySet0() {
    Set<Map.Entry<K,V>> es = entrySet;
    // 相当于返回了new EntrySet
    return es != null ? es : (entrySet = new EntrySet());
}
```

代码比较简单，直接new EntrySet对象并返回，EntrySet是HashMap的内部类，注意，不是静态内部类，所以它的对象会默认持有外部类HashMap的对象，定义如下：

```
private final class EntrySet extends AbstractSet<Map.Entry<K,V>> {
    // 重写了iterator方法
    public Iterator<Map.Entry<K,V>> iterator() {
        return newEntryIterator();
    }
   // 不相关代码
   ...
}
```

我们主要是关心iterator方法，EntrySet 重写了该方法，所以调用Set的iterator方法，会调用到这个重写的方法，方法内部很简单单，直接调用了newEntryIterator方法，返回了一个自定义的迭代器。我们看看newEntryIterator：

```
Iterator<Map.Entry<K,V>> newEntryIterator()   {
    return new EntryIterator();
}
```

可看到，直接new了一个EntryIterator对象返回，看看EntryIterator的定义：

```
private final class EntryIterator extends HashIterator<Map.Entry<K,V>> {
    // 重写了next方法
    public Map.Entry<K,V> next() {
        return nextEntry();
    }
}
```

EntryIterator 是继承了HashIterator，我们再来看看HashIterator的定义：

```
private abstract class HashIterator<E> implements Iterator<E> {
    Entry<K,V> next;        // 下一个要返回的Entry
    int expectedModCount;   // For fast-fail
    int index;              // 当前table上下标
    Entry<K,V> current;     // 当前的Entry

    HashIterator() {
        expectedModCount = modCount;
        if (size > 0) { // advance to first entry
            Entry[] t = table;
            while (index < t.length && (next = t[index++]) == null)
                ;
        }
    }

    public final boolean hasNext() {
        return next != null;
    }

    final Entry<K,V> nextEntry() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        Entry<K,V> e = next;
        if (e == null)
            throw new NoSuchElementException();

        if ((next = e.next) == null) {
            Entry[] t = table;
            while (index < t.length && (next = t[index++]) == null)
                ;
        }
        current = e;
        return e;
    }
    // 不相关
    ......
}
```

我们先看构造方法：

```
HashIterator() {
    expectedModCount = modCount;
    if (size > 0) { // advance to first entry
        Entry[] t = table;
        // 这里其实就是遍历table，找到第一个返回的Entry next
        // 该值是table数组的第一个有值的Entry，所以也肯定是单向链表的表头
        while (index < t.length && (next = t[index++]) == null)
            ;
    }
}
```

以上，就是我们调用了Iterator<Entry<String, String>> iterator = set.iterator();代码所执行的过程

接下来就是使用while(iterator.hasNext())去循环判断是否有下一个Entry，EntryIterator没有实现hasNext方法，所以也是调用的HashIterator中的hasNext，我们来看看该方法：

```
public final boolean hasNext() {
    // 如果下一个返回的Entry不为null，则返回true
    return next != null;
}
```

该方法很简单，就是判断下一个要返回的Entry next是否为null，如果HashMap中有元素，那么第一次调用hasNext时next肯定不为null，且是table数组的第一个有值的Entry，也就是第一条单向链表的表头Entry。

接下来，就到了调用EntryIterator.next去取下一个Entry了，EntryIterator对next方法进行了重写，看看该方法：

```
public Map.Entry<K,V> next() {
    return nextEntry();
}
```

直接调用了nextEntry方法，返回下一个Entry，但是EntryIterator并没有重写nextEntry，所以还是调用的HashIterator的nextEntry方法，方法如下：

```
final Entry<K,V> nextEntry() {
    // 保存下一个需要返回的Entry，作为返回结果
    Entry<K,V> e = next;
    // 如果遍历到table上单向链表的最后一个元素时
    if ((next = e.next) == null) {
        Entry[] t = table;
        // 继续往下寻找table上有元素的下标
        // 并且把下一个talbe上有单向链表的表头，作为下一个返回的Entry next
        while (index < t.length && (next = t[index++]) == null)
            ;
    }
    current = e;
    return e;
}
```

其实nextEntry的主要作用有两点

- 把当前遍历到的Entry返回
- 准备好下一个需要返回的Entry

如果当前返回的Entry不是单向链表的最后一个元素，那只要让下一个返回的Entrynext为当前Entry的next属性（下图红色过程）；如果当前返回的Entry是单向链表的最后一个元素，那么它就没有next属性了，所以要寻找下一个table上有单向链表的表头（下图绿色过程）

![HashMap结构](/images/hashmap7-6.webp)

可知，HashMap的遍历，是先遍历table，然后再遍历table上每一条单向链表，如上述的HashMap遍历出来的顺序就是Entry1、Entry2....Entry6，但显然，这不是插入的顺序，所以说：HashMap是无序的。

#### 8. 对key为null的处理

先看put方法时，key为null

```
public V put(K key, V value) {
    if (key == null)
        return putForNullKey(value);
   //其他不相关代码
   .......
}
```

看看putForNullKey的处理

```
private V putForNullKey(V value) {
    // 遍历table[0]上的单向链表
    for (Entry<K,V> e = table[0]; e != null; e = e.next) {
        // 如果有key为null的Entry，则替换该Entry中的value
        if (e.key == null) {
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }
    modCount++;
    // 如果没有key为null的Entry，则构造一个hash为0、key为null、value为真实值的Entry
    // 插入到table[0]上单向链表的头部
    addEntry(0, null, value, 0);
    return null;
}
```

其实key为null的put过程，跟普通key值的put过程很类似，区别在于key为null的hash为0，存放在table[0]的单向链表上而已。

我们再来看看对于key为null的取值：

```
public V get(Object key) {
    if (key == null)
        return getForNullKey();
        //不相关的代码
        ......
}
```

取值就是通过getForNullKey方法来完成的，代码如下：

```
private V getForNullKey() {
    //  遍历table[0]上的单向链表
    for (Entry<K,V> e = table[0]; e != null; e = e.next) {
        // 如果key为null，则返回该Entry的value值
        if (e.key == null)
            return e.value;
    }
    return null;
}
```

key为null的取值，跟普通key的取值也很类似，只是不需要去算hash和确定存储在table上的index而已，而是直接遍历talbe[0]。

所以，在HashMap中，不允许key重复，而key为null的情况，只允许一个key为null的Entry，并且存储在table[0]的单向链表上。

#### 9. remove方法

HashMap提供了remove方法，用于根据key移除HashMap中对应的Entry

```
public V remove(Object key) {
    Entry<K,V> e = removeEntryForKey(key);
    return (e == null ? null : e.value);
}
```

首先调用removeEntryForKey方法把key对应的Entry从HashMap中移除。然后把移除的值返回。我们继续看removeEntryForKey方法：

```
final Entry<K,V> removeEntryForKey(Object key) {
    // 算出hash
    int hash = (key == null) ? 0 : hash(key);
    // 得到在table中的index
    int i = indexFor(hash, table.length);
    // 当前结点的上一个结点，初始为table[index]上单向链表的头结点
    Entry<K,V> prev = table[i];
    Entry<K,V> e = prev;

    while (e != null) {
        // 得到下一个结点
        Entry<K,V> next = e.next;
        Object k;
        // 如果找到了删除的结点
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k)))) {
            modCount++;
            size--;
            // 如果是table上的单向链表的头结点，则直接让把该结点的next结点放到头结点
            if (prev == e)
                table[i] = next;
            else
                // 如果不是单向链表的头结点，则把上一个结点的next指向本结点的next
                prev.next = next;  
            // 空实现
            e.recordRemoval(this);
            return e;
        }
        // 没有找到删除的结点，继续往下找
        prev = e;
        e = next;
    }

    return e;
}
```

其实逻辑也很简单，先根据key算出hash，然后根据hash得到在table上的index，再遍历talbe[index]的单向链表，这时候需要看要删除的元素是否就是单向链表的表头，如果是，则直接让table[index]=next，即删除了需要删除的元素；如果不是单向链表的头，那表示有前面的结点，则让pre.next = next，也删除了需要删除的元素。

#### 10. 线程安全问题

由前面HashMap的put和get方法分析可得，put和get方法真实操作的都是Entry[] table这个数组，而所有操作都没有进行同步处理，所以HashMap是线程不安全的。如果想要实现线程安全，推荐使用ConcurrentHashMap。


### 总结

- HashMap是基于哈希表实现的，用Entry[]来存储数据，而Entry中封装了key、value、hash以及Entry类型的next

- HashMap存储数据是无序的

- hash冲突是通过拉链法解决的

- HashMap的容量永远为2的幂次方，有利于哈希表的散列

- HashMap不支持存储多个相同的key，且只保存一个key为null的值，多个会覆盖

- put过程，是先通过key算出hash，然后用hash算出应该存储在table中的index，然后遍历table[index]，看是否有相同的key存在，存在，则更新value；不存在则插入到table[index]单向链表的表头，时间复杂度为O(n)

- get过程，通过key算出hash，然后用hash算出应该存储在table中的index，然后遍历table[index]，然后比对key，找到相同的key，则取出其value，时间复杂度为O(n)

- HashMap是线程不安全的，如果有线程安全需求，推荐使用ConcurrentHashMap。

