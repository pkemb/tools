#!/bin/bash

OIFS="$IFS"
IFS=$'\n'


LIBRARY=$1

if [ ! "$LIBRARY" ]; then
	echo "Usage: $(basename $0) library-path"
	exit 1
fi

if ! type -t ebook-meta > /dev/null; then
    echo "脚本不可用！请先安装 Calibre"
    exit
fi

# $1 target dir
function delete_empty_dir()
{
	dir=$1
	if [ ! -d $dir ]; then
		return
	fi
	if [[ -z "$(find "$dir" -mindepth 1 -type f)" ]] >/dev/null
	then
		echo "$dir"
		rm -rf ${dir} 2>&- && echo "Empty, Deleted!" || echo "Delete error"
	fi
}

# $1 backdir
# 将当前所在目录的书籍添加到书库
function add_books()
{
	BACKDIR=$1
	if [ ! -d $BACKDIR ]; then
		return
	fi
	
	for f in $PWD/*.azw3 $PWD/*.mobi $PWD/*.MOBI $PWD/*.azw $PWD/*.epub $PWD/*.EPUB $PWD/*.ebk3
	do
		if [[ -f "$f" ]]
		then
			author=$(ebook-meta "$f" 2>/dev/null | grep Author | cut -d ":" -f2 | sed 's/ //g')
			f_basename=$(basename $f)
			if [ "$author" = "Unknown" ]; then
				echo "author unknown: $f_basename"
			else
				echo "add book      : $f_basename"
				calibredb add $f --duplicates --library-path $LIBRARY >/dev/null 2>&1
				mv $f $BACKDIR
			fi
		fi
	done
}

# $1 backdir
function recursive_add_books()
{
	local BACKDIR=$1
	if [[ ! -d $BACKDIR ]]; then
		echo "$BACKDIR not exits, return"
		return
	fi
	
	BACKBASE=$(basename $BACKDIR)

	find . -mindepth 1 -maxdepth 1 -type d | grep -v $BACKBASE | while read -r dir
	do
		dirbase=$(basename $dir)
        mkdir -p $BACKDIR/$dirbase
		cd $dirbase
		recursive_add_books $BACKDIR/$dirbase
		cd ..
		delete_empty_dir $PWD/$dirbase
    done
	
	add_books $BACKDIR
	delete_empty_dir $BACKDIR
	#echo "PWD = $PWD"
	#echo "BACK = $BACKDIR"
}

BACKDIR=$(mktemp Backup.XXXXXXXXXX)
rm -rf $BACKDIR
mkdir $BACKDIR

echo "add books to: $LIBRARY"
echo "backup to   : $BACKDIR"
echo -e "\n"

recursive_add_books $PWD/$BACKDIR

IFS=$OIFS