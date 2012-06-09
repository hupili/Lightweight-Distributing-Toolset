#!/bin/bash

if [[ $# == 1 ]] ; then
	working=$1
else 
	echo "usage $0 {working}"
	exit 255
fi

cd $working

if [[ -e run.finish ]] ; then
	#exit 0
	echo "check:0"
else 
	#exit 1
	echo "check:1"
fi

exit 0 
