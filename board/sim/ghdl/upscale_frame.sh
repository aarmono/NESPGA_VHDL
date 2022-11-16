#!/usr/bin/env bash

bigfile=${1/frame/big}
if [ ! -e "$bigfile" ]
then
	exec convert "$1" -interpolate Nearest -filter point -resize 500% "$bigfile"
fi
