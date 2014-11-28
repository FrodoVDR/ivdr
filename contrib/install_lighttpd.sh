#!/bin/sh
# set -e

color() {
      printf '\033[%sm%s\033[m\n' "$@"
      # usage color "31;5" "string"
      # 0 default
      # 5 blink, 1 strong, 4 underlined
      # fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
      # bg: 40 black, 41 red, 44 blue, 45 purple
}

SERVERPORT=8081
echo
dpkg -l | grep apache
if [ $? -eq 0 ] ; then
        printf "\napache2 found.\n"
	if [ -f /etc/apache2/ports.conf ] ; then
        	OTHERSERVERPORT=`grep ^Listen /etc/apache2/ports.conf | awk '{ print $2 }'`
		printf "apache was configured on port "
		color '31;1' "$OTHERSERVERPORT"
		printf "\n\n"
	fi
fi

dpkg -l | grep lighttpd
if [ $? -eq 0 ] ; then
        printf "\nlighttpd found.\n"
	if [ -f /etc/lighttpd/lighttpd.conf ] ; then
		OLDSERVERPORT=`grep server.port /etc/lighttpd/lighttpd.conf | sed "s/\"//g" | sed "s/ //g" | awk -F "=" '{ print $2 }'`
		grep server.port /etc/lighttpd/lighttpd.conf >/dev/null  2>&1
		if [ $? -ne 0 ] ; then
			OLDSERVERPORT=80
		fi
		printf "lighttpd was configured on port "
		color '31;1' "$OLDSERVERPORT"
		printf "\n\n"
	fi
fi
if [ $OTHERSERVERPORT ] ; then
        SERVERPORT=`expr $OTHERSERVERPORT + 1`
fi
if [ $OLDSERVERPORT ] ; then
        SERVERPORT=$OLDSERVERPORT
fi

printf "lighttpd port [$SERVERPORT]: "
read port
printf "\nlighttpd port : %s\n" $port
if [ ! $port ] ; then
	port=$SERVERPORT
fi
printf "\n\nNew port: $port\n\n"

# Port Check
for i in `netstat -tan | grep '^tcp6 ' | awk '{ print $4 }' | awk -F ":::" '{ print $2 }'`; do
        if [ $i -eq $OLDSERVERPORT ] ; then continue; fi;
        if [ $i -eq $port ] ; then printf "\nERR: Port $port is in use\n\n"; exit 1; fi;
done
for i in `netstat -tan | grep '^tcp ' | awk '{ print $4 }' | awk -F ":" '{ print $2 }'`; do
        if [ $i -eq $OLDSERVERPORT ] ; then continue; fi;
        if [ $i -eq $port ] ; then printf "\nERR: Port $port is in use\n\n"; exit 1; fi;
done

apt-get install lighttpd

if [ -f /etc/lighttpd/lighttpd.conf.ivdr ]
then
	cp -a /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.ivdr
fi
if [ ! -d /etc/lighttpd/conf-enabled ] 
then
	mkdir -p /etc/lighttpd/conf-enabled
fi
grep server.port /etc/lighttpd/lighttpd.conf  >/dev/null  2>&1
if [ $? -ne 0 ] ; then
	cp /usr/share/ivdr/lighttpd/lighttpd.conf /etc/lighttpd/
	OLDSERVERPORT=8081
fi
sed -i /etc/lighttpd/lighttpd.conf -e "s/$OLDSERVERPORT/$port/g"

if [ -f /etc/lighttpd/conf-available/10-cgi.conf ]
then
        if [ ! -e /etc/lighttpd/conf-enabled/10-cgi.conf ] ; then
                ln -s /etc/lighttpd/conf-available/10-cgi.conf /etc/lighttpd/conf-enabled/10-cgi.conf
        fi
fi
if [ -f /etc/lighttpd/conf-available/15-fastcgi-php.conf ] ; then
        if [ ! -e /etc/lighttpd/conf-enabled/15-fastcgi-php.conf ] ; then
                ln -s /etc/lighttpd/conf-available/15-fastcgi-php.conf /etc/lighttpd/conf-enabled/15-fastcgi-php.conf
        fi
fi
if [ -f /etc/lighttpd/conf-available/10-fastcgi.conf ] ; then
        if [ ! -e /etc/lighttpd/conf-enabled/10-fastcgi.conf ] ; then
                ln -s /etc/lighttpd/conf-available/10-fastcgi.conf /etc/lighttpd/conf-enabled/10-fastcgi.conf
        fi
fi
cat /etc/mime.types | grep 'ts' | grep 'video/MP2T' >/dev/null  2>&1
if [ $? -ne 0 ] ; then
        echo "video/MP2T                                      ts" >> /etc/mime.types
fi
cat /etc/mime.types | grep 'm3u8' | grep 'application/x-mpegURL' >/dev/null  2>&1
if [ $? -ne 0 ] ; then
        echo "application/x-mpegURL                           m3u8" >> /etc/mime.types
fi

/etc/init.d/lighttpd restart

exit 0
