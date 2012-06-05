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

20120605
----

I want to capture the return value of child process in multiprocess.pl. 
It turns out the $? after waitpid() call has two parts. 
The lower 8 bits are indicator of returning condition
(termination, kill, etc). The upper 8 bits are the return 
value of the child process. 

[http://perldoc.perl.org/perlvar.html]
(http://perldoc.perl.org/perlvar.html)
``
Finally, $? may be set to non-0 value if the external program /cdrom/install fails. The upper eight bits reflect specific error conditions encountered by the program (the program's exit() value). The lower eight bits reflect mode of failure, like signal death and core dump information. See wait(2) for details.
``
