
java 中的常用集合

--------------------------------

### JAVA中的集合

- Collection。一个独立元素的序列，这些元素都服从一条或多条规则。List必须按照插入的顺序保存元素，而Set不能有重复元素。Queue按照排队规则来确定对象产生的顺序。

![集合](/images/collection.png)

待整理： http://crazyfzw.github.io/2018/08/30/the-diff-ArrayList-Vector-LinkedList/#more

- Map。一组成对的“键值对”对象，允许你使用键来查找值。映射表让我们能够使用一个对象来查找另一个对象，就像“字典”一样。


一, Collection接口
(1). collection接口的成员方法
​ 增加: boolean add(E e)
​ 删除: boolean remove(Object o)
​ 清空: void clear()
​ 包含: boolean contains(Object o)
​ 判断为空: boolean isEmpty()
​ 容量: int size()

​ boolean addAll(Collection c)
​ boolean removeAll(Collection c)
​ boolean containsAll(Collection c)
​ boolean retainAll(Collection c)

(2). Object[] toArray()
​ 把集合转成数组，可以实现集合的遍历.

(3). Iterator iterator()
​ 迭代器，集合的专用遍历方式.

使用方法iterator()要求容器返回一个Iterator

boolean hasNext() 检查是否有下一个元素

E next() 获取下一个元素

remove() 将迭代器新进返回的元素删除


#### List

ArrayList

LinkedList

Vector

#### Set

HashSet

LinkedHashSet

TreeSet


#### Queue

ArrayBlockQueue

PriorityBlockingQueue

LinkedBlockingQueue


### 常用集合对比


https://www.jianshu.com/p/64f4a1089dc1

jdk1.7和1.8的Hashmap区别
1.jdk1.7中发生hash冲突新节点采用头插法，1.8采用的为尾插法

2.1.7采用数组+链表，1.8采用的是数组+链表+红黑树

3.1.7在插入数据之前扩容，而1.8插入数据成功之后扩容



### 源码解析

#### ArrayList


#### LinkedList


[CopyOnWriteArrayList](java/collection/copyonwritearraylist.md)

[Hashtable](java/collection/hashtable.md)

[HashMap](java/collection/hashmap.md)

[ConcurrentHashMap](java/collection/concurrenthashmap.md)










