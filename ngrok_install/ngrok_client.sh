#! /bin/bash

# Absolute path for ngrok
NGROK=
# Absolute path for ngrok.cfg
CONFIG=

function check_file()
{
    if [ ! -f $1 ]; then
        echo "file $1 not exits, please check"
        exit 1
    fi
}

if [ ! $NGROK -o ! $CONFIG ]; then
    echo "please specify startup parameters"
    echo "NGROK="
    echo "CONFIG="
    exit 1
fi

check_file $NGROK
check_file $CONFIG

if [ ! $1 ]; then
    echo "Usage: `basename $0` start|stop|restart"
    exit 1
fi

if [ $1 = "start" ]; then
    nohup $NGROK -config=$CONFIG -log=stdout  start-all > ngrok.log 2>&1 &
elif [ $1 = "stop" ]; then
    killall $NGROK
elif [ $1 = "restart" ]; then
    $0 stop
    sleep 1
    $0 start
else
    echo "unknow parameter: $1"
fi

