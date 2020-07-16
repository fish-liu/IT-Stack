
<h2>ArrayList</h2>

参考：[图解ArrayList](https://www.jianshu.com/p/be1ff16dfcbd)

【源码之下无秘密】ArrayList：在内存只有10M的空间中申请一块5M的数组空间，会导致OOM吗？
https://blog.csdn.net/qq_33220089/article/details/105313478

-----------------------------------------------

ArrayList和LinkedList是我们常用的数据结构，它们都是线性表，ArrayList是顺序存储的线性表，LinkedList是链式存储的线性表。

### ArrayList使用与实现

#### 1. 构造方法

ArrayList有三个构造方法，我们先来看默认的构造方法

```
public ArrayList() {
    this(10);
}
```

直接调用了initalCapacity为10的有参构造方法

```
private transient Object[] elementData;

public ArrayList(int initialCapacity) {
    super();
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal Capacity: "+
                                           initialCapacity);
    this.elementData = new Object[initialCapacity];
}
```

在有参的构造方法里，主要就是创建了一个长度为initialCapacity，类型为Object的数组，而这里的elementData就是我们ArrayList真正存放数据的数组了。

通过构造方法，我们知道

- 1.ArrayList是基于数组实现的
- 2.默认的ArrayList构造方法，其实就是创建了一个长度为10的Object数组elementData
- 3.ArrayList支持有参的构造方法，其中参数initialCapacity用于指定存放数据的数组elementData 的初始化长度

我们通过new ArrayList()代码时，其实就是创建了如下图的数组elementData

![ArrayList结构](/images/arraylist-1.webp)

其实，ArrayList还有一个参数为Collection的构造方法

```
public ArrayList(Collection<? extends E> c) {
    elementData = c.toArray();
    size = elementData.length;
    // c.toArray might (incorrectly) not return Object[] (see 6260652)
    if (elementData.getClass() != Object[].class)
        elementData = Arrays.copyOf(elementData, size, Object[].class);
}
```

可以看出，这个构造函数其实就是用传入的集合c去创建一个Object[] elementData

#### 2. 添加元素 add（E e）

```
public boolean add(E e) {
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    elementData[size++] = e;
    return true;
}
```

新增元素的流程主要有如下三步

- 1.首先调用ensureCapacityInternal来确保加入一个元素以后，没有超出当前存储数据的数组elementData的长度，如果超出了，则需要进行扩容

- 2.然后再把新加入的元素e放到数组elementData第一个没有赋值的地方（其实就是插入到ArrayList的尾部）

- 3.最后ArrayList的长度size自增。

我们先来看看ensureCapacityInternal是如何确保elementData的容量的：

```
private void ensureCapacityInternal(int minCapacity) {
    modCount++;
    // overflow-conscious code
    if (minCapacity - elementData.length > 0)
        grow(minCapacity);
}
```

当我们需要的ArrayList长度大于elementData长度时，表示当前数组不能再添加新的元素了，则需要调用grow方法进行扩容，我们看看grow方法

```
private void grow(int minCapacity) {
    // overflow-conscious code
    int oldCapacity = elementData.length;
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    elementData = Arrays.copyOf(elementData, newCapacity);
}
```

这个方法的作用其实就是对存放数据的数组elementData 进行扩容，首先，扩容的长度newCapacity 为1.5倍之前数组的长度，然后再和需要的长度做比较，如果需要的长度大于1.5倍原来的长度，那扩容以后的长度就为需要的长度

后面是对数组允许最大长度的处理，一般不会触发。

最后，调用Arrays.copyOf方法去创建一个长度为newCapacity的新数组，并且把原有数据复制进去

举例说明：

假如我们开始通过默认方式创建了一个ArrayList，也就是elementData是长度为10的Object[]，然后我们一次把a~j一共10个字母加入到ArrayList，这个时候，elementData已经满了，我们还想加入字母k，就需要扩容了，经过计算可得扩容后的数组elementData长度为：10 * 1.5 = 15，然后再把扩容前的数据复制到扩容后的数组中

这只是完成elementData的扩容，接下来，再通过elementData[size++] = e；把要加入的元素k放到elementData的size位置，如下图所示：

![ArrayList结构](/images/arraylist-2.webp)

可以看出，添加元素的时间复杂度为O(1)

另外，当我们ArrayList需要加入元素时，如果当前elementData不足以存放新加入的元素时，就需要扩容，所以如果当我们事先知道我们加入数据的大致规模，我们就可以通过ArrayList(int initialCapacity) 构造函数来创建ArrayList，这样就可以初始化一个与我们数据规模相当的elementData，从而减少扩容的次数。

#### 3. 增加集合 addAll（Collection<? extends E> c）

ArrayList除了增加一个元素的方法，还可以增加一个集合，和增加元素类似，增加集合也是加入到ArrayList的尾部，代码如下：

```
public boolean addAll(Collection<? extends E> c) {
    Object[] a = c.toArray();
    int numNew = a.length;
    ensureCapacityInternal(size + numNew);  // Increments modCount
    System.arraycopy(a, 0, elementData, size, numNew);
    size += numNew;
    return numNew != 0;
}
```

可以看到，新增集合的步骤也有如下三步：

- 1.调用ensureCapacityInternal去确定数组是否要扩容时，传入的参数为ArrayList原本的长度+新增集合的长度

- 2.存入新增集合数据时，调用System.arraycopy方法把新增集合放到数组elementData第一个没有赋值的地方（其实就是插入到ArrayList的尾部）

- 3.ArrayList的size增加新增集合的长度

还是之前的例子，只不过这时候我们不是只加入元素k，而是加入了一个集合，这个集合中有元素k、l、m、n，示意图如下

![ArrayList结构](/images/arraylist-3.webp)

#### 4. 取数据 get(int index)

```
public E get(int index) {
    rangeCheck(index);

    return elementData(index);
}
```

首先，调用了rangeCheck去检测index是否超过ArrayList的长度，如果超过，则会抛出著名的IndexOutOfBoundsException错误，我们来看看rangeCheck方法就知道了

```
private void rangeCheck(int index) {
    if (index >= size)
        throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
```

确定index合法以后，就调用elementData去获取值了，我们来看看elementData方法

```
E elementData(int index) {
    return (E) elementData[index];
}
```

这里就是直接从elementData中取出数据返回即可

所以ArrayList的get（index）方法主要就是如下两步：

- 检测index是否合法

- 从elementData从取出下标为index的元素

**举例：**

比如我们的ArrayList已经加入了a~k这11个元素，这时候我们想得到arrayList.get(5)，就能通过elementData[5]轻松取出元素f了，示意图如下：

![ArrayList结构](/images/arraylist-4.webp)

可见，ArrayList的get方法的时间复杂度为O(1)

#### 5. 插入元素 add(int index, E element)

```
public void add(int index, E element) {
    rangeCheckForAdd(index);

    ensureCapacityInternal(size + 1);  // Increments modCount!!
    System.arraycopy(elementData, index, elementData, index + 1,
                     size - index);
    elementData[index] = element;
    size++;
}
```

我们知道ArrayList是基于数组来实现的，那插入一个元素怎么来实现呢？其实就是把要插入的位置的元素已经后面的元素，都往后面挪动一个位置（这里的挪动其实不是真正地往后挪动，而是element[index+1] = elementData[index]），从上面的代码也可以看出，插入的逻辑如下：

- 检查index的合法性

- 调用ensureCapacityInternal进行有可能的扩容

- 调用System.arraycopy去把数组index以及后面的数据往后挪动一个位置

- 把插入的元素element放入数组elementData的index处

- ArrayList的长度size自增

那时间复杂度是多少呢？其实这里花费的时间主要是由System.arraycopy方法决定的，它的时间复杂度为O(n)，所以ArrayList插入数据的时间复杂度为O(n)

ArrayList插入的示意图：

![ArrayList结构](/images/arraylist-5.webp)

#### 6. 插入集合 addAll(int index, Collection<? extends E> c)

```
public boolean addAll(int index, Collection<? extends E> c) {
    // 检查index的合法性
    rangeCheckForAdd(index);
    
    Object[] a = c.toArray();
    int numNew = a.length;
    // 进行可能需要的扩容
    ensureCapacityInternal(size + numNew);  // Increments modCount
    
    // 需要移动元素的个数
    int numMoved = size - index;
    if (numMoved > 0)
        // index后面的元素，往后移动numNew个位置
        System.arraycopy(elementData, index, elementData, index + numNew,
                         numMoved);
    // 把插入的结合插入到移动过后空出来的elementData的相应位置
    System.arraycopy(a, 0, elementData, index, numNew);
    // ArrayList的长度size增加numNew个
    size += numNew;
    return numNew != 0;
}
```

之前已经了解了添加集合和插入元素的只是，这里直接看上面的注释就可以了，下面是ArrayList插入集合的示意图：

举例，我们的ArrayList已经存在a~j这10个元素，现在又要在index=5的位置插入

![ArrayList结构](/images/arraylist-6.webp)

#### 7. 删除元素 remove(int index)

```
public E remove(int index) {
    rangeCheck(index);

    modCount++;
    E oldValue = elementData(index);

    int numMoved = size - index - 1;
    if (numMoved > 0)
        // index后面的元素，都往前挪动一个位置
        System.arraycopy(elementData, index+1, elementData, index,
                         numMoved);
     // 把最后ArrayList的最后一个元素设置为空
    elementData[--size] = null; // Let gc do its work

    return oldValue;
}
```

我们知道插入的操作原理了，那删除的原理也类似，把index位置以及后面的元素往前挪动一个位置(这里的往前挪动一个位置，也不是真正意义上的挪动，而是elementData[index-1] = elementData[index])，并把最后一个元素位置为null

示意图如下:

![ArrayList结构](/images/arraylist-7.webp)

因为需要移动size - index个元素，所以删除的时间复杂度为O(n)

#### 8. 查找 contains(Object o)

```
public boolean contains(Object o) {
    return indexOf(o) >= 0;
}

public int indexOf(Object o) {
    if (o == null) {
        for (int i = 0; i < size; i++)
            if (elementData[i]==null)
                return i;
    } else {
        for (int i = 0; i < size; i++)
            if (o.equals(elementData[i]))
                return i;
    }
    return -1;
}
```

查找的思想，就很简单粗暴了，直接遍历elementData数组，如果当前元素与待查找元素相同，则返回当前元素的下标位置，所以查找的时间复杂度为O(n)


### 总结

ArrayList是基于数组来实现的
ArrayList各种操作的时间复杂度如下

| 序号 |	操作 | 时间复杂度 |
|---|---|---|
| 1	| 增加 |	O(1) |
| 2	| 获取 | O(1) |
| 3	| 插入 | O(n) |
| 4	| 删除 |	O(n) |
| 5	| 查找 | O(n) |

由上可知，ArrayList比较适合存取比较多的操作；不太适合插入、删除、查找比较多的操作
