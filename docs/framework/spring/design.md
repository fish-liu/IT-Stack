
参考：https://zhuanlan.zhihu.com/p/29344811   
https://www.jianshu.com/p/f8d560962a68 
https://javadoop.com/post/spring-ioc

### 整体设计

#### Spring容器高层视图

- Spring 启动时读取应用程序提供的Bean配置信息，并在Spring容器中生成一份相应的Bean配置注册表，然后根据这张注册表实例化Bean，装配好Bean之间的依赖关系，为上层应用提供准备就绪的运行环境。

![Spring容器高层视图](/images/spring-load.jpg)

Bean缓存池：HashMap实现


- Spring 通过一个配置文件描述 Bean 及 Bean 之间的依赖关系，利用 Java 语言的反射功能实例化 Bean 并建立 Bean 之间的依赖关系。Sping的IoC容器在完成这些底层工作的基础上，还提供了Bean实例缓存，生命周期管理，Bean实例代理，事件发布，资源装载等高级服务。


- Bean工厂（com.springframework.beans.factory.BeanFactory）是Spring框架最核心的接口，它提供了高级IoC的配置机制。BeanFactory使管理不同类型的Java对象成为可能，应用上下文（com.springframework.context.ApplicationContext）建立在BeanFactory基础之上，提供了更多面向应用的功能，它提供了国际化支持和框架事件体系，更易于创建实际应用。我们一般称BeanFactory为IoC容器，而称ApplicationContext为应用上下文。

>BeanFactory 是 Spring 框架的基础设施，面向 Spring 本身；
>ApplicationContext 面向使用 Spring 框架的开发者，几乎所有的应用场合我们都直接使用 ApplicationContext 而非底层的 BeanFactory。


#### BeanFactory 

BeanFactory，从名字上也很好理解，生产 bean 的工厂，它负责生产和管理各个 bean 实例。

![BeanFactory体系结构](/images/beanfactory.png)

- ListableBeanFactory:该接口定义了访问容器中Bean基本信息的若干方法，如查看Bean的个数，获取某一个类型Bean的配置名，查看容器中是否包括某一Bean等方法；

- HierarchicalBeanFactory:父子级联IoC容器的接口，子容器可以通过接口方法访问父容器；

- ConfigurableBeanFactory:是一个重要的接口，增强了IoC容器的可定制性，它定义了设置类装载器，属性编辑器，容器初始化后置处理器等方法；

- AutowireCapableBeanFactory:用来自动装配 Bean 用的

- DefaultListableBeanFactory:BeanFactory的实现类，实现了ConfigurableBeanFactory 和 AutowireCapableBeanFactory，是功能最全的BeanFactory实现类，Spring BeanFactory 里面的实例就是该类的实例。


#### ApplicationContext 

ApplicationContext 继承自 BeanFactory，但是它不应该被理解为 BeanFactory 的实现类，而是说其内部持有一个实例化的 BeanFactory（DefaultListableBeanFactory）。以后所有的 BeanFactory 相关的操作其实是委托给这个实例来处理的。

![ApplicationContext体系结构](/images/applicationcontext-sample.png)

- ApplicationContext 继承了 ListableBeanFactory, HierarchicalBeanFactory （但是没有继承 AutowireCapableBeanFactory接口，不使用继承，不代表不可以使用组合，ApplicationContext 接口中定义一个方法 getAutowireCapableBeanFactory() ）

- ApplicationContext还继承了诸如Environment、Resource、Message、Event等相关的接口，也就是说除了bean的管理配置相关的能力，ApplicationContext还拥有了Environment（环境）、MessageSource（国际化）、ResourceLoader（资源）、ApplicationEventPublisher（应用事件）等服务相关的接口


![ApplicationContext体系结构](/images/applicationcontext.png)

- ClassPathXmlApplicationContext 默认从类路径加载配置文件

- FileSystemXmlApplicationContext 默认从文件系统中装载配置文件

- AnnotationConfigApplicationContext 是基于注解来使用的，它不需要配置文件，采用 java 配置类和各种注解来配置

ApplicationContext 的完整体系结构

![ApplicationContext体系结构](/images/applicationcontext-all.png)

- ApplicationEventPublisher：让容器拥有发布应用上下文事件的功能，包括容器启动事件、关闭事件等。实现了 ApplicationListener 事件监听接口的 Bean 可以接收到容器事件 ， 并对事件进行响应处理 。 在 ApplicationContext 抽象实现类AbstractApplicationContext 中，我们可以发现存在一个 ApplicationEventMulticaster，它负责保存所有监听器，以便在容器产生上下文事件时通知这些事件监听者。

- MessageSource：为应用提供 i18n 国际化消息访问的功能；

- ResourcePatternResolver ： 所 有 ApplicationContext 实现类都实现了类似于PathMatchingResourcePatternResolver 的功能，可以通过带前缀的 Ant 风格的资源文件路径装载 Spring 的配置文件。

- LifeCycle：该接口是 Spring 2.0 加入的，该接口提供了 start()和 stop()两个方法，主要用于控制异步处理过程。在具体使用时，该接口同时被 ApplicationContext 实现及具体 Bean 实现， ApplicationContext 会将 start/stop 的信息传递给容器中所有实现了该接口的 Bean，以达到管理和控制 JMX、任务调度等目的。

- ConfigurableApplicationContext 扩展于 ApplicationContext，它新增加了两个主要的方法： refresh()和 close()，让 ApplicationContext 具有启动、刷新和关闭应用上下文的能力。在应用上下文关闭的情况下调用 refresh()即可启动应用上下文，在已经启动的状态下，调用 refresh()则清除缓存并重新装载配置信息，而调用close()则可关闭应用上下文。这些接口方法为容器的控制管理带来了便利，但作为开发者，我们并不需要过多关心这些方法。

```java
// 除了继承，它自身也提供了一些扩展的能力：
public interface ApplicationContext extends EnvironmentCapable, ListableBeanFactory, HierarchicalBeanFactory,
        MessageSource, ApplicationEventPublisher, ResourcePatternResolver {

    //标识当前context实例的id，最终会通过native方法来生成：System.identityHashCode
    String getId();

    //返回该context所属的应用名称，默认为空字符串，在web应用中返回的是servlet的contextpath 
    String getApplicationName();

    //返回当前context的名称
    String getDisplayName();

    //返回context第一次被加载的时间
    long getStartupDate();

    //返回该context的parent
    ApplicationContext getParent();

    //返回具有自动装配能力的beanFactory，默认返回的就是初始化时实例化的beanFactory
    AutowireCapableBeanFactory getAutowireCapableBeanFactory() throws IllegalStateException;
}
```

ApplicationContext的初始化和BeanFactory有一个重大的区别：

- BeanFactory在初始化容器时，并未实例化Bean,直到第一次访问某个Bean时才实例化目标Bean；

- 而ApplicationContext则在初始化应用上下文时就实例化所有单实例的Bean。因此ApplicationContext的初始化时间会比BeanFactory稍长一些


其他参考文章：https://www.jianshu.com/p/ea6de78a17d6 

#### WebApplicationContext

WebApplicationContext扩展了ApplicationContex。                                
                                        
![WebApplicationContext体系结构](/images/webapplicationcontext.png)


WebApplicationContext是专门为Web应用准备的，它允许从相对于Web根目录的路径中装载配置文件完成初始化工作。从WebApplicationContext中可以获得ServletContextde引用，整个Web应用上下文对象将作为属性放置到ServletContext中，以便Web应用环境可以访问Sping应用上下文。sping专门为此提供一个工具类WebApplicationContextUtils，通过该类的getWebApplicationContext(ServletContext sc)方法，即可以从ServletContext中获取WebApplicationContext实例。

WebApplicationContext定义了一个常量ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE,在上下文启动时，WebApplicationContext实例即以此为键放置在ServletContext的属性列表中，因此我们可以直接通过以下话语从Web容器中获取WebApplicationContext：

`WebApplicationContext wac=(WebApplicationContext)servletContext.getAttribute(ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE);`         

这正是我们前面提到的WebApplicationContextUtils工具类getWebApplicationContext(ServletContext sc)方法的内部实现方式。这样sping的web应用上下文和web容器的上下文就可以实现互访，二者实现了融合：

![sping和Web应用的上下文融合](/images/applicationcontext-web.webp)

ConfigurableWebApplicationContext扩展了WebApplicationContext，它允许通过配置的方式实例化WebaApplicationContext，它定义了两个重要的方法：

- setServletContext(ServletContext servletContext):为sping设置web应用上下文，以便两者整合；

- setConfigLocations(String[] configLocations):设置sping配置文件地址，一般情况下，配置文件地址是相对于web根目录的地址，如/WEB-INF/baobaotao-dao.xml,/WEB-INF/baobaotao-service.xml等。但用户也可以使用带资源类型前缀的地址，如classpath:com/baobaotao/beans.xml等。


**WebApplicationContext初始化**

WebApplicationContext的初始化方式和BeanFactory，ApplicationContext有所区别，因为WebApplicationContext需要Servlet或定义Web容器监听器（ServletContextListener）,借助这两者中的任何一个，我们就可以完成启动sping web应用上下文的工作。

Sping分别提供了用于启动WebApplicationContext的Servlet和Web容器监听器：

- org.spingframework.web.context.ContextLoaderServlet;
- org.spingframework.web.context.ContextLoaderListener。

两者的内部都实现了启动WebApplicationContext实例的逻辑，我们只要根据Web容器的具体情况选择两者之一，并在web.xml中完成配置就可以了。


**父子容器**

通过HierarchicalBeanFactory接口，sping的IoC容器可以建立父子层级关联的容器体系，子容器可以访问父容器中的Bean，但父容器不能访问子容器的Bean。在容器内，Bean的id必须是唯一的，但子容器可以拥有一个和父容器id相同的Bean。父子容器层级体系增强了sping容器架构的扩展性和灵活性，因为第三方可以通过编程的方式，为一个已经存在的容器添加一个或多个特殊用途的子容器，以提供一些额外的功能。



### Spring项目

Spring 不仅可以构建web项目，也可以构建非web项目，针对不同类型的项目，启动方式也有一定的不同。


#### 非WEB类型项目

非Web类型项目的启动，需要使用ApplicationContext的实现类，ClassPathXmlApplicationContext、FileSystemXmlApplicationContext 或者 AnnotationConfigApplicationContext 中的一个类启动即可，

将所写的代码打成一个jar，指定main函数，然后执行java -jar  xxx.jar

```java
//创建一个UserDao
@Repository
public class UserDao {
    //这里可以 @Autowired 来注入SqlSession
    // 然后findById方法可以真正从数据库获取数据
    public User findById(){//模拟从数据库查数据等
        User user =new User();
        user.setId("2019");
        user.setName("pengfei.wang");
        user.setAge(25);
        return user;
    }
}

//创建UserService接口
public interface UserService {
    User findById();
}

//实现UserService
@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private UserDao userDao;
    public User findById() {
        return userDao.findById();
    }
}

// 启动类
@ComponentScan
public class Application {
    /**
     * 注意四点
     * ①Application使用了@ComponentScan
     * ②Application这个类的位置是不是和spring boot的启动类位置很相似
     * ③这里ComponentScan默认basePackages是com.wpf
     * ④如果你的启动类放在其他包下面记得@ComponentScan里你要写你要扫描的包路径
     * 不然@ComponentScan默认是到自己类路径的。
     * 可以见com.wpf.app.Main
     */
    public static void main(String[] args) {
        AnnotationConfigApplicationContext applicationContext = null;
        try {
            applicationContext = new AnnotationConfigApplicationContext(Application.class);//初始化IOC容器
            
            // ClassPathXmlApplicationContext 方式
            //ApplicationContext context = new ClassPathXmlApplicationContext("classpath:applicationfile.xml");
            
            UserService userService = applicationContext.getBean(UserService.class);//通过IOC容器获得你要执行的业务代码的类
            User user = userService.findById();//通过IOC容器获取到的类执行你的业务代码
            System.out.println(user);
        } finally {
            if (applicationContext != null){
                applicationContext.close();
                System.out.println("普通java程序执行完成,IOC容器关闭。。。");
            }
        }
    }
}

```

ClassPathXmlApplicationContext 部分代码

```
public ClassPathXmlApplicationContext(String configLocation) throws BeansException {
    this(new String[] {configLocation}, true, null);
}

public ClassPathXmlApplicationContext(
        String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
        throws BeansException {

    super(parent);
    setConfigLocations(configLocations);
    if (refresh) {
        refresh();
    }
}
```


注意：Application这个类是放在包的根目录下，所以@ComponentScan是扫描根包下所有使用注解得Bean，如果你的主函数入口放在其他包下面，那么请在@ComponentScan加入包扫描路径。

**所以Spring容器（IOC容器）的启动，需要从ClassPathXmlApplicationContext() 类的构造函数看起。最终调用refresh()方法**



参考文章：https://blog.csdn.net/qq_16557637/article/details/100513286


#### WEB 类型项目

web类型的项目，通过Servlet容器来启动， ContextLoadListener

![WebApplicationContext体系结构](/images/spring-web-tomcat.jpg)

1、tomcat启动的时候，会加载web.xml文件，

2、解析web.xml文件，读取<listener>和<context-param>两个结点的内容

3、创建一个ServletContext（servlet上下文）, 这个web项目的所有部分都将共享这个上下文。

4、容器将<context-param>转换为键值对, 并交给servletContext。

5、容器创建<listener>中的类实例,创建监听器；

tomcat在启动web容器的时候会启动一个叫ServletContextListener的监听器，每当在web容器中有ServletContextListener这个接口被实例化的时候，web容器会通知ServletContextListener被实例的对象去执行其contextInitialized()的方法进行相应的业务处理；
而spring框架在设计的过程中ContextLoadListener这个类实现了ServletContextListener这个接口，因此每当有ContextLoadListener这个类被实例化的时候，web容器会通知Spring执行contextInitialized（）这个方法，从而进行spring容器的启动与创建的过程中

6、ContextLoaderListener中的contextInitialized()进行了spring容器的启动配置，调用initWebApplicationContext初始化spring容器；

```
@Override
public void contextInitialized(ServletContextEvent event) {
  initWebApplicationContext(event.getServletContext());
}
```

```
public WebApplicationContext initWebApplicationContext(ServletContext servletContext) {
  //Spring 启动的句柄，spring容器开始启动的根目录
  if(servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
    throw new IllegalStateException("Cannot initialize context because there is already a root application context present - check whether you have multiple ContextLoader* definitions in your web.xml!");
  } else {
    Log logger = LogFactory.getLog(ContextLoader.class);
    servletContext.log("Initializing Spring root WebApplicationContext");
    if(logger.isInfoEnabled()) {
      logger.info("Root WebApplicationContext: initialization started");
    }
  
    long startTime = System.currentTimeMillis();
  
    try {
      //处理spring容器是否已经创建（只创建没有创建spring的各个bean）
      if(this.context == null) {
        this.context = this.createWebApplicationContext(servletContext);
      }
  
      if(this.context instanceof ConfigurableWebApplicationContext) {
        ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext)this.context;
        if(!cwac.isActive()) {
          if(cwac.getParent() == null) {
            ApplicationContext parent = this.loadParentContext(servletContext);
            cwac.setParent(parent);
          }
  
          //Spring容器创建完成后，加载spring容器的各个组件
          this.configureAndRefreshWebApplicationContext(cwac, servletContext);
        }
      }
  
      servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);
      ClassLoader ccl = Thread.currentThread().getContextClassLoader();
      if(ccl == ContextLoader.class.getClassLoader()) {
        currentContext = this.context;
      } else if(ccl != null) {
        currentContextPerThread.put(ccl, this.context);
      }
  
      if(logger.isDebugEnabled()) {
        logger.debug("Published root WebApplicationContext as ServletContext attribute with name [" + WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE + "]");
      }
  
      if(logger.isInfoEnabled()) {
        long elapsedTime = System.currentTimeMillis() - startTime;
        logger.info("Root WebApplicationContext: initialization completed in " + elapsedTime + " ms");
      }
  
      return this.context;
    } catch (RuntimeException var8) {
      logger.error("Context initialization failed", var8);
      servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, var8);
      throw var8;
    } catch (Error var9) {
      logger.error("Context initialization failed", var9);
      servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, var9);
      throw var9;
    }
  }
}
```

```
protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac, ServletContext sc) {
        if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
            // The application context id is still set to its original default value
            // -> assign a more useful id based on available information
            String idParam = sc.getInitParameter(CONTEXT_ID_PARAM);
            if (idParam != null) {
                wac.setId(idParam);
            }
            else {
                // Generate default id...
                wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
                        ObjectUtils.getDisplayString(sc.getContextPath()));
            }
        }
  
        wac.setServletContext(sc);
        String configLocationParam = sc.getInitParameter(CONFIG_LOCATION_PARAM);
        if (configLocationParam != null) {
            wac.setConfigLocation(configLocationParam);
        }
  
        // The wac environment's #initPropertySources will be called in any case when the context
        // is refreshed; do it eagerly here to ensure servlet property sources are in place for
        // use in any post-processing or initialization that occurs below prior to #refresh
        ConfigurableEnvironment env = wac.getEnvironment();
        if (env instanceof ConfigurableWebEnvironment) {
            ((ConfigurableWebEnvironment) env).initPropertySources(sc, null);
        }
  
        customizeContext(sc, wac);
        wac.refresh();
    }
```

**所以Spring容器（IOC容器）的启动，需要ContextLoaderListener-> ContextLoader 的 initWebApplicationContext方法开始，最终调用refresh()方法**


#### 总结

Spring 容器的启动，最终都调用的是的 refresh()方法，即AbstractApplicationContext来的refresh()方法来完成。

详细的IOC启动流程，[点击这里](framework/spring/ioc.md)



### 常见概念

#### Servlet 规范 

参考：[Servlet 规范](java/servlet/)

#### Servlet 容器

Servlet 容器是 web server 或 application server 的一部分，提供基于请求/响应发送模型的网络服务，解码基于 MIME 的请求，并且格式化基于 MIME 的响应。Servlet 容器也包含了管理 Servlet 生命周期。Servlet 容器可以嵌入到宿主的 web server 中，或者通过 Web Server 的本地扩展 API 单独作为附加组件安。Servelt 容器也可能内嵌或安装到包含 web 功能的 application server 中。所有 Servlet 容器必须支持基于 HTTP 协议的请求/响应模型，比如像基于 HTTPS（HTTP over SSL）协议的请求/应答模型可以选择性的支持。容器必须实现的 HTTP 协议版本包含 HTTP/1.0 和 HTTP/1.1。

#### ServletContext 

ServletContext: 这个是来自于servlet规范里的概念，它是servlet用来与容器间进行交互的接口的组合，也就是说，这个接口定义了一系列的方法，servlet通过这些方法可以很方便地与自己所在的容器进行一些交互，比如通过getMajorVersion与getMinorVersion来获取容器的版本信息等. 从它的定义中也可以看出，在一个应用中(一个JVM)只有一个ServletContext, 换句话说，容器中所有的servlet都共享同一个ServletContext.

#### ServletConfig 

ServletConfig: 它与ServletContext的区别在于，servletConfig是针对servlet而言的，每个servlet都有它独有的serveltConfig信息，相互之间不共享.

#### Spring容器

https://blog.csdn.net/haohaizijhz/article/details/90674774

https://www.cnblogs.com/jieerma666/p/10805966.html


https://www.cnblogs.com/pan-4957/p/10599020.html

Spring容器最基本的接口就是BeanFactory。BeanFactory负责配置、创建、管理Bean，他有一个子接口：ApplicationContext，因此也称之为Spring上下文。Spring容器负责管理Bean与Bean之间的依赖关系。

在Spring 中有两个比较核心接口BeanFactory和ApplicationContext，其中ApplicationContext是BeanFactory的子接口。他们都可代表Spring容器，Spring容器是生成Bean实例的工厂，并且管理容器中的Bean。

Bean是Spring管理的基本单位，在基于Spring的Java EE应用中，所有的组件都被当成Bean处理，包括数据源、Hibernate的SessionFactory、事务管理器等。在Spring中，Bean的是一个非常广义的概念，任何的Java对象、Java组件都被当成Bean处理。
 
而且应用中的所有组件，都处于Spring的管理下，都被Spring以Bean的方式管理，Spring负责创建Bean实例，并管理他们的生命周期。Bean在Spring容器中运行，无须感受Spring容器的存在，一样可以接受Spring的依赖注入，包括Bean属性的注入，协作者的注入、依赖关系的注入等。

Spring容器负责创建Bean实例，所以需要知道每个Bean的实现类，Java程序面向接口编程，无须关心Bean实例的实现类；但是Spring容器必须能够精确知道每个Bean实例的实现类，因此Spring配置文件必须精确配置Bean实例的实现类。


#### ApplicationContext

ApplicationContext: 这个类是Spring实现容器功能的核心接口，它也是Spring实现IoC功能中最重要的接口，从它的名字中可以看出，它维护了整个程序运行期间所需要的上下文信息， 注意这里的应用程序并不一定是web程序，也可能是其它类型的应用. 在Spring中允许存在多个applicationContext，这些context相互之间还形成了父与子，继承与被继承的关系，这也是通常我们所说的，在spring中存在两个context,一个是root context，一个是servlet applicationContext的意思. 这点后面会进一步阐述.

#### WebApplicationContext

WebApplicationContext: 其实这个接口不过是applicationContext接口的一个子接口罢了，只不过说它的应用形式是web罢了. 它在ApplicationContext的基础上，添加了对ServletContext的引用，即getServletContext方法.









