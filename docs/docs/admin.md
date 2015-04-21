# Quick Server 管理接口使用

Quick Server 在安装完成了之后，默认配置了一些基于 HTTP 协议的接口，主要用于 Quick Server 服务器本身的管理、维护、以及配置。这些接口的实现代码都置于 `apps/admin` 下。

这些接口的 HTTP URL 都是 `/admin` 。


## 监控接口

监控接口是用于读取 Quick Server 监控数据的接口。Quick Server 的监控数据包括：进程 CPU 使用率，进程内存使用大小，进程接受的连接数。

action: `monitor.getdata`

参数说明：

-   `time_span`: 指定返回最近多少时间内的数据，格式为 `时间长度 时间单位`，例如 `60s`、`1h`。如果省略该参数，那么将会针对每一个进程的每一个监控项返回所有精度的数组。

    -   如果指定的时间跨度小于 60s，那么监控数据中就只会返回 `last_60s` 这一数组，采样精度由 `config.monitor.interval` 决定；
    -   如果指定的时间跨度大于60s，但是小于1小时也就是3600s，那么就只会返回 `last_hour` 这一数组，精度为1分钟；
    -   如果指定的时间间隔大于3600s，那么只会返回 `last_day` 这一数组，精度为1小时。

返回值说明（JSON 字符串）：

```json
{
    // 主机监控程序采样间隔，即 config.monitor.interval 的值，单位秒
    "interval": 10,
    // 主机 cpu 核心数量
    "cpu_cores": "2",
    // 主机物理内存，单位 kb
    "mem_total": "2049988",
    // 主机空闲物理内存， 单位 kb
    "mem_free": "119988",
    // 主机硬盘空间， 单位 kb
    "disk_total": "393838972",
    // 主机空闲磁盘空间， 单位 kb
    "disk_free": "340386420",

    // 进程名称, nginx master 进程
    "NGINX_MASTER": {
        // 监控项目名称， 该项为 cpu 使用率
        "cpu": {
            // 根据 time_span 参数返回以下三种精度的数据之一
            "last_60s": [ // 最近60s数据， 根据上述采样间隔采样
                "0.2",
                "0.2",
                "0.2",
                "0.2",
            ],
            "last_hour": [ // 最近1小时数据， 1分钟间隔采样
            ],
            "last_day": [ // 最近1天数据， 1小时间隔采样
            ]
        },

        // 监控项目，当前进程的内容使用，单位 KB
        "mem": {
        },

        // nginx 当前总的连接数
        "conn_num": {
        }
    },

    // Nginx Worker 进程的数据
    "NGINX_WORKER_#1": {
        "cpu": {
        },
        "mem": {
        }
    },

    // Redis 进程的数据
    "REDIS_SERVER": {
        "cpu": {
        },
        "mem": {
        },
        "conn_num": {
        }
    },

    // Beanstalkd 进程的数据
    "BEANSTALKD": {
        "cpu": {
        },
        "total_jobs": {
        }
    }
}
```

### 调用示例

采用 `curl` 工具调用该接口的示例如下:

```bash
$ curl "http://quick_server_host:port/admin" \
       -d "action=monitor.getdata&time_span=5m"
```
