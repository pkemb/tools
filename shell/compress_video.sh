#!/bin/bash
# 2017-11-10 更新日志
# 使用 -z 判断第一个选项是否为空
# 使用 find 命令查找工作目录及其子目录下的所有目标格式视频
# 2018-01-13 更新日志
# 将压缩的视频列表写入 list.txt 文件，用于查看进度
# 2022-02-27 优化
# 1. 使用mktemp创建临时的list文件，避免覆盖已有的list.txt
# 2. 检测ffmpeg的返回值，如果失败，则回退，并记录
# 3. 原始文件重命名为${filename}.original.${EXTEND}，压缩完成之后不删除
# 4. 如果 ${filename}.original.${EXTEND} 存在，则跳过压缩
# 5. 优化变量命名
# 6. 检查命令 ffmpeg 是否存在

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

EXTEND=$1

if [ ! "$(type -t ffmpeg)" ]; then
    echo "命令 ffmpge 没有找到，请先安装 ffmpeg"
    exit 1
fi

if [ -z ${EXTEND} ]
then
    echo "请将需要压缩的视频的扩展名作为第一个参数。"
    exit 1
fi

LIST=$(mktemp list.XXXXXXXX.txt)
ERROR_LIST=""

/usr/bin/find | /bin/grep -v ".original.${EXTEND}$" | /bin/grep ".${EXTEND}$" | sed s/".${EXTEND}"//g > ${LIST}

for filename in $(cat ${LIST})
do
    if [ -f "${filename}.original.${EXTEND}" ]; then
        echo "跳过压缩，文件存在：${filename}.original.${EXTEND}"
        continue
    fi

    mv "${filename}.${EXTEND}" "${filename}.original.${EXTEND}"
    ffmpeg -i "${filename}.original.${EXTEND}" -strict -2 -r 10 -b:a 64k "$filename".mp4
    if [ $? != 0 ]; then
        echo "${filename}.${EXTEND} 压缩失败"
        rm -rf "$filename".mp4
        mv "${filename}.original.${EXTEND}" "${filename}.${EXTEND}"
        ERROR_LIST="${filename}.${EXTEND} ${ERROR_LIST}"
        continue
    fi
done
rm ${LIST}

if [ x"$ERROR_LIST" != "x" ]; then
    echo "以下文件压缩失败："
    echo "$ERROR_LIST" | tr " " "\n"
fi

IFS=$SAVEIFS
