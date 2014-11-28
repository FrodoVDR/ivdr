#!/bin/sh
# set -e
# set -x
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
dpkg -l | grep lighttpd
if [ $? -eq 0 ] ; then
        printf "\nlighttpd found.\n\n"
        if [ -f /etc/lighttpd/lighttpd.conf ] ; then
                OTHERSERVERPORT=`grep server.port /etc/lighttpd/lighttpd.conf | sed "s/\"//g" | sed "s/ //g" | awk -F "=" '{ print $2 }'`
		grep server.port /etc/lighttpd/lighttpd.conf >/dev/null  2>&1
		if [ $? -ne 0 ] ; then
			OTHERSERVERPORT=80
		fi
		printf "\nlighttpd was configured on port "
		color '31;1' "$OTHERSERVERPORT"
		printf "\n\n"
        fi
fi
dpkg -l | grep apache
if [ $? -eq 0 ] ; then
        printf "\napache2 found.\n\n"
	if [ -f /etc/apache2/ports.conf ] ; then
       		OLDSERVERPORT=`grep ^Listen /etc/apache2/ports.conf | awk '{ print $2 }'`
		printf "\napache2 was configured on port "
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


printf "apache2 port [$SERVERPORT]: "
read port
printf "\napache2 port : %s\n" $port
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

apt-get install libapache2-mod-perl2 perl-modules libhtml-parser-perl libwww-perl libxml-simple-perl

if [ -f /etc/apache2/ports.conf ] ; then
	OLDSERVERPORT=`grep ^Listen /etc/apache2/ports.conf | awk '{ print $2 }'`
fi


if [ -f /etc/apache2/ports.conf ] ; then
	grep "$port$" /etc/apache2/ports.conf >/dev/null  2>&1
	if [ $? -ne 0 ] ; then
		sed -i /etc/apache2/ports.conf -e "s/$OLDSERVERPORT/$port/g"
	fi
fi
if [ -f /etc/apache2/sites-enabled/000-default ] ; then
	grep ":$OLDSERVERPORT/>" /etc/apache2/sites-enabled/000-default >/dev/null  2>&1
	if [ $? -ne 0 ] ; then
		sed -i /etc/apache2/sites-enabled/000-default -e "s/$OLDSERVERPORT/$port/g"
	fi
fi

if [ -d /etc/apache2/conf.d ] ; then
	if [ ! -L /etc/apache2/conf.d/ivdr ] ; then
		ln -s /usr/share/ivdr/apache/ivdr /etc/apache2/conf.d/ivdr
	fi
fi

/etc/init.d/apache2 restart

exit 0
