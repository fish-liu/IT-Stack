
<h2>String类的一些知识点</h2>

-------------------------------------------------------------

### 基础知识

**String对象的解析**

String对象实际上就是一个char数组，包括三个属性域：

```
private final char value[];  //字符数组
private final int offset;      //string对象在字符数组中的开始位置
private final int count;      //字符数组的长度 
```

> 需要注意 offset和count在1.7及以后版本中已经没有了。


String 有 3 个基本特点：

- 不变性；

- 针对常量池的优化；

- 类的 final 定义。

不变性指的是 String 对象一旦生成，则不能再对它进行改变。String 的这个特性可以泛化成不变 (immutable) 模式，即一个对象的状态在对象被创建之后就不再发生变化。不变模式的主要作用在于当一个对象需要被多线程共享，并且访问频繁时，可以省略同步和锁等待的时间，从而大幅提高系统性能。

针对常量池的优化指的是当两个 String 对象拥有相同的值时，它们只引用常量池中的同一个拷贝，当同一个字符串反复出现时，这个技术可以大幅度节省内存空间。


**StringBuffer 和 StringBuilder**

StringBuffer 和 StringBuilder 都实现了 AbstractStringBuilder 抽象类，拥有几乎相同的对外借口，两者的最大不同在于 StringBuffer 对几乎所有的方法都做了同步，而 StringBuilder 并没有任何同步。由于方法同步需要消耗一定的系统资源，因此，StringBuilder 的效率也好于 StringBuffer。 但是，在多线程系统中，StringBuilder 无法保证线程安全，不能使用。

> StringBuffer 是线程安全的、  StringBuilder 不是线程安全的。

### 字符串常量池

> 参考： [Java 字符串常量池介绍](https://javadoop.com/post/string)

在 Java 世界中，构造一个 Java 对象是一个相对比较重的活，而且还需要垃圾回收，而缓存池就是为了缓解这个问题的。

我们来看下基础类型的包装类的缓存，Integer 默认缓存 -128 ~ 127 区间的值，Long 和 Short 也是缓存了这个区间的值，Byte 只能表示 -127 ~ 128 范围的值，全部缓存了，Character 缓存了 0 ~ 127 的值。Float 和 Double 没有缓存的意义。

> Integer 可通过设置 java.lang.Integer.IntegerCache.high 扩大缓存区间

String 不是基础类型，但是它也有同样的机制，通过 String Pool 来缓存 String 对象。假设 "Java" 这个字符串我们会在应用程序中使用多次，我们肯定不希望在每次使用到的时候，都重新在堆中创建一个新的对象。

> 当然，之所以 Integer、Long、String 这些类的对象可以缓存，是因为它们是不可变类

基础类型包装类的缓存池使用一个数组进行缓存，而 String 类型，JVM 内部使用 HashTable 进行缓存，我们知道，HashTable 的结构是一个数组，数组中每个元素是一个链表。和我们平时使用的 HashTable 不同，JVM 内部的这个 HashTable 是不可以动态扩容的。

![字符串常量池](/images/stringpool.png)

#### 创建和回收

当我们在程序中使用双引号来表示一个字符串时，这个字符串就会进入到 String Pool 中。当然，这里说的是已被加载到 JVM 中的类。

> 这是一个不够严谨的说法，请参见评论区的讨论。

另外，就是 String#intern() 方法，这个方法的作用就是：

- 如果字符串未在 Pool 中，那么就往 Pool 中增加一条记录，然后返回 Pool 中的引用。
- 如果已经在 Pool 中，直接返回 Pool 中的引用。

只要 String Pool 中的 String 对象对于 GC Roots 来说不可达，那么它们就是可以被回收的。

如果 Pool 中对象过多，可能导致 YGC 变长，因为 YGC 的时候，需要扫描 String Pool，可以看看笨神大佬的文章《[JVM源码分析之String.intern()导致的YGC不断变长](http://lovestblog.cn/blog/2016/11/06/string-intern/)》。

#### 讨论 String Pool 的实现

**1、首先，我们先考虑 String Pool 的空间问题。**

在 Java 6 中，String Pool 置于 PermGen Space 中，PermGen 有一个问题，那就是它是一个固定大小的区域，虽然我们可以通过 -XX:MaxPermSize=N 来设置永久代的空间大小，但是不管我们设置成多少，它终归是固定的。

所以，在 Java 6 中，我们应该尽量小心使用 String.intern() 方法，否则容易导致 OutOfMemoryError。

到了 Java 7，大佬们已经着手去掉 PermGen Space 了，首先，就是将 String Pool 移到了堆中。

把 String Pool 放到堆中，即使堆的大小也是固定的，但是这个时候，对于应用调优工作，只需要调整堆大小就行了。

到了 Java 8，PermGen 已经被彻底废弃，出现了堆外内存区域 MetaSpace，String Pool 相应的从堆转移到了 MetaSpace 中。

在 Java 8 中，String Pool 依然还是在 Heap Space 中。感谢评论区的读者指出错误。大家可以看一下我后面写的关于 MetaSpace 的文章，那篇文章深入分析了 MetaSpace 的构成。

**2、其次，我们再讨论 String Pool 的实现问题。**

前面我们说了 String Pool 使用一个 HashTable 来实现，这个 HashTable **不可以扩容**，也就意味着极有可能出现单个 bucket 中的链表很长，导致性能降低。

在 Java 6 中，这个 HashTable 固定的 bucket 数量是 1009，后来添加了选项（**-XX:StringTableSize=N**）可以配置这个值。到 Java 7（7u40），大佬们提高了这个默认值到 60013，Java 8 依然也是使用这个值，对于绝大部分应用来说，这个值是足够用的。当然，如果你会在代码中大量使用 String#intern()，那么有必要手动设置一下这个值。

> 为什么是 1009，而不是 1000 或者 1024？因为 1009 是质数，有利于达到更好的散列。60013 同理。

 JVM 内部的 HashTable 是不扩容的，但是不代表它不 rehash，它会在发现散列不均匀的时候进行 rehash，这里不展开介绍。

**3、观察 String Pool 的使用情况。**

JVM 提供了 `-XX:+PrintStringTableStatistics` 启动参数来帮助我们获取统计数据。

遗憾的是，只有在 JVM 退出的时候，JVM 才会将统计数据打印出来，JVM 没有提供接口给我们实时获取统计数据。

```
SymbolTable statistics:
Number of buckets       :     20011 =    160088 bytes, avg   8.000
Number of entries       :     10923 =    262152 bytes, avg  24.000
Number of literals      :     10923 =    425192 bytes, avg  38.926
Total footprint         :           =    847432 bytes
Average bucket size     :     0.546
Variance of bucket size :     0.545
Std. dev. of bucket size:     0.738
Maximum bucket size     :         6
# 看下面这部分：
StringTable statistics:
Number of buckets       :     60003 =    480024 bytes, avg   8.000
Number of entries       :   4000774 =  96018576 bytes, avg  24.000
Number of literals      :   4000774 = 1055252184 bytes, avg 263.762
Total footprint         :           = 1151750784 bytes
Average bucket size     :    66.676
Variance of bucket size :    19.843
Std. dev. of bucket size:     4.455
Maximum bucket size     :        84
```

统计数据中包含了 buckets 的数量，总的 String 对象的数量，占用的总空间，单个 bucket 的链表平均长度和最大长度等。

上面的数据是在 Java 8 的环境中打印出来的，Java 7 的信息稍微少一些，主要是没有 footprint 的数据：

`
StringTable statistics:
Number of buckets       :   60003
Average bucket size     :      67
Variance of bucket size :      20
Std. dev. of bucket size:       4
Maximum bucket size     :      84
`

#### 测试 String Pool 的性能

接下来，我们来跑个测试，测试下 String Pool 的性能问题，并讨论 -XX:StringTableSize=N 参数的作用。

我们将使用 String#intern() 往字符串常量池中添加 400万 个不同的长字符串。

```
package com.javadoop;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.WeakHashMap;

public class StringTest {

    public static void main(String[] args) {
        test(4000000);
    }

    private static void test(int cnt) {
        final List<String> lst = new ArrayList<String>(1024);
        long start = System.currentTimeMillis();
        for (int i = 0; i < cnt; ++i) {
            final String str = "Very very very very very very very very very very very very very very " +
                    "very long string: " + i;
            lst.add(str.intern());

            if (i % 200000 == 0) {
                System.out.println(i + 200000 + "; time = " + (System.currentTimeMillis() - start) / 1000.0 + " sec");
                start = System.currentTimeMillis();
            }
        }
        System.out.println("Total length = " + lst.size());
    }
}
```

我们每插入 20万 条数据，输出一次耗时。

```
# 编译
javac -d . StringTest.java
# 使用默认 table size (60013) 运行一次
java -Xms2g -Xmx2g com.javadoop.StringTest
# 设置 table size 为 400031，再运行一次
java -Xms2g -Xmx2g -XX:StringTableSize=400031 com.javadoop.StringTest
```

![stringpool2](/images/stringpool2.png)

从左右两部分数据可以很直观看出来，插入的性能主要取决于链表的平均长度。当链表平均长度为 10 的时候，我们看到性能是几乎没有任何损失的。

还是那句话，根据自己的实际情况，考虑是否要设置 -XX:StringTableSize=N，还是使用默认值。


#### 讨论自建 String Pool

这一节我们来看下自己使用 HashMap 来实现 String Pool。

这里我们需要使用 WeakReference：

```
private static final WeakHashMap<String, WeakReference<String>> pool
            = new WeakHashMap<String, WeakReference<String>>(1024);

private static String manualIntern(final String str) {
    final WeakReference<String> cached = pool.get(str);
    if (cached != null) {
        final String value = cached.get();
        if (value != null) {
            return value;
        }
    }
    pool.put(str, new WeakReference<String>(str));
    return str;
}
```

我们使用 1000 * 1000 * 1000 作为入参 cnt 的值进行测试，分别测试 [1] 和 [2]：

```
private static void test(int cnt) {
    final List<String> lst = new ArrayList<String>(1024);
    long start = System.currentTimeMillis();
    for (int i = 0; i < cnt; ++i) {
          // [1]
        lst.add(String.valueOf(i).intern());
        // [2]
        // lst.add(manualIntern(String.valueOf(i)));

        if (i % 200000 == 0) {
            System.out.println(i + 200000 + "; time = " + (System.currentTimeMillis() - start) / 1000.0 + " sec");
            start = System.currentTimeMillis();
        }
    }
    System.out.println("Total length = " + lst.size());
}
```

测试结果，2G 的堆大小，如果使用 String#intern()，大概在插入 3000万 数据的时候，开始进入大量的 FullGC。

而使用自己写的 manualIntern()，大概到 1400万 的时候，就已经不行了。

没什么结论，如果要说点什么的话，那就是不要自建 String Pool，没必要。


#### 小结

记住有两个 JVM 参数可以设置：-XX:StringTableSize=N、-XX:+PrintStringTableStatistics

StringTableSize，在 Java 6 中，是 1009；在 Java 7 和 Java 8 中，默认都是 60013，如果有必要请自行扩大这个值。



### substring方法引发的内存泄漏

> 参考文章：[Java中由substring方法引发的内存泄漏](https://honeypps.com/java/java-out-of-memory-through-substring-method) 和 [Java内存泄漏-------JDK6与JDK7里的subString()方法](https://blog.csdn.net/rap_libai/article/details/78772287)

在Java中我们无须关心内存的释放，JVM提供了内存管理机制，有垃圾回收器帮助回收不需要的对象。但实际中一些不当的使用仍然会导致一系列的内存问题，常见的就是内存泄漏和内存溢出

- 内存溢出（out of memory ） ：通俗的说就是内存不够用了，比如在一个无限循环中不断创建一个大的对象，很快就会引发内存溢出。

- 内存泄漏（leak of memory） ：是指为一个对象分配内存之后，在对象已经不在使用时未及时的释放，导致一直占据内存单元，使实际可用内存减少，就好像内存泄漏了一样。


substring(int beginIndex, int endndex )是String类的一个方法，但是这个方法在JDK6和JDK7中的实现是完全不同的（虽然它们都达到了同样的效果）。了解它们实现细节上的差异，能够更好的帮助你使用它们，因为在JDK1.6中不当使用substring会导致严重的内存泄漏问题。

#### 1、substring的作用

substring(int beginIndex, int endIndex)方法返回一个子字符串,从父字符串的beginIndex开始，结束于endindex-1。父字符串的下标从0开始，子字符串包含beginIndex而不包含endIndex。

```
String x= "abcdef";
x= str.substring(1,3);
System.out.println(x);
```

上述程序的输出是“bc”

#### 2、实现原理

**JDK6中subString的实现** 

String对象被当作一个char数组来存储，在String类中有3个域：char[] value、int offset、int count，分别用来存储真实的字符数组，数组的起始位置，String的字符数。由这3个变量就可以决定一个字符串。当substring方法被调用的时候，它会创建一个新的字符串，但是上述的char数组value仍然会使用原来父数组的那个value。父数组和子数组的唯一差别就是count和offset的值不一样

> 在JDK6中subString是是通过改变offset和count来创建一个新的String对象，value相当于一个仓库，还是用的父String的。

JDK6中对subString实现的源码：

```
public String substring(int beginIndex, int endIndex) {
  if (beginIndex < 0) {
      throw new StringIndexOutOfBoundsException(beginIndex);
  }
  if (endIndex > count) {
      throw new StringIndexOutOfBoundsException(endIndex);
  }
  if (beginIndex > endIndex) {
      throw new StringIndexOutOfBoundsException(endIndex - beginIndex);
  }
  return ((beginIndex == 0) && (endIndex == count)) ? this :
      new String(offset + beginIndex, endIndex - beginIndex, value); 
}


String(int offset, int count, char value[]) {
  this.value = value;
  this.offset = offset;
  this.count = count;
}
```

引发的内存泄漏泄漏情况：

```
String str = "abcdefghijklmnopqrst";
String sub = str.substring(1, 3);
str = null;
```

![JDK6中subString的实现](/images/jdk6-substring.png)

在这里，虽然str1为null，但是由于str1和str2之前指向的对象用的是同一个value数组，导致第一个String对象无法被GC，这也就是内存泄漏。

解决方案：

```
String str = "abcdefghijklmnopqrst";
String sub = str.substring(0, 2)+"";
str = null;
```

利用的就是字符串的拼接技术，它会创建一个新的字符串，这个新的字符串会使用一个新的内部char数组存储自己实际需要的字符，这样父数组的char数组就不会被其他引用，令str=null，在下一次GC回收的时候会回收整个str占用的空间。

> 通过产生新的字符串对象，拥有新的value数组。



**JDK7中subString的实现**

在JDK7中，改进了subString方法，让它在方法内创建了一个新的char数组，用于存放value，也就解决了内存泄漏的问题。

源码如下：

```
public String substring(int beginIndex, int endIndex) {
    if (beginIndex < 0) {
      throw new StringIndexOutOfBoundsException(beginIndex);
    }
    if (endIndex > value.length) {
      throw new StringIndexOutOfBoundsException(endIndex);
    }
    int subLen = endIndex - beginIndex;
    if (subLen < 0) {
      throw new StringIndexOutOfBoundsException(subLen);
    }
    return ((beginIndex == 0) && (endIndex == value.length)) ? this
        : new String(value, beginIndex, subLen);
}

public String(char value[], int offset, int count) {
    if (offset < 0) {
      throw new StringIndexOutOfBoundsException(offset);
    }
    if (count < 0) {
      throw new StringIndexOutOfBoundsException(count);
    }
    // Note: offset or count might be near -1>>>1.
    if (offset > value.length - count) {
      throw new StringIndexOutOfBoundsException(offset + count);
    }
    this.value = Arrays.copyOfRange(value, offset, offset+count);
}

// Arrays类的copyOfRange方法：
public static char[] copyOfRange(char[] original, int from, int to) {
        int newLength = to - from;
        if (newLength < 0)
            throw new IllegalArgumentException(from + " > " + to);
        char[] copy = new char[newLength];   //是创建了一个新的char数组
        System.arraycopy(original, from, copy, 0,
                         Math.min(original.length - from, newLength));
        return copy;
}

```

![JDK7中subString的实现](/images/jdk7-substring.png)



### 字符串操作优化

> 参考文章:[Java 程序优化：字符串操作、基本运算方法等优化策略](https://honeypps.com/java/java-program-optimize/)

#### 合并字符串

由于 String 是不可变对象，因此，在需要对字符串进行修改操作时 (如字符串连接、替换)，String 对象会生成新的对象，所以其性能相对较差。但是 JVM 会对代码进行彻底的优化，将多个连接操作的字符串在编译时合成一个单独的长字符串。针对超大的 String 对象，我们采用 String 对象连接、使用 concat 方法连接、使用 StringBuilder 类等多种方式，代码如清单 8 所示。








