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
