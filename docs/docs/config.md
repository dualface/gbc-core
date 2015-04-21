# Quick Server 详细配置

Quick Server 的基本配置都可以由 `config.lua` 完成。除此之外，对于高级用户，还可以直接修改 `nginx.conf` ， `redis.conf` 等配置文件来定制运行环境。

> 在直接编辑 `nginx.conf` 或者 `redis.conf` 时，请自行保证修改后的配置符合 Quick Server 的运行要求，并且与 `config.lua` 中的设置保持兼容。

## config.lua 文件

`config.lua` 文件本身是一个 Lua 的 table。分为应用程序设置和 Quick Server 系统设置两部分。

### 应用程序设置

-   `appRootPath`: 配置用户 app 所在的位置（绝对路径）。例如：`appRootPath = "/home/apps/myapp"`
-   `numOfWorkers`: 指定启动多少个 Nginx Worker 进程。通常，这个数值应该和 CPU 内核数量相等，以获得最佳的性能表现。
-   `appHttpMessageFormat`: 指定 HTTP 请求使用的消息格式，默认为 'json'。目前只支持 'json' 和 'text' 两种。
-   `appSocketMessageFormat`: 指定 Socket 连接使用的消息格式，默认为 'json'。目前只支持 'json' 和 'text' 两种。
-   `appJobMessageFormat`: 指定后台任务存储数据时使用的格式，默认为 'json'。目前只支持 'json' 和 'text' 两种。
-   `appSessionExpiredTime`: 指定 Session 的过期时间，默认为 `600` 秒。


### Quick Server 系统设置

-   `quickserverRootPath`: 指定 Quick Server 的安装目录，默认为 `_QUICK_SERVER_ROOT_`，通常不应修改。
-   `port`: 指定 Quick Server 在哪一个端口接受请求，默认为 `8088`。
-   `welcomeEnabled`: 指定是否启用 Quick Server 自带的欢迎界面，默认为 `true`。在生产服务器上可以将这个选项设置为 `false`，屏蔽掉欢迎界面。
-   `adminEnabled`: 指定是否启用 Quick Server 内置的管理接口，默认为 `true`。欢迎界面中的服务器状态监控等功能需要依赖管理接口。
-   `websocketsTimeout`: WebSocket 协议超时时间，默认值为 `60 * 1000`（60秒）。
-   `websocketsMaxPayloadLen`: 客户端发往服务端的 WebSocket 消息的最大长度，默认值为 `16 * 1024`（16KB）。可以根据自己应用的情况调整这个设置。调整原则是满足需求的前提下，越小越好。
-   `maxSubscribeRetryCount`: 指定订阅广播频道最大尝试次数，默认为 `10` 次。
-   `redis.*`: 指定 Quick Server 内部使用的 Redis 数据库的连接方式和协议超时时间。
-   `beanstalkd.*`: 指定 Quick Server 内部使用的 Beanstalkd 任务队列的连接方式。
-   `beanstalkd.jobTube`: 指定 Quick Server 内部使用什么“桶”来存储后台任务。
-   `monitor.process`: 指定管理接口要监控的进程。
-   `monitor.interval`: 指定监控数据刷新的频率。

