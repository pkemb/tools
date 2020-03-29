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

[ngrok_server.sh](ngrok_server.sh)

服务端启动脚本，参数`start`启动服务，`stop`停止服务。在使用前，请修改文件头部的启动参数。`DOMAIN`是脚本[ngrok_install.sh](ngrok_install.sh)的第一个参数，`NGROKD`、`TLS_KEY`、`TLS_CRT`是脚本[ngrok_install.sh](ngrok_install.sh)生成的三个文件。

```shell
# Absolute path for ngrokd
NGROKD=
# Absolute path for device.key
TLS_KEY=
# Absolute path for device.crt
TLS_CRT=
DOMAIN=
```

[ngrok_client.sh](ngrok_client.sh)

客户端端启动脚本，参数`start`启动客户端，`stop`停止客户端。在使用前，请修改文件头部的启动参数。`DOMAIN`是脚本[ngrok_install.sh](ngrok_install.sh)生成的文件。`CONFIG`是客户端的配置文件，这是一个示例配置[ngrok.cfg](ngrok.cfg)。

```shell
# Absolute path for ngrok
NGROK=
# Absolute path for ngrok.cfg
CONFIG=
```
