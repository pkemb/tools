#!/bin/bash

OIFS="$IFS"
IFS=$'\n'


LIBRARY=$1

if [ ! $LIBRARY ]; then
	echo "Usage: $(basename $0) library-path"
	exit 1
fi

if ! type -t ebook-meta > /dev/null; then
    echo "脚本不可用！请先安装 Calibre"
    exit
fi

ADDED_DIR=$(mktemp AddedBooks.XXXXXXXXXX)
rm -rf $ADDED_DIR
mkdir $ADDED_DIR

echo "添加到书库($LIBRARY)的书籍将被移动到目录："
echo -e "$PWD/$ADDED_DIR\n"

for f in $PWD/*.azw3 $PWD/*.mobi $PWD/*.MOBI $PWD/*.azw $PWD/*.epub $PWD/*.EPUB $PWD/*.ebk3
do
	if [[ -f "$f" ]]
	then
		author=$(ebook-meta "$f" 2>/dev/null | grep Author | cut -d ":" -f2 | sed 's/ //g')
		f_basename=$(basename $f)
		if [ "$author" = "Unknown" ]; then
			echo "author unknown: $f_basename"
		else
			ADD=1
			echo "add book      : $f_basename"
			calibredb add $f --duplicates --library-path $LIBRARY >/dev/null 2>&1
			mv $f $ADDED_DIR
		fi
	fi
done

if [ ! $ADD ]; then
	echo "没有添加任何书籍，删除 $ADDED_DIR"
	rm -r $ADDED_DIR
fi


IFS=$OIFS