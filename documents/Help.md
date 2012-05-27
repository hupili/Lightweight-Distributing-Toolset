LWT Help
====

Setup
----

   * Copy all the scripts to a local directory 
   of your master machine. 
   One example: ~/distribute. 
   * Configure your hosts list file 'host.list'. 
   One host per line with tab separated records
   in the following format: 
   <name> \t <category> \t <home_dir>
   . For example, 
   "me	fedora	/home/hupili/distribute". 
   We'll explain the fields in later chapters. 
   * Configure your ssh '~/.ssh/config'
   The host names (<name> field in 'host.list')
   should have their corresponding information 
   in '~/.ssh/config'. 
   Please refer to online resources or later 
   chapters. 
   * Build trust relationships from your peer 
   machine to your master machine. 
   * Now you're ready for your pilot test of LWT. 
   

Hello World
----

In this chapter, we present a way how
simple commands are executed and how 
files are transferred between master machine
and peer machine. 
   * './deploy.pl'. This will arrage the running 
   environment for your distributed tasks
   on all peer machines
   (mkdir, copy auxiliary tools). 
   * './execute-all.pl <cmd>'. In this way, you can 
   batch execute <cmd> on all peer machines and 
   the result will be output to the console
   of master machine. 
   * './put-all.pl <local_dir> <remote_dir>'. 
   You can put files from master machine to 
   peer machine using this command. 
   * './get-all.pl <remote_dir> <local_dir>'. 
   This script help you fetch files from 
   all machines(probably produced by your 
   previous commands). Don't worry the file
   names. LWT will put files from different
   machines in different subfolders in the format:
   '<local_dir>/d.<hostname>'. 


Advanced Distributed Task
----

For comples works, you may want to utilize 
LWT's distribution framework. 
   * Check 'description/sample' for one 
   sample distributed task(dtask). 'desc' 
   provides a description of dtask, 
   in which 'exec' is mandatory. 'exec'
   is the command to be executed after 
   master assigns a dtask to peer. 
   'exec' (either a series of commands or 
   a script) MUST TOUCH 'run.finish'
   at current directory after the dtask
   is finished. 'run.finish' is an indicator 
   to LWT that this task is completed and 
   result will be fetched automatically 
   for you. 
   * './task-add.pl'. Use this script 
   to add a dtask in 'description'. 
   Those added tasks are ready to be 
   distributed. 
   * './task-update.pl'. This script provides
   the core function of LWT. It monitors
   the status of machines and dtasks 
   and switch between the following 
   status: new, running, finished, suspended, 
   killed. The script is self-locked, 
   so you needn't worry any failure 
   caused by multiple invocations. 
   * './task-show.pl'. This script shows 
   the information of tasks, using 
   Perl's Dumper function. 
   * For those dtasks which take a very long 
   time to finish, you don't want to manually 
   invoke './task-update.pl' everytime and 
   help it switch between status. You can 
   configure a cron job for 'auto.sh'. This 
   script is a wrapper for './task-update.pl'. 
   You'll find the wrapper useful while debugging. 
   Commenting/Uncommenting the the './task-update.pl' line
   of the script is more convenient than 
   turning off/on cron jobs. 

