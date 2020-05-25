
## 目录

 ### [jvm](/java/jvm1.md)
  
 ### [多线程](/java/threads.md)


CAS 具有原子性，他的原子性由cpu硬件指令实现保证，即 使用JNI调用native方法 调用有C++ 编写的硬件级别指令，JDK中提供了Unsafe类执行这些操作。