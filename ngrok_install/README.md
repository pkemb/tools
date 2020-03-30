# ngrok 一键安装脚本

[ngrok_install.sh](ngrok_install.sh)

一键安装脚本，在使用前，请务必安装好`git`、`gcc`、`make`、`openssl`以及`go`语言环境。并且在文件头部修改编译参数：

```shell
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
```
