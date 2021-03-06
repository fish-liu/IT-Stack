
本文转载自 ：https://www.jianshu.com/p/5efed51d1ecc

https://blog.csdn.net/qq_25343557/article/details/89110319

平衡二叉树

-------------------

二叉排序树，它使得查找数据的次数减少，但是这是基于左右子树高度相差不大的情况，如果所有数据全都在左子树（右子树），优点就不存在了。所以需要想办法使得一个树在插入数据和删除数据的过程中能自己保持左右子树高度一致，这就是平衡二叉树

![平衡二叉树](/images/bt-tree1.png)


### 定义

平衡二叉树又叫AVL树（三个人名词的缩写），是一种特殊的二叉排序树。其左右子树都是平衡二叉树，但左右子树的高度之差不超过1。即以树中所有节点为树根时，左右字数的高度之差不超过1


### 平衡因子

为了描述左右子树的高度之差，引入这个定义。平衡因子表示为其左子树的高度减去右子树高度的差值【平衡二叉树的平衡因子取值应该在-1、0、1之间】。

![平衡二叉树](/images/bt-tree2.png)


### 平衡二叉树的调整