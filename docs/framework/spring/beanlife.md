
### Spring Bean的生命周期

了解 Spring 生命周期的意义就在于，可以利用 Bean 在其存活期间的指定时刻完成一些相关操作。这种时刻可能有很多，但一般情况下，会在 Bean 被初始化后和被销毁前执行一些相关操作。

Spring中的bean类型

- singleton

Spring 容器可以管理 singleton 作用域 Bean 的生命周期，在此作用域下，Spring 能够精确地知道该 Bean 何时被创建，何时初始化完成，以及何时被销毁。

- prototype 

而对于 prototype 作用域的 Bean，Spring 只负责创建，当容器创建了 Bean 的实例后，Bean 的实例就交给客户端代码管理，Spring 容器将不再跟踪其生命周期。每次客户端请求 prototype 作用域的 Bean 时，Spring 容器都会创建一个新的实例，并且不会管那些被配置成 prototype 作用域的 Bean 的生命周期。



Spring Bean的生命周期

http://c.biancheng.net/view/4261.html

Spring Bean的生命周期（非常详细）

https://www.cnblogs.com/zrtqsk/p/3735273.html


Spring中BeanFactory和ApplicationContext的生命周期及其区别详解

https://blog.csdn.net/qq_32651225/article/details/78323527