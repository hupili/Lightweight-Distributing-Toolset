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

> Finally, $? may be set to non-0 value if the external program /cdrom/install fails. The upper eight bits reflect specific error conditions encountered by the program (the program's exit() value). The lower eight bits reflect mode of failure, like signal death and core dump information. See wait(2) for details.


20120605 - Implementation of ./multiprocess.pl
----

I try to find some time to note my implementation of multiprocess.pl. 
Some parts are so ugly that I'm afraid I'll forget one day. 
Here I list those key points:
   * The way of handling log levels. This is the first time I try to 
   introduce a formal format of log into my Perl scripts. Most time, 
   my Perl scripts are snippets that I do not worry about tracing 
   valuable information. However for this one, it acts as a hub and 
   will be frequently used in the future. There may be standard log 
   libraries off-the-shelf. That's not explored during the development. 
   * 'Proc::ProcessTable'. I don't want to use any non-defaultly installed 
   modules. I tried several ways to kill child process, grand child, etc. 
   It turns out this is the only way I find to kill cleanly. Other options are
      * Kill with a negative signal. It is supposed to work by may articles
      online. My observation is that all the child process will share the same 
      group of the first terminal('sh', 'bash', etc). Nothing happens
      using negative signal with the child process ID. 
      * Kill the child process with positive signal. I don't know why 
      the signal does not pass on to its child in this way. What I see 
      is that the child process(directly forked from my script) is 
      killed. However, the internal commands keeps executing until finish..
      It turns out, kill() by default does not kill process recursively. 
   In the end, I found the ProcessTable module. Using this module, we can 
   enumerate the process list and then kill them in reserse order. 
   * 'sub recursive_kill'. It can be upgraded to iterative version. 
   Well, this is not the key point. For a tree of processes, if 
   we kill child first, the parent may return as if it executes 
   successfully. This is true if the customer served commands are 
   poorly written. If we kill the parent before recurse to the next 
   level, the parent dies, leaving children attached to the grand 
   parent... The recursion may stop at some point, leaving some 
   zombie process there. There are two things to find way out:
      * Iterate over the process table to find all process to be 
      killed in a batch and kill them in a batch. 
      * Record the killing signal is sent in my 'multiprocess.pl' and 
      ignore the child's output even if it shows a successful return.
   * 'waitpid(-1, POSIX::WNOHANG)'. This is said to be another 
   portable issue. This command waits for all possible zombie child, 
   not a specific one. It operates in non-blocking mode. Not system 
   has corresponding implementation to support this operation. 
   * '$?' of 'waitpid'. As is noted in the last section. 
   * 'echo "$$: finished executing: $cmd\n"'. I'm not sure to make this 
   line background or not. There are hazards. Without background 
   execution, the hazard can be alleviated, but not cleaned. 
   * Inter process communication with hazard. I'm lazy and I don't want 
   to survey for sophisticated modules to handle interprocess communication. 
   The most ugly design I come out in this script is the fifo based 
   communication. There are two considerations:
      * If 'waitpid' operates in blocking mode, it looses much 
      paralellism. 
      * If 'waitpid' operates in non-blocking mode, we fall in a 
      busy waiting status. It's a waste of resource. 
   Bearing this in mind, it first came to me that we use 'select'
   to handle the situation in network programming. After a little 
   survey, I can not see direct methods to convert PID to handles 
   that can be 'select'ed. Then I thought of pipe, which is a special 
   file of unix system. When the child process exits, it can write 
   something into the pipe, just to trigger parent. In the parent, 
   'waitpid(-1, POSIX::WNOHANG)' will be able to capture this child. 
   In this way, we avoid busy-waiting. 
   * 'open $fh_fifo, "cat $tmpfifo |"'. There are other ways to 
   open a pipe in Perl. More straightforward one is to open without
   'cat' as a bridge. This does not work. If you directly open a 
   pipe in Perl, it blocks until there are something in the pipe. 
   I don't know why the 'open' function is designed to get stuck there...
   Looks strange. With the help of a cat command, our parent process 
   will not get stuck then. 
   * This introduces another issue. When we 
   finish everything, there is a danling 'cat' command running. 
   This is because we already read out everything in the pipe and 
   reopens it every time. In the end of parent script, the 'cat' 
   gets stuck and the parent process does not exit...
   So I intentionally echo something into the pipe 
   when multi-processing is finished. This is to let 'cat' go, 
   and the process can terminate...
   * I should explain why the pipe is re-opened every time. 
   After one round of 'while... read...', the pipe becomes 
   invalid at the parent side. If we do not re-open it, we 
   can not read anything child processes write to it later...


20120609
----

The return value of system has the same structure as
the return value of waitpid. 
Lower 8bit is the status of waitpid. It is usually 
0 due to successful locally waiting of child process. 
The higher bit is the return status of command series 
inside system call. 

For 'ssh' command, it returns 255 on failure of connection, 
authentication, etc. It returns the status of command 
inside 'ssh' on other conditions. 
