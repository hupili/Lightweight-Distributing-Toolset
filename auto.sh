#!/bin/bash

#execute update script automatically, by cron
#

pid=$$
dir="log/$pid"
mkdir -p $dir

begin=`date +%s`
echo "[begin]`date`" >> auto.log
#./task-update.pl > $dir/stdout 2> $dir/stderr 
ret=$?
echo "[end]`date` :$ret" >> auto.log
end=`date +%s`


exit 0 
