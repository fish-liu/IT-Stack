
<h2>Spring钩子接口</h2>

参考：[Spring（七）核心容器 - 钩子接口](https://www.cnblogs.com/loongk/p/12375708.html) [Spring钩子方法和钩子接口的使用详解](https://www.cnblogs.com/520playboy/p/10256122.html)

----------------------------------------------------

### 前言

Spring 提供了非常多的扩展接口，官方将这些接口称之为钩子，这些钩子会在特定的时间被回调，以此来增强 Spring 功能，众多优秀的框架也是通过扩展这些接口，来实现自身特定的功能，如 SpringBoot、mybatis 等。

### Aware 系列接口

Aware 从字面意思理解就是“知道”、“感知”的意思，是用来获取 Spring 内部对象的接口。Aware 自身是一个顶级接口，它有一系列子接口，在一个 Bean 中实现这些子接口并重写里面的 set 方法后，Spring 容器启动时，就会回调该 set 方法，而相应的对象会通过方法参数传递进去。我们以其中的 ApplicationContextAware 接口为例。

ApplicationContextAware

大部分 Aware 系列接口都有一个规律，它们以对象名称为前缀，获取的就是该对象，所以 ApplicationContextAware 获取的对象是 ApplicationContext 。

```
public interface ApplicationContextAware extends Aware {

	void setApplicationContext(ApplicationContext applicationContext) throws BeansException;
}
```

ApplicationContextAware 源码非常简单，其继承了 Aware 接口，并定义一个 set 方法，参数就是 ApplicationContext 对象，当然，其它系列的 Aware 接口也是类似的定义。其具体使用方式如下：

```java
public class Test implements ApplicationContextAware {
    
    private ApplicationContext applicationContext;
    
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
}
```

在 Spring 启动过程中，会回调 setApplicationContext 方法，并传入 ApplicationContext 对象，之后就可对该对象进行操作。其它系列的 Aware 接口也是如此使用。


以下是几种常用的 Aware 接口：

- BeanFactoryAware：获取 BeanFactory 对象，它是基础的容器接口。
- BeanNameAware：获取 Bean 的名称。
- EnvironmentAware：获取 Environment 对象，它表示整个的运行时环境，可以设置和获取配置属性。
- ApplicationEventPublisherAware：获取 ApplicationEventPublisher 对象，它是用来发布事件的。
- ResourceLoaderAware：获取 ResourceLoader 对象，它是获取资源的工具。


### InitializingBean接口和DisposableBean接口

#### InitializingBean接口

InitializingBean接口只有一个方法#afterPropertiesSet，作用是：当一个Bean实现InitializingBean，#afterPropertiesSet方法里面可以添加自定义的初始化方法或者做一些资源初始化操作(Invoked by a BeanFactory after it has set all bean properties supplied ==> "当BeanFactory 设置完所有的Bean属性之后才会调用#afterPropertiesSet方法")。

```java
public interface InitializingBean {

	void afterPropertiesSet() throws Exception;
}
```

#### DisposableBean接口

DisposableBean接口只有一个方法#destroy，作用是：当一个单例Bean实现DisposableBean，#destroy可以添加自定义的一些销毁方法或者资源释放操作(Invoked by a BeanFactory on destruction of a singleton ==>"单例销毁时由BeanFactory调用#destroy")

```java
public interface DisposableBean {

	void destroy() throws Exception;

}
```

![bean实例化过程](/images/bean实例化过程.png)


### BeanPostProcessor接口和BeanFactoryPostProcessor接口

一般我们叫这两个接口为Spring的Bean后置处理器接口,作用是为Bean的初始化前后提供可扩展的空间。

#### BeanPostProcessor接口

BeanPostProcessor 和 InitializingBean 有点类似，也是可以在 Bean 的生命周期执行自定义操作，一般称之为 Bean 的后置处理器，不同的是，BeanPostProcessor 可以在 Bean 初始化前、后执行自定义操作，且针对的目标也不同，InitializingBean 针对的是实现 InitializingBean 接口的 Bean，而 BeanPostProcessor 针对的是所有的 Bean。

```java
public interface BeanPostProcessor {

	// Bean 初始化前调用
	default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}

	// Bean 初始化后调用
	default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}
}
```

所有的 Bean 在初始化前、后都会回调接口中的 postProcessBeforeInitialization 和 postProcessAfterInitialization 方法，入参是当前正在初始化的 Bean 对象和 BeanName。值得注意的是 Spring 内置了非常多的 BeanPostProcessor ，以此来完善自身功能

#### BeanFactoryPostProcessor接口

BeanFactoryPostProcessor 是 Bean 工厂的后置处理器，一般用来修改上下文中的 BeanDefinition，修改 Bean 的属性值。可以对bean的定义（配置元数据）进行处理。也就是说，Spring IoC容器允许BeanFactoryPostProcessor在容器实际实例化任何其它的bean之前读取配置元数据，并有可能修改它

```java
public interface BeanFactoryPostProcessor {

    // 入参是一个 Bean 工厂：ConfigurableListableBeanFactory。该方法执行时，所有 BeanDefinition 都已被加载，但还未实例化 Bean。
    // 可以对其进行覆盖或添加属性，甚至可以用于初始化 Bean。
	void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException;
}
```

BeanFactoryPostProcessor 源码非常简单，其提供了一个 postProcessBeanFactory 方法，当所有的 BeanDefinition 被加载时，该方法会被回调。值得注意的是，Spring 内置了许多 BeanFactoryPostProcessor 的实现，以此来完善自身功能。

> BeanFactoryPostProcessor回调会先于BeanPostProcessor

### ImportSelector

ImportSelector 是一个较为重要的扩展接口，通过该接口可动态的返回需要被容器管理的类，不过一般用来返回外部的配置类。可在标注 @Configuration 注解的类中，通过 @Import 导入 ImportSelector 来使用。

```java
public interface ImportSelector {

	// 方法入参是注解的元数据对象，返回值是类的全路径名数组
	String[] selectImports(AnnotationMetadata importingClassMetadata);
}
```

selectImports 方法返回的是类的全路径名。

自定义 ImportSelector：

```java
public class TestImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        
        if (importingClassMetadata.hasAnnotation("")) {
            // 判断是否包含某个注解
        }
        
        // 返回 Test 的全路径名，Test 会被放入到 Spring 容器中
        return new String[]{"com.loong.diveinspringboot.test.Test"};
    }
}
```

selectImports 方法中可以针对通过 AnnotationMetadata 对象进行逻辑判断，AnnotationMetadata 存储的是注解元数据信息，根据这些信息可以动态的返回需要被容器管理的类名称。

```java
public class Test {
    public void hello() {
        System.out.println("Test -- hello");
    }
}
```

这里，我们没有对 Test 标注 @Component 注解，所以，Test 不会自动加入到 Spring 容器中。

```java
@SpringBootApplication
@Import(TestImportSelector.class)
public class Main {
    public static void main(String[] args) {
        SpringApplication springApplication = new SpringApplication();
        ConfigurableApplicationContext run = springApplication.run(Main.class);
        Test bean = run.getBean(Test.class);
        bean.hello();
    }
}
```

之后通过 @Import 导入自定义的 TestImportSelector ，前面也说过，@Import 一般配合 @Configuration 使用，而 @SpringBootApplication 中包含了 @Configuration 注解。之后，通过 getBean 方法从容器中获取 Test 对象，并调用 hello 方法。

```
2020-02-26 08:01:41.712  INFO 29546 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2020-02-26 08:01:41.769  INFO 29546 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2020-02-26 08:01:41.773  INFO 29546 --- [           main] com.loong.diveinspringboot.test.Main     : Started Main in 4.052 seconds (JVM running for 4.534)
Test -- hello
```

最终，结果正确输出。



### ImportBeanDefinitionRegistrar

该接口和 ImportSelector 类似，也是配合 @Import 使用，不过 ImportBeanDefinitionRegistrar 更为直接一点，它可以直接把 Bean 注册到容器中。

```java
public interface ImportBeanDefinitionRegistrar {

	public void registerBeanDefinitions(
			AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry);
}
```

入参除了注解元数据对象 AnnotationMetadata 外，还多了一个 BeanDefinitionRegistry 对象，该对象定义了关于 BeanDefinition 的一系列的操作，如：注册、移除、查询等。

自定义 ImportBeanDefinitionRegistrar：

```java
public class TestRegistrar implements ImportBeanDefinitionRegistrar {
    // 一般通过 AnnotationMetadata 进行业务判断，然后通过 BeanDefinitionRegistry 直接注册 Bean
    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        RootBeanDefinition beanDefinition = new RootBeanDefinition(Test.class);
        beanDefinition.setLazyInit(true);
        registry.registerBeanDefinition(Test.class.getName(), beanDefinition);
    }
}
```

这里，主要通过 BeanDefinitionRegistry 手动注册 Test 类的 BeanDefinition，并设置懒加载属性。

ImportSelector 和 ImportBeanDefinitionRegistrar 是实现 @Enable 模式注解的核心接口，而 @Enable 模式注解在 Spring、SpringBoot、SpringCloud 中被大量使用，其依靠这些注解来实现各种功能及特性，是较为重要的扩展接口



### BeanDefinitionRegistryPostProcessor

BeanDefinitionRegistryPostProcessor 接口可以看作是BeanFactoryPostProcessor和ImportBeanDefinitionRegistrar的功能集合，既可以获取和修改BeanDefinition的元数据，也可以实现BeanDefinition的注册、移除等操作。

```java
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor {

	void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;

}
```



### FactoryBean

FactoryBean 也是一种 Bean，不同于普通的 Bean，它是用来创建 Bean 实例的，属于工厂 Bean，不过它和普通的创建不同，它提供了更为灵活的方式，其实现有点类似于设计模式中的工厂模式和修饰器模式。
一般情况下，Spring通过反射机制利用bean的class属性指定实现类来实例化bean ，实例化bean过程比较复杂。FactoryBean接口就是为了简化此过程，把bean的实例化定制逻辑下发给使用者。

Spring 框架内置了许多 FactoryBean 的实现，它们在很多应用如(Spring的AOP、ORM、事务管理)及与其它第三框架(ehCache)集成时都有体现。

```java
public interface FactoryBean<T> {
	// 该方法会返回该 FactoryBean “生产”的对象实例，我们需要实现该方法以给出自己的对象实例化逻辑,如果isSingleton()返回true，则该实例会放到Spring容器中单实例缓存池中。
	T getObject() throws Exception;

	// Bean的类型
	Class<?> getObjectType();

	// 是否是单例
	default boolean isSingleton() {
		return true;
	}
}
```

自定义 FactoryBean:

```java
@Component
public class TestFactoryBean implements FactoryBean<Test> {
    @Override
    public Test getObject() throws Exception {

        // 这里可以灵活的创建 Bean，如：代理、修饰

        return new Test();
    }

    @Override
    public Class<?> getObjectType() {
        return null;
    }
}
```

Test 类：

```java
public class Test {
    public void hello() {
        System.out.println("Test -- hello");
    }
}
```

启动类：

```java
@SpringBootApplication
public class Main {
    public static void main(String[] args) {
        SpringApplication springApplication = new SpringApplication();
        ConfigurableApplicationContext run = springApplication.run(Main.class);
        Test bean = (Test) run.getBean("testFactoryBean");
        bean.hello();
    }
}
```

输出：

```
2020-02-27 23:16:00.334  INFO 32234 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2020-02-27 23:16:00.338  INFO 32234 --- [           main] com.loong.diveinspringboot.test.Main     : Started Main in 3.782 seconds (JVM running for 4.187)
Test -- hello
```

可以看到，启动类中 getBean 的参数是 testFactoryBean ，从这可以看出，当容器中的 Bean 实现了 FactoryBean 后，通过 getBean(String BeanName) 获取到的 Bean 对象并不是 FactoryBean 的实现类对象，而是这个实现类中的 getObject() 方法返回的对象。如果想获取 FactoryBean 的实现类，需通过这种方式：getBean(&BeanName)，在 BeanName 之前加上&。

> 注意一点：通过Spring容器的getBean()方法返回的不是FactoryBean本身，而是FactoryBean#getObject()方法所返回的对象，相当于FactoryBean#getObject()代理了getBean()方法。

### ApplicationListener

ApplicationListener 是 Spring 实现事件机制的核心接口，属于观察者设计模式，一般配合 ApplicationEvent 使用。在 Spring 容器启动过程中，会在相应的阶段通过 ApplicationContext 发布 ApplicationEvent 事件，之后所有的 ApplicationListener 会被回调，根据事件类型，执行不同的操作。

```java
public interface ApplicationListener<E extends ApplicationEvent> extends EventListener {

	void onApplicationEvent(E event);
}
```

在 onApplicationEvent 方法中，通过 instanceof 判断 event 的事件类型。

自定义 ApplicationListener：

```java
@Component
public class TestApplicationListener implements ApplicationListener {
    @Override
    public void onApplicationEvent(ApplicationEvent event) {
        if (event instanceof TestApplicationEvent) {
            TestApplicationEvent testApplicationEvent = (TestApplicationEvent) event;
            System.out.println(testApplicationEvent.getName());
        }
    }
}
```

当自定义的 TestApplicationListener 被回调时，判断当前发布的事件类型是否是自定义的 TestApplicationEvent，如果是则输出事件名称。

自定义 TestApplicationEvent：

```java
public class TestApplicationEvent extends ApplicationEvent {

    private String name;

    public TestApplicationEvent(Object source, String name) {
        super(source);
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

启动类：

```java
@SpringBootApplication
public class Main {
    public static void main(String[] args) {
        SpringApplication springApplication = new SpringApplication();
        ConfigurableApplicationContext run = springApplication.run(Main.class);
        run.publishEvent(new TestApplicationEvent(new Main(),"Test 事件"));
    }
}
```

通过 ApplicationContext 发布 TestApplicationEvent 事件。当然也可以在业务代码中通过 ApplicationContextAware 获取 ApplicationContext 发布事件。

结果：

```
2020-02-27 08:37:10.972  INFO 30984 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2020-02-27 08:37:11.026  INFO 30984 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2020-02-27 08:37:11.029  INFO 30984 --- [           main] com.loong.diveinspringboot.test.Main     : Started Main in 3.922 seconds (JVM running for 4.367)
Test 事件
```

ApplicationListener 也被 SpringBoot 进行扩展，来实现自身特定的事件机制

