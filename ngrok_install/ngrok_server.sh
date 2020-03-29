#! /bin/bash

# Absolute path for ngrokd
NGROKD=
# Absolute path for device.key
TLS_KEY=
# Absolute path for device.crt
TLS_CRT=
DOMAIN=

function check_file()
{
    if [ ! -f $1 ]; then
        echo "file $1 not exits, please check"
        exit 1
    fi
}

if [ ! $NGROKD -o ! $TLS_KEY -o ! $TLS_CRT -o ! $DOMAIN ]; then
    echo "please specify startup parameters"
    echo "NGROKD="
    echo "TLS_KEY="
    echo "TLS_CRT="
    echo "DOMAIN="
    exit 1
fi

check_file $NGROKD
check_file $TLS_KEY
check_file $TLS_CRT

if [ ! $1 ]; then
    echo "Usage: `basename $0` start|stop|restart"
    exit 1
fi

if [ $1 = "start" ]; then
    nohup  $NGROKD \
       -tlsKey=$TLS_KEY \
       -tlsCrt=$TLS_CRT \
       -domain="$DOMAIN" \
       -httpAddr=:88 \
       -httpsAddr=":443" \
       -tunnelAddr=":4443" \
       > ngrokd.log 2>&1  &
elif [ $1 = "stop" ]; then
    killall $NGROKD
elif [ $1 = "restart" ]; then
    $0 stop
    sleep 1
    $0 start
else
    echo "unknow parameter: $1"
fi

