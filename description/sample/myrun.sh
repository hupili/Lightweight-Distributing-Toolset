#!/bin/bash

cp -r $d_home/template/* .
./run.sh

echo `date` > run.finish

exit 0 
