#!/bin/bash

disk_info=(
	dev_path mount_path
)

num=${#disk_info[*]}

index=0

while [ $index -lt $num ]; do
    dev_path=${disk_info[$index]}
    index=$(($index+1))

    mount_path=${disk_info[$index]}
    index=$(($index+1))

    if [ ! -e "$dev_path" ]; then
        echo "device $dev_path not exits, ignore"
        continue
    fi
    mkdir -p "$mount_path"
    mount "$dev_path" "$mount_path"
    echo "mount $dev_path result: $?"
done

