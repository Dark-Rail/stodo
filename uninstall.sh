#!/bin/sh
DIR_PATH_TEMP="$1"
UID_TEMP=$(id -u )
USERNAME=$(logname)

if [ "${UID_TEMP}" -eq 0 ]; then
	rm -v /usr/local/man/man1/stodo.1 /usr/local/man/man1/stodo.1.gz
else
	printf "\033[0;31m%s\033[0m\n" "For deleting manual page of stodo, you should run with sudo/doas."
	exit 1
fi

if [ -n "${DIR_PATH_TEMP}" -a -d "${DIR_PATH_TEMP}" ]; then
	GREP_CMD=$(printf "%s" "${DIR_PATH_TEMP}" | awk \ 
		-v VAR="/home/${USERNAME}"'{gsub("~/", VAR);print }' )
	rm -rf "${DIR_PATH_TEMP}/"
	exit 0
fi

if [ -d "/home/${USERNAME}/stodo/" ]; then
	ls
	# rm -rf "/home/${USERNAME}/stodo/"
else
	printf "The stodo directory in the home does not exists."
	exit 1
fi
