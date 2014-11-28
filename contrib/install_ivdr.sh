#!/bin/sh
# set -e

if [ ! -d /dev/shm/ram ]
then
	mkdir /dev/shm/ram
	chmod 777 /dev/shm/ram
	ln -s /dev/shm/ram /var/www/ram
fi

grep ram /etc/rc.local >/dev/null 2>&1
if [ $? -ne 0 ] 
then
	sed 's/exit 0//g' /etc/rc.local > /tmp/rc.local
	cp /tmp/rc.local /etc/rc.local
	rm /tmp/rc.local
	echo "mkdir /dev/shm/ram" >> /etc/rc.local
	echo "chmod 777 /dev/shm/ram" >> /etc/rc.local
	echo "exit 0" >> /etc/rc.local 
fi

if [ ! -d /var/cache/vdr/epgimages ]
then
	mkdir -p /var/cache/vdr/epgimages
fi

if [ ! -d /srv/streams ]
then
	mkdir -p /srv/streams
	chown www-data:www-data /srv/streams
	chmod 666 /srv/streams
else
	chown www-data:www-data /srv/streams
	chmod 666 /srv/streams
fi

exit 0
