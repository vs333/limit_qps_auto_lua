自动限流
====
1、项目背景
-------
    公司一直使用的都是淘宝的Tengine作为http的代理和负载均衡，经过好几次秒杀抢购的场景后深知限流对后端的重要性，对于Tengine已有的限流在早期也试着使用过几个月，总体来说对业务的灵活度不高，只能通过location，server等几个维度去做限流，并且每次要修改配置文件生成限流配置，所以一直在考虑有没有一种能够感知业务压力，自动限制qps的方式，找来找去网上没有现成的解决办法，唯有自己动手丰衣足食。
2、思路概括
-------
    首先通过lua和Tengine结合计算出每秒、每分钟的qps，每分钟同一个url的耗时总数，并且用lua形成一个json格式显示给分析程序，分析程序拿到这个json以后，能够读出每个url请求，这一分钟内的每个请求的平均耗时，根据这个平均耗时读取预制的限流配置（1分钟允许的qps数），写回lua配置这个url的限流。
    Tengine中的lua接受到了这个url的限流配置，根据每个请求每秒的qps与配置限流数/60秒进行对比，如果小于等于就正常转发，如果大于就直接返回一个json数据告诉业务请求，此url目前正处于限流状态。
