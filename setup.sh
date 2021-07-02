#!/bin/sh
UID_TEMP=$(id -u)
if [ "$UID_TEMP" == 0 ];then
	if [ ! -e /usr/local/man/man1/ ];then
		mkdir -v /usr/local/man/man1/
	fi
	mv -v ./stodo.1 /usr/local/man/man1/
	mv -v ./stodo.1.gz /usr/local/man/man1/
else
	printf "Script need to run with sudo or doas because script moves man page to \033[4m/usr/local/man/man1/\033[0m directory\n"
fi
