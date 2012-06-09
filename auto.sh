#!/bin/bash

#execute update script automatically, by cron
#

echo "[begin]`date`" >> auto.log
#./task-update.pl > /dev/null 2> /dev/null
ret=$?
echo "[end]`date` :$ret" >> auto.log

exit 0 
