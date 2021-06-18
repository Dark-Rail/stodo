#!/bin/sh
USERNAME=$(logname)
UID_TEMP=$(id -u ${USERNAME})
if [ "${UID_TEMP}" -eq 0 ]; then
	rm -v /usr/local/man/man1/stodo.1 /usr/local/man/stodo.1.gz
fi

if [ -d "/home/${USERNAME}/stodo/" ]; then
	rm -rf "/home/${USERNAME}/stodo/"
fi
