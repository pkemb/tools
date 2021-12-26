#!/bin/bash

# 生成一个新的ssh key，并配置config文件、部署到目标主机

function usage()
{
    echo "usage: "
    echo "    $0 [-h] [-p] user@host[:port]"
    echo ""
    echo "    generate ssh key and deploy to host."
    echo "    If no port is specified, use port 22."
    echo "    key file path: ~/.ssh/id_rsa_<user>_<host>"
    echo ""
    echo "-p  don't deploy public key, just print it"
    echo "-h  print this message"
    echo ""
    exit 0
}

JUST_PRINT="0"

for arg in "$@"
do
    case $arg in
    -p)
        JUST_PRINT="1"
        ;;

    -h|--help)
        usage
        ;;

    *@*)
        read USER HOST PORT < <(echo $arg | awk -F "[@:]" '{print $1,$2,$3}')
        ;;

    *)
        ;;
    esac
done

if [ ! "$USER" ] || [ ! "$HOST" ]; then
    usage
fi

if [ ! "$PORT" ]; then
    PORT=22
fi

if ! type -t ssh-keygen > /dev/null; then
    echo "please install ssh first"
    exit 1
fi

IDENTITY_FILE=~/.ssh/id_rsa_${USER}_${HOST}

if [ -f "${IDENTITY_FILE}" ]; then
    echo "${IDENTITY_FILE} exits"
    exit 1
fi

mkdir -p ~/.ssh

# https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html
ssh-keygen \
    -t RSA \
    -C "${USER}_${HOST}" \
    -f ${IDENTITY_FILE} \
    -N ""

{
    echo ""
    echo "Host ${HOST}"
    echo "HostName ${HOST}"
    echo "User ${USER}"
    echo "Port ${PORT}"
    echo "IdentityFile ${IDENTITY_FILE}"
    echo ""
} >> ~/.ssh/config

if [ $JUST_PRINT = "1" ]; then
    echo "public key is:"
    echo ""
    cat ${IDENTITY_FILE}.pub
else
    ssh-copy-id -i ${IDENTITY_FILE} -p ${PORT} ${USER}@${HOST}
fi
