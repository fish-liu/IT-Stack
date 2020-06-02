
参考文章：https://www.cnblogs.com/xcmelody/p/10859704.html

https://www.cnkirito.moe/spi/

<h2>Java中的spi机制</h2>

--------------------------------

SPI全名为Service Provider Interface是JDK内置的一种服务提供发现机制,是Java提供的一套用来被第三方实现或者扩展的API，它可以用来启用框架扩展和替换组件。
Java中SPI机制主要思想是将装配的控制权移到程序之外，在模块化设计中这个机制尤其重要，其核心思想就是 解耦。

JAVA SPI = 基于接口的编程＋策略模式＋配置文件 的动态加载机制

![SPI](/images/spi.jpg)


#### Java SPI的具体约定如下：

- 当服务的提供者，提供了服务接口的一种实现之后，在jar包的META-INF/services/目录里同时创建一个以服务接口命名的文件。该文件里就是实现该服务接口的具体实现类。

- 而当外部程序装配这个模块的时候，就能通过该jar包META-INF/services/里的配置文件找到具体的实现类名，并装载实例化，完成模块的注入。

- 根据SPI的规范我们的服务实现类必须有一个无参构造方法。

为什么一定要在classes中的META-INF/services下呢？

JDK提供服务实现查找的一个工具类：java.util.ServiceLoader

在这个类里面已经写死

```
// 默认会去这里寻找相关信息
private static final String PREFIX = "META-INF/services/";
```


#### 常见的使用场景：

- JDBC加载不同类型的数据库驱动

- 日志门面接口实现类加载，SLF4J加载不同提供商的日志实现类

- Spring中大量使用了SPI,

  - 对servlet3.0规范
  - 对ServletContainerInitializer的实现
  - 自动类型转换Type Conversion SPI(Converter SPI、Formatter SPI)等

- Dubbo里面有很多个组件，每个组件在框架中都是以接口的形成抽象出来！具体的实现又分很多种，在程序执行时根据用户的配置来按需取接口的实现


#### 实现一个自定义的 SPI

**项目结构**

![SPI](/images/spi_1.png)

- invoker 是我们的用来测试的主项目。
- interface 是针对厂商和插件商定义的接口项目，只提供接口，不提供实现。
- good-printer,bad-printer 分别是两个厂商对 interface 的不同实现，所以他们会依赖于 interface 项目。

这个简单的 demo 就是让大家体验，在不改变 invoker 代码，只更改依赖的前提下，切换 interface 的实现厂商。

**interface 模块**

moe.cnkirito.spi.api.Printer

```java
public interface Printer {
    void print();
}
```

interface 只定义一个接口，不提供实现。规范的制定方一般都是比较牛叉的存在，这些接口通常位于 java，javax 前缀的包中。这里的 Printer 就是模拟一个规范接口。

**good-printer 模块**

good-printer\pom.xml

```
<dependencies>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>interface</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
</dependencies>
```

规范的具体实现类必然要依赖规范接口

moe.cnkirito.spi.api.GoodPrinter

```java
public class GoodPrinter implements Printer {
    public void print() {
        System.out.println("你是个好人 ~");
    }
}    
```

作为 Printer 规范接口的实现一

resources\META-INF\services\moe.cnkirito.spi.api.Printer

```
moe.cnkirito.spi.api.GoodPrinter
```

这里需要重点说明，每一个 SPI 接口都需要在自己项目的静态资源目录中声明一个 services 文件，文件名为实现规范接口的类名全路径，在此例中便是 moe.cnkirito.spi.api.Printer，在文件中，则写上一行具体实现类的全路径，在此例中便是 moe.cnkirito.spi.api.GoodPrinter。

这样一个厂商的实现便完成了。


**bad-printer 模块**

我们在按照和 good-printer 模块中定义的一样的方式，完成另一个厂商对 Printer 规范的实现。

bad-printer\pom.xml

```
<dependencies>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>interface</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
</dependencies>
```

moe.cnkirito.spi.api.BadPrinter

```java
public class BadPrinter implements Printer {

    public void print() {
        System.out.println("我抽烟，喝酒，蹦迪，但我知道我是好女孩 ~");
    }
}
```

resources\META-INF\services\moe.cnkirito.spi.api.Printer

```
moe.cnkirito.spi.api.BadPrinter
```

这样，另一个厂商的实现便完成了。


**invoker 模块**

这里的 invoker 便是我们自己的项目了。如果一开始我们想使用厂商 good-printer 的 Printer 实现，是需要将其的依赖引入。

```
<dependencies>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>interface</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>good-printer</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
</dependencies>
```

编写调用主类

```java
public class MainApp {


    public static void main(String[] args) {
        ServiceLoader<Printer> printerLoader = ServiceLoader.load(Printer.class);
        for (Printer printer : printerLoader) {
            printer.print();
        }
    }
}
```

ServiceLoader 是 java.util 提供的用于加载固定类路径下文件的一个加载器，正是它加载了对应接口声明的实现类。

打印结果 1

```
你是个好人 ~
```

如果在后续的方案中，想替换厂商的 Printer 实现，只需要将依赖更换

```
<dependencies>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>interface</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
    <dependency>
        <groupId>moe.cnkirito</groupId>
        <artifactId>bad-printer</artifactId>
        <version>1.0-SNAPSHOT</version>
    </dependency>
</dependencies>
```

调用主类无需变更代码，这符合开闭原则

打印结果 2

```
我抽烟，喝酒，蹦迪，但我知道我是好女孩 ~
```


#### ServiceLoader源码解析

```
// ServiceLoader实现了Iterable接口，可以遍历所有的服务实现者
public final class ServiceLoader<S> implements Iterable<S>{
    
     // 加载具体实现类信息的前缀
    private static final String PREFIX = "META-INF/services/";
    
    // 需要加载的接口
    // The class or interface representing the service being loaded
    private final Class<S> service;
    
    // 用于加载的类加载器
    // The class loader used to locate, load, and instantiate providers
    private final ClassLoader loader;
    
    // 创建ServiceLoader时采用的访问控制上下文
    // The access control context taken when the ServiceLoader is created
    private final AccessControlContext acc;
    
    // 用于缓存已经加载的接口实现类，其中key为实现类的完整类名
    // Cached providers, in instantiation order
    private LinkedHashMap<String,S> providers = new LinkedHashMap<>();
    
    // 用于延迟加载接口的实现类
    // The current lazy-lookup iterator
    private LazyIterator lookupIterator;
    
}
```

从ServiceLoader.load(IService.class)进入源码中

```
 public static <S> ServiceLoader<S> load(Class<S> service) {
    // 获取当前线程上下文的类加载器
    ClassLoader cl = Thread.currentThread().getContextClassLoader();
    return ServiceLoader.load(service, cl);
}
```

在ServiceLoader.load(service, cl)中

```
public static <S> ServiceLoader<S> load(Class<S> service,ClassLoader loader){
    // 返回ServiceLoader的实例
    return new ServiceLoader<>(service, loader);
}

private ServiceLoader(Class<S> svc, ClassLoader cl) {
    service = Objects.requireNonNull(svc, "Service interface cannot be null");
    loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
    acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
    reload();
}

public void reload() {
    // 清空已经缓存的加载的接口实现类
    providers.clear();
    // 创建新的延迟加载迭代器
    lookupIterator = new LazyIterator(service, loader);
}   

private LazyIterator(Class<S> service, ClassLoader loader) {
    // 指定this类中的 需要加载的接口service和类加载器loader
    this.service = service;
    this.loader = loader;
}
```

当我们通过迭代器获取对象实例的时候，首先在成员变量providers中查找是否有缓存的实例对象

如果存在则直接返回，否则则调用lookupIterator延迟加载迭代器进行加载

迭代器判断的代码如下

```
// 服务提供者查找的迭代器
public Iterator<S> iterator() {
    // 返回迭代器
    return new Iterator<S>() {
        // 查询缓存中是否存在实例对象
        Iterator<Map.Entry<String,S>> knownProviders
            = providers.entrySet().iterator();

        public boolean hasNext() {
            // 如果缓存中已经存在返回true
            if (knownProviders.hasNext())
                return true;
            // 如果不存在则使用延迟加载迭代器进行判断是否存在
            return lookupIterator.hasNext();
        }

        public S next() {
            // 如果缓存中存在则直接返回
            if (knownProviders.hasNext())
                return knownProviders.next().getValue();
            // 调用延迟加载迭代器进行返回
            return lookupIterator.next();
        }

        public void remove() {
            throw new UnsupportedOperationException();
        }

    };
}
```

LazyIterator的类加载

```
private class LazyIterator implements Iterator<S>
{

    // 服务提供者接口
    Class<S> service;
    // 类加载器
    ClassLoader loader;
    // 保存实现类的url
    Enumeration<URL> configs = null;
    // 保存实现类的全名
    Iterator<String> pending = null;
    // 迭代器中下一个实现类的全名
    String nextName = null;

    private LazyIterator(Class<S> service, ClassLoader loader) {
        this.service = service;
        this.loader = loader;
    }
    
     // 判断是否拥有下一个实例
    private boolean hasNextService() {
        
        // 如果拥有直接返回true
        if (nextName != null) {
            return true;
        }
        
        // 具体实现类的全名 ，Enumeration<URL> config
        if (configs == null) {
            try {
                String fullName = PREFIX + service.getName();
                if (loader == null)
                    configs = ClassLoader.getSystemResources(fullName);
                else
                    configs = loader.getResources(fullName);
            } catch (IOException x) {
                fail(service, "Error locating configuration files", x);
            }
        }
        while ((pending == null) || !pending.hasNext()) {
            if (!configs.hasMoreElements()) {
                return false;
            }
            
            // 转换config中的元素，或者具体实现类的真实包结构
            pending = parse(service, configs.nextElement());
        }
        // 具体实现类的包结构名
        nextName = pending.next();
        return true;
    }

    private S nextService() {
        if (!hasNextService())
            throw new NoSuchElementException();
        String cn = nextName;
        nextName = null;
        Class<?> c = null;
        try {
            // 加载类对象
            c = Class.forName(cn, false, loader);
        } catch (ClassNotFoundException x) {
            fail(service,
                 "Provider " + cn + " not found");
        }
        if (!service.isAssignableFrom(c)) {
            fail(service,
                 "Provider " + cn  + " not a subtype");
        }
        try {
            // 通过c.newInstance()实例化
            S p = service.cast(c.newInstance());
            // 将实现类加入缓存
            providers.put(cn, p);
            return p;
        } catch (Throwable x) {
            fail(service,
                 "Provider " + cn + " could not be instantiated",
                 x);
        }
        throw new Error();          // This cannot happen
    }

    public boolean hasNext() {
        if (acc == null) {
            return hasNextService();
        } else {
            PrivilegedAction<Boolean> action = new PrivilegedAction<Boolean>() {
                public Boolean run() { return hasNextService(); }
            };
            return AccessController.doPrivileged(action, acc);
        }
    }

    public S next() {
        if (acc == null) {
            return nextService();
        } else {
            PrivilegedAction<S> action = new PrivilegedAction<S>() {
                public S run() { return nextService(); }
            };
            return AccessController.doPrivileged(action, acc);
        }
    }

    public void remove() {
        throw new UnsupportedOperationException();
    }

}
```

**实现的流程如下：**

- 1 应用程序调用ServiceLoader.load方法

  ServiceLoader.load方法内先创建一个新的ServiceLoader，并实例化该类中的成员变量，包括：

  - loader(ClassLoader类型，类加载器)
  - acc(AccessControlContext类型，访问控制器)
  - providers(LinkedHashMap<String,S>类型，用于缓存加载成功的类)
  - lookupIterator(实现迭代器功能)

- 2 应用程序通过迭代器接口获取对象实例
  
  ServiceLoader先判断成员变量providers对象中(LinkedHashMap<String,S>类型)是否有缓存实例对象，如果有缓存，直接返回。

  如果没有缓存，执行类的装载，实现如下：

  - (1) 读取META-INF/services/下的配置文件，获得所有能被实例化的类的名称，值得注意的是，ServiceLoader可以跨越jar包获取META-INF下的配置文件，具体加载配置的实现代码如下：
    
    ```
    try {
        String fullName = PREFIX + service.getName();
        if (loader == null)
            configs = ClassLoader.getSystemResources(fullName);
        else
            configs = loader.getResources(fullName);
    } catch (IOException x) {
        fail(service, "Error locating configuration files", x);
    }
    ```
        
  - (2) 通过反射方法Class.forName()加载类对象，并用instance()方法将类实例化。
  - (3) 把实例化后的类缓存到providers对象中，(LinkedHashMap<String,S>类型） ，然后返回实例对象。

<!--
- 首先，ServiceLoader实现了Iterable接口，所以它有迭代器的属性，这里主要都是实现了迭代器的hasNext和next方法。这里主要都是调用的lookupIterator的相应hasNext和next方法，lookupIterator是懒加载迭代器。

- 其次，LazyIterator中的hasNext方法，静态变量PREFIX就是”META-INF/services/”目录，这也就是为什么需要在classpath下的META-INF/services/目录里创建一个以服务接口命名的文件。

- 最后，通过反射方法Class.forName()加载类对象，并用newInstance方法将类实例化，并把实例化后的类缓存到providers对象中，(LinkedHashMap<String,S>类型） 然后返回实例对象。
-->

#### 总结

**优点**

- 使用Java SPI机制的优势是实现解耦，使得第三方服务模块的装配控制的逻辑与调用者的业务代码分离，而不是耦合在一起。应用程序可以根据实际业务情况启用框架扩展或替换框架组件。

**缺点**

- 多个并发多线程使用ServiceLoader类的实例是不安全的

- 虽然ServiceLoader也算是使用的延迟加载，但是基本只能通过遍历全部获取，也就是接口的实现类全部加载并实例化一遍。

- 不能按需加载，需要遍历所有的实现，并实例化，然后在循环中才能找到我们需要的实现。如果不想用某些实现类，或者某些类实例化很耗时，它也被载入并实例化了，这就造成了浪费。


针对以上的不足点，我们在SPI机制选择时，可以考虑使用dubbo实现的SPI机制。

具体参考:  http://dubbo.apache.org/zh-cn/blog/introduction-to-dubbo-spi.html



