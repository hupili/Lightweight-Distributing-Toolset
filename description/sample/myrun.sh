#!/bin/bash

#This is a sample dtask startup script.
#
#Environment variables:
# $d_home :contains the home folder of 
#          the current machine running the dtask
# $d_working :contains the working folder 
#             of the current dtask. 
#
#Principles:
# * You may want to use put-all.pl to 
#   upload command files to all machines,
#   putting them somewhere under $d_home. 
# * For each dtask, put specific input data
#   in the task description folder, just 
#   like the 'input' folder located along 
#   with this script. 
# * Before this script is executed, the 
#   current working directory will be swtiched
#   to $d_working. 
# * $d_working is kept in the running 
#   environment in case the user's dtask
#   want's to know the absolute path. 
#   Remember only operate files under
#   $d_working. Any operation outside is vunerable
#   to interfere with other tasks. 
# * After your task is finished, touch one 
#   file named 'run.finish' under the current 
#   directory($d_working). You can put in other 
#   information like date, if you like. 


#cp -r $d_home/template/* .
delay=10
sleep $delay
mkdir -p output
echo "I slept for $delay seconds" > output/info
echo `hostname` >> output/info
echo `pwd` >> output/info
echo `ls -1 .` >> output/info
echo "d_working:$d_working" >> output/info
echo "d_home:$d_home" >> output/info
echo `date` >> output/date

echo `date` > run.finish

exit 0 
