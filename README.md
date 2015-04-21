# Quick Server
## 基于OpenResty的服务器框架

---

## 最新版本 0.5.1

## 介绍

Quick Server 为开发者提供一个稳定可靠，可伸缩的服务端架构，让开发者可以使用 Lua 脚本语言快速完成服务端的功能开发。

主要特征:

-   稳定可靠、经过验证的高性能游戏服务端架构。
-   使用 Lua 脚本语言开发服务端功能。
-   支持短连接和长连接，满足从异步网络到实时网络的各种需求。
-   支持插件机制，使用第三方插件加快功能开发。

更多介绍可以参考[Quick Server 介绍](http://quickserver-docs.readthedocs.org/zh_CN/latest/intro/index.html)。

## 安装

安装 Quick Server 请参考[Quick Server 安装](http://quickserver-docs.readthedocs.org/zh_CN/latest/install/index.html)。

## 相关资源

-   文档: [http://quickserver-docs.readthedocs.org/](http://quickserver-docs.readthedocs.org/zh_CN/latest/index.html)
-   QQ群: **424776815**

## 版本日志

### 0.5.1
-   新的功能
    -    后台执行任务功能 Job Worker 现在已经开发完成了。这个功能主要用于游戏开发中的定时任务的实现。
    -    Job Worker 是 Quick Server 的一个子模块，并且与另一子模块 Beanstalkd 配合使用。
    -    提供了 Job Service 插件，直接用于添加后台任务。支持任务延时，任务优先级，任务最大处理时间等参数。

-   主要 Bug 修复和改进
    -    Quick Server 返回的错误信息会去除冗余的路径显示。
    -    启动或者停止 Quick Server时，各个子模块启动出错之后，脚本现在可以正常退出了。
    -    对于后台任务数量的监视，Monitor 现在会返回正确的值。
    -    tools.sh 工具现在能更好的显示执行的结果。
    -    启动，停止以及状态显示脚本，支持 Job Worker 模块。
    -    启动，停止以及状态显示脚本，可以在任何目录下正确得到 Quick Server 的配置信息，完成相应的功能。
    -    启动, 停止以及状态显示脚本，可以正确显示当前 Quick Server 的版本号，以及是处于 Release 或者 Debug 模式。

-   支持 Mac 操作系统
    -    install.sh 脚本现在可以在 Mac 系统下正常使用。所有参数与在 Linux 系统下没有变化。
    -    对于在 Mac 下需要的前置安装条件，安装脚本会自动使用 brew 进行安装。
    -    所有组件都将被离线安装，与 Linux 下表现一致，不会因为网络延时浪费时间。（除了 luasec 库，见下）
    -    绝大部分 Quick Server 组件都能在 Mac 系统下使用。由于 shell 兼容性的原因， Monitor 在 Mac 系统下将不会被启动。
    -    启动，停止以及状态显示脚本支持 Mac 操作系统。

-  增加了 luasec 库
    -    该库的作用是对 httpclient 库以及 luasocket 库增加 ssl 的支持。在 Mac 下，作者停止维护，该库仅支持10.4版本的 Mac 系统。因此该库当 Quick Server 在 Mac 系统下安装时，该库并不会安装。
