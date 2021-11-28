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

编译成功之后，会自动生成`ngrokd.sh`和`ngrok_server.service`文件。

推荐使用`systemd`来管理客户端和服务端的启动，省事、省心、有保障。[ngrok_client.service](ngrok_client.service)是客户端的示例配置，有一些本地化的东西需要配置。

创建一个指向此文件的软链接，并放到`/lib/systemd/system`目录下，即可使用以下命令来管理服务的启动与停止：
```shell
# 启动服务
systemctl start ngrok_client
# 停止服务
systemctl stop ngrok_client
# 打开开机自启动
systemctl enable ngrok_client
# 关闭开机自启动
systemctl disable ngrok_client
```
