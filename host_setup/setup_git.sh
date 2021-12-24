#!/bin/bash

git config --global user.name  "pkemb"
git config --global user.email "pkemb@outlook.com"
git config --global core.editor "vi"

echo 'export PS1="$(echo $PS1 | sed "s/\\\\\\\$[ \t]*$//g")\[\033[36m\]"\`__git_ps1\`"\[\033[0m\]\\$ "' >> ~/.bashrc
source ~/.bashrc
