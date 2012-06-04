Notes
====

20120528
----

   * Use multi-thread or multi-process to speedup 
   batch execution. My original desin is for the 
   use in intanet servers, where the network 
   condition is good. When I use LWT on PlanetLab, 
   the stauts update scripts get stuck quite 
   often. That is mainly due to underlying network
   congestion or failure. For example, scp may get
   stuck when fetching back files. Then the whole 
   cycle get stuck. 
   * The autonoma in task-update.pl should be 
   redesigned... It gets rather large now. 

20120531
----

Here's a piece of interesting work: 
[https://github.com/erikfrey/bashreduce](https://github.com/erikfrey/bashreduce)

The bashreduce looks more lightweighted than the current tool... 
LWT has more functionality but can learn the way of handling 
muti-machine communications from that project. esp. ssh + netcat. 

2012060x
----

The multiporcess eventually work. But the implementation is really ugly..
I don't quite like it...
