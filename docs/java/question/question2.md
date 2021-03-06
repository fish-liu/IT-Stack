
通用型业务解决方案设计

文章参考：[字节跳动必问面试题——通用型业务解决方案设计](https://honeypps.com/architect/bytedance-interview-general-business-solutions/)

-------------------------------------

**前言**

受邀参加过字节跳动面试的小伙伴一般都会收到一封面试邀请的邮件，邮件上面会注明考查的内容，只有两项，其中第一项就是“我们主要考察通用型的业务问题和过往的项目经历”，项目经历很好理解，那么“通用性业务问题”又是什么呢？今天的文章，皮皮就通过一道通用性业务问题（真实面试题）来带大家感受一下。

**正文**

业务背景：某浪微博平台有很多用户时常的会发布微博，当某个用户发布一条微博的时候，TA的所有关注着都可以接收到这条信息。那么怎么样设计一个合理的解决方案来让用户快速将他所发布的微博信息推送给所有的关注者呢？

小伙伴们可以先思考一下，回味一下这道题，然后再继续往下看。

> 当然，类似的业务场景有很多，举微博的例子因为它比较典型而且熟知度也高。注意：以下的分析仅代表个人立场，皮皮没有在某浪微博工作过，至于他们到底怎么做的只能说不了解。

方案一

每个用户所发送的微博都存储起来（时间上有序）。当用户要刷新微博的时候就可以直接拉取TA所关注的人在这个时间内的微博，然后按照时间排序之后再推送过来。（当然，这里的什么延迟拉取之类的细节优化就不做详述了。）

机智的小伙伴可能也发现了这种方案的问题，对于某浪微博这种级别的平台，他所支撑的用户都是数以亿计的，这样的方案对于读的压力将会是巨大的。

那么怎么办呢？当我们试图开始要优化一个系统的时候，有个相对无脑而又实用的方案就是——上缓存。

方案二

具体操作说起来也比较简单，对每个用户都维护一块缓存。当用户发布微博的时候，相应的后台程序可以先查询一下他的关注着，然后将这条微博插入到所有关注着的缓存中。（当然这个缓存会按时间线排序，也会有一定的容量大小限制等，这些细节也不多做赘述。）这样当用户上线逛微博的时候，那么TA就可以直接从缓存中读取，读取的性能有了质的飞升。

如此就OK了吗？显然不是，这种方案的问题在于么有考虑到大V的存在，大V具有很庞大的流量扇出。比如微博女王谢娜的粉丝将近1.25亿，那么她发一条微博（假设为1KB）所要占用的缓存大小为1KB * 1.25 * 10^8 = 125GB。对于这个量我们思考一下几个点：

- 对于1.25亿人中有多少人会在这个合适的时间在线，有多少人会刷到这条微博，很多像皮皮这种的半僵尸用户也不会太少，这块里面的很多容量都是浪费。

- 1.25亿次的缓存写入，虽然不需要瞬时写入，但好歹也要在几秒内完成的吧。这个流量的剧增带来的影响也不容忽视。

- 微博上虽然上亿粉丝的大V不多，但是上千万、上百万的大V也是一个不小的群体。某个大V发1条微博就占用了这么大的缓存，这个机器成本也太庞大了，得不偿失。

那么又应该怎么处理呢？这里也可以先停顿思考一下。

> 这种案例比较典型，比如某直播平台，当PDD上线直播时（直播热度一般在几百万甚至上千万级别）所用的后台支撑策略与某些小主播（直播热度几千之内的）的后台支撑的策略肯定是不一样的。

从微观角度而言，计算机应用是0和1的世界，而从宏观角度来看，计算机应用的艺术确是在0-1之间。通用型业务设计的难点在于要考虑很多种方面的因数，然后权衡利弊，再对症下药。业务架构本没有什么银弹，有的是对系统的不断认知和优化改进。

对于本文这个问题的解决方法是将方案一和二合并，以粉丝数来做区分。也就是说，对于大V发布的微博我们用方案一处理，而对于普通用户而言我们就用方案二来处理。当某个用户逛微博的时候，后台程序可以拉取部分缓存中的信息，与此同时可以如方案一中的方式读取大V的微博信息，最后将此二者做一个时间排序合并后再推送给用户。



