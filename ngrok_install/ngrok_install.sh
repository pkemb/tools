#!/bin/bash

#compilation paremeters
# linux platform:   linux
# windows platfrom: windows
# MAC platfrom:     darwin
GOOS_server=
GOOS_client=

# 32bits system: 386
# 64bits system: amd64
# arm platform:  arm
GOARCH_server=
GOARCH_client=

# $1 command
function check_command()
{
	if [ ! $1 ];then
		return;
	fi
	if ! type -t $1 > /dev/null; then
		echo "please install $1 first!!!"
		exit 1
	fi
}

# $1 script file name
function print_usage()
{
	if [ ! $1 ];then
		return;
	fi
	base=`basename $1`
	echo "Usage: $base domain"
	#echo "-h     print help message"
}

# $1 file name
function check_certificate_file()
{
	if [ ! $1 ];then
		return;
	fi
	if [ ! -f $1 ]; then
		echo "generate $1 fail, please check"
		exit 1
	fi
}

check_command git
check_command gcc
check_command go
check_command openssl
check_command make

if [ ! $1 ];then
	print_usage $0
	exit 1
fi

if [ ! $GOOS_server -o ! $GOOS_client -o ! $GOARCH_server -o ! $GOARCH_client ]; then
	echo "plese specify compilation paremeters in the file header!!!"
	echo "GOOS_server="
	echo "GOOS_client="
	echo "GOARCH_server="
	echo "GOARCH_client="
	exit 1
fi

domain=$1
workdir=ngrok_$domain

if [ -d $workdir ]; then
	echo "repo exits, escape clone repo"
else
	rm -rf $workdir
	git clone https://github.com/inconshreveable/ngrok.git $workdir
	if [ $? != 0 ]; then
		echo "clone ngrok repo fail, please check network"
		exit 1
	fi
fi

cd $workdir

rm -f rootCA.key rootCA.pem device.key device.csr device.crt
echo "start generate certificate"
openssl genrsa -out rootCA.key 2048 > /dev/null 2>&1
check_certificate_file rootCA.key 

openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$domain" -days 5000 -out rootCA.pem > /dev/null 2>&1
check_certificate_file rootCA.pem

openssl genrsa -out device.key 2048 > /dev/null 2>&1
check_certificate_file device.key

openssl req -new -key device.key -subj "/CN=$domain" -out device.csr > /dev/null 2>&1
check_certificate_file device.csr

openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000 > /dev/null2>&1
check_certificate_file device.crt

echo "start replace certificate"
cp -f rootCA.pem assets/client/tls/ngrokroot.crt
cp -f device.crt assets/client/tls/snakeoilca.crt
cp -f device.crt assets/server/tls/snakeoil.crt
cp -f device.key assets/server/tls/snakeoil.key

echo "start compilation"
GOOS=$GOOS_server GOARCH=$GOARCH_server make release-server
if [ $? != 0 ]; then
	echo "server compilation error, please compile manually"
	echo "command: GOOS=$GOOS_server GOARCH=$GOARCH_server make release-server"
fi

GOOS=$GOOS_client GOARCH=$GOARCH_client make release-client
if [ $? != 0 ]; then
	echo "client compilation error, please compile manually"
	echo "command: GOOS=$GOOS_client GOARCH=$GOARCH_client make release-server"
fi

