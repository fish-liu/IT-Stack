
面试题汇总

--------------------------

**问题：判断链表中是否有环？**

参考：https://www.cnblogs.com/yorkyang/p/10876604.html

参考知识点：

快慢指针，就是有两个指针fast和slow，开始的时候两个指针都指向链表头head，然后在每一步操作中slow向前走一步即：slow = slow->next，而fast每一步向前两步即：fast = fast->next->next。
由于fast要比slow移动的快，如果有环，fast一定会先进入环，而slow后进入环。当两个指针都进入环之后，经过一定步的操作之后二者一定能够在环上相遇，并且此时slow还没有绕环一圈，也就是说一定是在slow走完第一圈之前相遇。


**问题：链表相关的面试问题**

参考：https://www.jianshu.com/p/6a6dac4db7d2

找出单链表的倒数第K个元素（仅允许遍历一遍链表）

找出单链表的中间元素（仅允许遍历一遍链表）

如何知道环的长度？

如何找到环的入口？


**问题：为什么MongoDB使用B-Tree，Mysql使用B+Tree ?**

https://www.jianshu.com/p/564b23e68b18







