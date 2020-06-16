
<h2>Servlet</h2>

--------------------------------------------------------

参考了 https://blog.csdn.net/u010297957/article/details/51498018

Servlet 是JavaEE的重要组成部分，需要对Servlet有一个全面的了解及认识。


### Servlet的历史

#### 一、Servlet的由来

**背景**

上世纪90年代，随着Internet和浏览器的飞速发展，基于浏览器的B/S模式随之火爆发展起来。最初，用户使用浏览器向WEB服务器发送的请求都是请求静态的资源，比如html、css等。但是可以想象：根据用户请求的不同动态的处理并返回资源是理所当然必须的要求。

**CGI**

必须要满足上述需求，所以CGI（Common Gateway Interface）出现了。CGI程序使用C、Shell Script或Perl编写，CGI是为特定操作系统编写的（如UNIX或Windows），不可移植，CGI程序对每个请求产生新的进程去处理。

步骤如下：

- WEB服务器接收一个用户请求；

- WEB服务器将请求转交给CGI程序处理；

- CGI程序将处理结果返回给WEB服务器；

- WEB服务器把结果送回用户；

![cgi](/images/cgi.jpeg)


**Java**

与此同时，Java语言也在迅速发展。必然的，Java要支持上述需求。Java有两种方案来实现动态需求，它们都属于JavaEE技术的一部分。

- 1、applet是纯客户端(浏览器)方案，applet就是浏览器中的Java插件，浏览器通过它解释执行Web服务器发来的Java代码，从而实现动态交互。此方法浏览器必须安装插件，同时又受浏览器限制导致Java代码不能太多太复杂；
    
- 2、既然浏览器不方便执行Java代码，那自然还是服务端来执行了，所以Servlet出现了，Servlet就是server端的applet的意思。


#### 二、Servlet的工作原理

其实Servlet的工作原理基本类似上面的CGI，不过Servlet比CGI更好。

- WEB服务器接收一个用户请求；

- WEB服务器将请求转交给WEB服务器关联的Servlet容器；

- Servlet容器找到对应的Servlet并执行这个Servlet；

- Servlet容器将处理结果返回给WEB服务器；

- WEB服务器把结果送回用户；


#### 三、Servlet的发展

Servlet　－>　Servlet1.1（JSP）　－>　Servlet1.2（MVC思想）

1. Servlet诞生后，SUN公司很快发现了Servlet编程非常繁琐，这是因为：

  - Servlet代码中有大量冗余代码，每个Servlet都有一模一样的或基本近似的代码，比如out输出你可能就得写成百遍；
  
  - 开发Servlet必须精通网页前端和美工，你得非常不直观的在Servlet中写前端代码，这使得实现各种页面效果和风格非常困难。

2. 所以，SUN借鉴了Microsoft的ASP，正式提出JSP（Servlet1.1），已期望能代替Servlet。但是很快，SUN发现JSP也有问题：

  - 前端开发人员需要看JSP中大量的令他困惑的后端代码；

  - 同样，Servlet开发人员也得在复杂的前端代码中找到其能写Servlet代码的地方；

3. 所以，Servlet1.2出现了，这个版本的Servlet倡导了MVC思想：

  - JSP（V）：将后端代码封装在标签中，使用大量的标签，JSP只用来写前端代码而不要有后台代码；

  - Servlet（C）：Servlet完成Controller的功能再加上部分代码逻辑；

  - Model（M）：Servlet将数据发送给Model，Model包括部分代码逻辑，最主要的Model也代表着被组织好的用于返回的数据。最终，Model数据会被显示在JSP上（V）。

基本上到这里Servlet的大方向已经固定了，随之，成熟的发展至今 - 2016年5月26日…

 

### Servlet规范

#### Servlet概述

Servlet有两种意思：

- 广义上是：基于Java技术的Web组件，被容器托管，用于生成动态内容。再详细点说，Servlet是JavaEE组件中的 -> Web组件的 -> 一种。（其它两种是JavaServer Faces和JavaServer Page）

- 狭义上说：是JavaEE API中的一个interface，javax.servlet.Servlet；

Servlet 容器/引擎：

- Servlet容器也可以叫引擎，Container/Engine，用于执行Servlet。

- 容器是以内嵌或者附加组件的形式存在于Web服务器或者应用服务器中的。

- 容器本身（不依赖Web服务器）就提供了基于请求/响应发送模型的网络服务，解码基于MIME的请求，格式化基于MIME的响应。

- 所有容器必须实现HTTP协议的请求/响应模型。其它协议不强求，如HTTPS。

![调用关系](/images/diaoyong.png)


#### Servlet Interface的生命周期

Servlet生命周期由容器管理，程序员不能通过代码控制。

加载和实例化　－>　初始化　－>　请求处理　－>　终止服务

- ａ.加载的时机取决于web.xml的定义，如果有`<load-on-startup>x</load-on-startup>`则在容器启动时启动，否则则在第一次针对该Servlet的请求发生时启动；

- ｂ.实例化后会立刻执行init方法进行初始化；

- ｃ.请求处理：初始化后，Servlet可以接受请求，基本方式是执行Servlet接口中的service方法，对Http请求而言则是执行API中提供的doGet、doPost等特殊方法；

- ｄ.容器将在合适的时候销毁某个Servlet对象（取决于容器的开发者），在容器关闭时Servlet对象一定会被销毁。当Servlet对象呗销毁时，destroy方法会被调用。

![servlet](/images/servlet.jpg)


Servlet API 

Java Servlet API是Servlet容器和Servlet之间的接口，它定义了Servlet的各种方法，还定义了Servlet容器传送给Servlet的对象类，其中最重要的是请求对象ServletRequest和响应对象ServletResponseo这两个对象都是由Servlet容器在客户端调用Servlet时产生的，
Servlet容器把客户请求信息封装在ServletRequest对象中，然后把这两个对象都传送给要调用的Servlet，Servlet处理完后把响应结果写入ServletResponse，然后由Servlet容器把响应结果发送到客户端。

![servlet](/images/api.png)

#### 官方的规范文档

Servlet规范官方地址：JSR 340: Java Servlet 3.1 Specification（中文版网上有人翻译了，可以自己搜索找找）
可以自己下载阅读，最终版final是2013年5月28发布的Servlet3.1。


#### Servlet容器

servlet容器是Web服务器或应用程序服务器的一部分，它提供发送requests和responses的网络服务，解码基于MIME的请求，并格式化基于MIME的响应。 servlet容器还包含并管理servlet的生命周期。
     
Servlet容器可以内置在Web服务器中，也可以通过web服务器的扩展API作为附加组件安装。Servlet容器同样可以作为具体Web服务功能的应用服务器的内置模块或者附加组件。

所有的Servlet容器必须支持HTTP协议，并可以支持其他基于请求－相应模式的协议，例如HTTPS。Servlet容器至少需要支持HTTP 1.0版本，并强烈建议同时支持HTTP 1.1版本。


### Servlet总结

Servlet是JavaEE规范的一种，主要是为了扩展Java作为Web服务的功能，统一接口。


为什么 Servlet 规范会有两个包 javax.servlet 和 javax.servlet.http ?

早先设计该规范的人认为 Servlet 是一种服务模型，不一定是依赖某种网络协议之上，因此就抽象出了一个 javax.servlet ，同时在提供一个基于 HTTP 协议上的接口扩展。但是从实际运行这么多年来看，似乎没有发现有在其他协议上实现的 Servlet 技术。 








