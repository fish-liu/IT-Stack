
Spring IOC 容器源码分析

参考文章：https://javadoop.com/post/spring-ioc  、 https://blog.csdn.net/qq_34203492/article/details/83865450

Spring IOC 源码分析直接使用ApplicationContext的实现类 ClassPathXmlApplicationContext来分析。

![Spring容器高层视图](/images/spring-load.jpg)

![Spring容器高层视图](/images/beanfactory.png.jpg)

![Spring容器高层视图](/images/applicationcontext.png)


```
// 启动demo
public static void main(String[] args) {
    ApplicationContext context = new ClassPathXmlApplicationContext("classpath:applicationfile.xml");
}
```

由上面的继承关系可知，ClassPathXmlApplicationContext 经过好几次继承才到 ApplicationContext 接口

ClassPathXmlApplicationContext 源码

```
public class ClassPathXmlApplicationContext extends AbstractXmlApplicationContext {
  private Resource[] configResources;

  // 如果已经有 ApplicationContext 并需要配置成父子关系，那么调用这个构造方法
  public ClassPathXmlApplicationContext(ApplicationContext parent) {
    super(parent);
  }
  ...
  public ClassPathXmlApplicationContext(String[] configLocations, boolean refresh, ApplicationContext parent)
      throws BeansException {

    super(parent);
    // 根据提供的路径，处理成配置文件数组(以分号、逗号、空格、tab、换行符分割)
    setConfigLocations(configLocations);
    if (refresh) {
      refresh(); // 核心方法
    }
  }
    ...
}
```

了解一下ApplicationContext 的大体结构。

- ApplicationContext 继承了ListableBeanFactory，这个ListableBeanFactory接口它可以获取多个bean，我们看BeanFactory接口的源码可以发现，BeanFactory的接口都是获取单个bean的

- 同时ApplicationContext 还继承了HierarchicalBeanFactory接口，这个接口可以在应用这起多个BeanFactory，然后将多个BeanFactory设置父子关系

- ApplicationContext 接口中的最后一个方法：AutowireCapableBeanFactory getAutowireCapableBeanFactory() throws IllegalStateException; 他的返回值是AutowireCapableBeanFactory，这个接口就是用来自动装配Bean的

然后我们回到上面的 new ClassPathXmlApplicationContext("classpath:application.xml")构造方法。

先看上面构造方法那个源码，setConfigLocations(configLocations);是根据提供的路径，处理成配置文件数组(以分号、逗号、空格、tab、换行符分割)，

然后就到了重点的refresh(); 这个refresh();方法可以用来重新初始化ApplicationContext 。

> 这里简单说下为什么是 refresh()，而不是 init() 这种名字的方法。因为 ApplicationContext 建立起来以后，其实我们是可以通过调用 refresh() 这个方法重建的，refresh() 会将原来的 ApplicationContext 销毁，然后再重新执行一次初始化操作。

核心方法refresh()

```
// https://blog.csdn.net/yjn1995/article/details/94977777
@Override
public void refresh() throws BeansException, IllegalStateException {

    //startupShutdownMonitor对象在spring环境刷新和销毁的时候都会用到，确保刷新和销毁不会同时执行
    synchronized (this.startupShutdownMonitor) {
        
        // 准备工作，例如记录事件，设置标志，检查环境变量等，并有留给子类扩展的位置，用来将属性加入到applicationContext中
        prepareRefresh();

        /* 创建beanFactory，这个对象作为applicationContext的成员变量，可以被applicationContext拿来用,
         * 
         * 这步比较关键，这步完成后，配置文件就会解析成一个个 Bean 定义，注册到 BeanFactory 中，
         * 当然，这里说的 Bean 还没有初始化，只是配置信息都提取出来了，
         * 注册也只是将这些信息都保存到了注册中心(说到底核心是一个 beanName-> beanDefinition 的 map)
         */ 
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // 对beanFactory做一些设置，设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor，手动注册几个特殊的 bean
        prepareBeanFactory(beanFactory);

        try {
            // 子类扩展用，可以设置bean的后置处理器（bean在实例化之后这些后置处理器会执行）
            postProcessBeanFactory(beanFactory);

            // 执行beanFactory后置处理器（有别于bean后置处理器处理bean实例，beanFactory后置处理器处理bean定义）
            invokeBeanFactoryPostProcessors(beanFactory);

            // 将所有的bean的后置处理器排好序，但不会马上用，bean实例化之后会用到
            registerBeanPostProcessors(beanFactory);

            // 初始化国际化服务
            initMessageSource();

            // 创建事件广播器
            initApplicationEventMulticaster();

            // 空方法，留给子类自己实现的，在实例化bean之前做一些ApplicationContext相关的操作
            onRefresh();

            // 注册一部分特殊的事件监听器，剩下的只是准备好名字，留待bean实例化完成后再注册
            registerListeners();

            // 单例模式的bean的实例化、成员变量注入、初始化等工作都在此完成
            finishBeanFactoryInitialization(beanFactory);

            // applicationContext刷新完成后的处理，例如生命周期监听器的回调，广播通知等
            finishRefresh();
        }

        catch (BeansException ex) {
            logger.warn("Exception encountered during context initialization - cancelling refresh attempt", ex);

            // 刷新失败后的处理，主要是将一些保存环境信息的集合做清理
            destroyBeans();

            // applicationContext是否已经激活的标志，设置为false
            cancelRefresh(ex);

            // Propagate exception to caller.
            throw ex;
        }
        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
        
    }
}

```












Spring基于@Configuration的类配置的内部源码实现

https://blog.csdn.net/u010013573/article/details/86663467


