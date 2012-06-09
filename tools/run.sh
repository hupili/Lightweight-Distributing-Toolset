#!/bin/bash

if [[ $# == 3 ]] ; then
	home=$1 
	working=$2
	exe=$3
else 
	echo "usage $0 {home} {working} {exec}"
	exit 255
fi

export d_home=$home
export d_working=$working

cd $working
chmod 744 $exe
nohup $exe > run.stdout 2> run.stderr &

exit $? 
