
<h2>两数相加（Add Two Numbers）</h2>

Medium、LinkedList

--------------------------------------

#### 题目要求

给定两个非空链表来表示两个非负整数。位数按照逆序方式存储，它们的每个节点只存储单个数字。将两数相加返回一个新的链表。(你可以假设除了数字 0 之外，这两个数字都不会以零开头。)


#### 示例

Input: (2 -> 4 -> 3) + (5 -> 6 -> 4)

Output: 7 -> 0 -> 8

Explanation: 342 + 465 = 807.


#### 解法

```java
public class Solution1{
    
    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        
        ListNode result = new ListNode(0);
        
        ListNode tmp = result;
        int sum = 0;
        
        while (l1 != null || l2 != null) {
            sum /= 10;
            if (l1 != null) {
                sum += l1.val;
                l1 = l1.next;
            }
            if (l2 != null) {
                sum += l2.val;
                l2 = l2.next;
            }
            tmp.next = new ListNode(sum % 10);
            tmp = tmp.next;
        }
        if (sum / 10 == 1) {
            tmp.next = new ListNode(1);//this means there's a carry, so we add additional 1, e.g. [5] + [5] = [0, 1]
        }
        
        return result.next;
    }
    
    /**
     *  ListNode 数据结构
     */
    class ListNode {
        
        public int val;
        
        public ListNode next;
    
        public ListNode(int i) {
            this.val = i;
        }
    
        public int val() {
            return val;
        }
        
    }
    
}



```









