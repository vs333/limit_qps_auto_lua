自动限流
====
1、项目背景
-------
    公司一直使用的都是淘宝的Tengine作为http的代理和负载均衡（理论上毛子原生的Nginx，章博士的OpenResty都是可以的），经过好几次秒杀抢购的场景后深知限流对后端的重要性，对于Tengine已有的限流在早期也试着使用过几个月，总体来说对业务的灵活度不高，只能通过location，server等几个维度去做限流，并且每次要修改配置文件生成限流配置，所以一直在考虑有没有一种能够感知业务压力，自动限制qps的方式，找来找去网上没有现成的解决办法，唯有自己动手丰衣足食。
    
2、思路概括
-------
    首先通过lua和Tengine结合计算出每秒、每分钟的qps，每分钟同一个url的耗时总数，并且用lua形成一个json格式显示给分析程序，分析程序拿到这个json以后，能够读出每个url请求，这一分钟内的每个请求的平均耗时，根据这个平均耗时读取预制的限流配置（1分钟允许的qps数），写回lua配置这个url的限流。
    Tengine中的lua接受到了这个url的限流配置，根据每个请求每秒的qps与配置限流数/60秒进行对比，如果小于等于就正常转发，如果大于就直接返回一个json数据告诉业务请求，此url目前正处于限流状态。

3、lua代码实现
-------
    lua生成的计算都是存储在nginx的lua_shared_dict中，这个大家可以认为是一个内存数据库，类似redis的kv结构。url和time组成key，time、qps都是value。lua_shared_dict的配置是在nginx.conf中，其中limitqps.xxxxxxxx.com.conf是lua数据收集的显示和接收限流配置的域名，其中调用了lua代码。yewu.xxxxxxxx.com.conf是业务域名，其中也调用了lua代码，主要作用是获取url请求的RT，qps数。作为限流和分析的依据。需要说明的是lua代码里用到了一个三方库cjson。

4、分析程序
-------
    是否进入限流状态，并且套用配置是什么要通过限流分析程序去实现，我这里同时写了java和python两种语言的限流分析程序，青菜萝卜各有所好。具体可以详见qps_auto_analysis_java、qps_auto_analysis_py这2个仓库。
