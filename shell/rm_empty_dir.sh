#!/bin/bash
# des: delete empty directories recursive

OIFS="$IFS"
IFS=$'\n'


deleteempty() {
    find ${1:-.} -mindepth 1 -maxdepth 1 -type d | while read -r dir
    do
        if [[ -z "$(find "$dir" -mindepth 1 -type f)" ]] >/dev/null
        then
            echo "$dir"
            rm -rf ${dir} 2>&- && echo "Empty, Deleted!" || echo "Delete error"
        fi
        if [ -d ${dir} ]
        then
            deleteempty "$dir"
        fi
    done
}

deleteempty

IFS=$OIFS