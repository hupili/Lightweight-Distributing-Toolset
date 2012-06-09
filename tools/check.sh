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
	echo 0
else 
	#exit 1
	echo 1
fi

