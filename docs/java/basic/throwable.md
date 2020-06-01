
Java把异常作为一种类，当做对象来处理。所有异常类的基类是Throwable类，两大子类分别是Error和Exception。

- 系统错误由Java虚拟机抛出，用Error类表示。Error类描述的是内部系统错误，例如Java虚拟机崩溃。这种情况仅凭程序自身是无法处理的，在程序中也不会对Error异常进行捕捉和抛出。

- 异常（Exception）又分为RuntimeException(运行时异常)和CheckedException(检查时异常)，两者区别如下：

  - RuntimeException：程序运行过程中才可能发生的异常。一般为代码的逻辑错误。例如：类型错误转换，数组下标访问越界，空指针异常、找不到指定类等等。
  - CheckedException：编译期间可以检查到的异常，必须显式的进行处理（捕获或者抛出到上一层）。例如：IOException, FileNotFoundException等等。

先来看看java中异常的体系结构图解：

![异常](/images/throwable.png)
![异常](/images/throwable1.png)

首先说明一点，java中的Exception类的子类不仅仅只是像上图所示只包含IOException和RuntimeException这两大类，事实上Exception的子类很多很多，主要可概括为：运行时异常与非运行时异常。






