---
description: juicefs 部署在docker-compose上
slug: juicefs
public: true
title: juicefs部署
createdAt: 1718615414596
updatedAt: 1718949325930
tags:
  - juicefs
heroImage: /cover.webp
---
## 前言
 juicefs可以基于s3存储来是实现  ，接下来通过docker-compose来实现juicefs的过程
 
 ## 运行minio
 通过docker-compose启动minio
 ```yaml
 version: "3.7"
services:
  minio:
    image: "quay.io/minio/minio:RELEASE.2022-08-02T23-59-16Z"
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - "./minio/data1:/data1"
      - "./minio/data2:/data2"
    command: server --console-address ":9001" http://minio/data{1...2}
    environment:
      - MINIO_ROOT_USER=admin
      - MINIO_ROOT_PASSWORD=12345678
    #- MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
    #- MINIO_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3


```

通过docker-compose up -d 来启动
![clipboard.png](/posts/juicefs_clipboard-png.png)
接下来进行以下几步操作：
1. 新建一个bucket给juicefs使用，这里我们创建了juicefs。
2. 在Identity -User 里面创建jiuicefs的账户，并且需要创建一个AccessKey和Secretkey
3. 准备一个数据库，redis、postgresql、mysql、etcd都可以，用于给juicefs存放元数据，这里我们采用了redis。

#创建redis服务
redis的docker-compose文件
```yaml
# cat docker-compose-redis.yaml
version: "3.3"
services:
  redis:
    image: redis:latest
    container_name: redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - ./redis/data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
      - ./redis/logs:/logs
    #配置文件启动
    command: redis-server /usr/local/etc/redis/redis.conf
```
redis。conf
```yaml
 cat redis.conf
# Redis 服务器的端口号（默认：6379）
port 6379

# 绑定的 IP 地址，如果设置为 127.0.0.1，则只能本地访问；若设置为 0.0.0.0，则监听所有接口（默认：127.0.0.1）
bind 0.0.0.0

# 设置密码，客户端连接时需要提供密码才能进行操作，如果不设置密码，可以注释掉此行（默认：无）
# requirepass foobared
requirepass xj2023

# 设置在客户端闲置一段时间后关闭连接，单位为秒（默认：0，表示禁用）
# timeout 0

# 是否以守护进程（daemon）模式运行，默认为 "no"，设置为 "yes" 后 Redis 会在后台运行
daemonize no

# 设置日志级别（默认：notice）。可以是 debug、verbose、notice、warning
loglevel notice

# 设置日志文件的路径（默认：空字符串），如果不设置，日志会输出到标准输出
logfile ""

# 设置数据库数量（默认：16），Redis 使用数据库索引从 0 到 15
databases 16

# 是否启用 AOF 持久化，默认为 "no"。如果设置为 "yes"，将在每个写操作执行时将其追加到文件中
appendonly no

# 设置 AOF 持久化的文件路径（默认：appendonly.aof）
# appendfilename "appendonly.aof"

# AOF 持久化模式，默认为 "always"。可以是 always、everysec 或 no
# always：每个写操作都立即同步到磁盘
# everysec：每秒钟同步一次到磁盘
# no：完全依赖操作系统的行为，可能会丢失数据，但性能最高
# appendfsync always

# 设置是否在后台进行 AOF 文件重写，默认为 "no"
# auto-aof-rewrite-on-rewrite no

# 设置 AOF 文件重写触发时，原 AOF 文件大小与新 AOF 文件大小之间的比率（默认：100）
# auto-aof-rewrite-percentage 100

# 设置是否开启 RDB 持久化，默认为 "yes"。如果设置为 "no"，禁用 RDB 持久化功能
save 900 1
save 300 10
save 60 10000

# 设置 RDB 持久化文件的名称（默认：dump.rdb）
# dbfilename dump.rdb

# 设置 RDB 持久化文件的保存路径，默认保存在当前目录
# dir ./

# 设置是否开启对主从同步的支持，默认为 "no"
# slaveof <masterip> <masterport>

# 设置主从同步时是否进行数据完整性校验，默认为 "yes"
# repl-diskless-sync no

# 设置在复制时是否进行异步复制，默认为 "yes"，可以加快复制速度，但会增加数据丢失的风险
# repl-backlog-size 1mb

# 设置是否开启集群模式（cluster mode），默认为 "no"
# cluster-enabled no

# 设置集群中的节点超时时间（默认：15000毫秒）
# cluster-node-timeout 15000

# 设置集群中节点间通信使用的端口号（默认：0）
# cluster-announce-port 0

# 设置集群中节点间通信使用的 IP 地址
# cluster-announce-ip 127.0.0.1

# 设置是否开启慢查询日志，默认为 "no"
# slowlog-log-slower-than 10000

# 设置慢查询日志的最大长度，默认为 128
# slowlog-max-len 128

# 设置每秒最大处理的写入命令数量，用于保护 Redis 服务器不被超负荷写入（默认：0，表示不限制）
# maxclients 10000

# 设置最大连接客户端数量（默认：10000，0 表示不限制）
# maxmemory <bytes>

# 设置最大使用内存的策略（默认：noeviction）。可以是 volatile-lru、allkeys-lru、volatile-random、allkeys-random、volatile-ttl 或 noeviction
# maxmemory-policy noeviction

# 设置允许最大使用内存的比例（默认：0），设置为 0 表示禁用
# maxmemory-samples 5


```
## 使用juicefs
### 安装juicefs
```shell
curl -sSL https://d.juicefs.com/install | sh -

```

创建文件系统

```
juicefs format \
    --storage minio \
    --bucket http://<minio-server>:9000/<bucket> \
    --access-key <your-key> \
    --secret-key <your-secret> \
    redis://:mypassword@<redis-server>:6379/1 \
    myjfs

```

## 挂载juiceFS

### linux
```shell
juicefs mount -d redis://:123456@127.0.0.1:6379/1 /mnt/myjfs -d
```
查看挂载情况
```

df -Th
```
![clipboard2.png](/posts/juicefs_clipboard2-png.png)
自动挂载有两种方式：
1. fstab
从 JuiceFS v1.1.0 开始，挂载命令的 `--update-fstab` 选项能自动帮你设置好开机自动挂载：


2. systemd.mount
基于安全考虑，JuiceFS 将命令行中的一些选项隐藏在环境变量中，所以像数据库访问密码、S3 访问密钥和密钥等设置不能直接应用于 `/etc/fstab` 文件。在这种情况下，你可以使用 systemd 来挂载 JuiceFS 实例。

以下是如何设置 systemd 配置文件的步骤：

1. 创建文件 `/etc/systemd/system/juicefs.mount`，并添加以下内容：

   ```conf
   [Unit]
   Description=Juicefs
   Before=docker.service

   [Mount]
   Environment="ALICLOUD_ACCESS_KEY_ID=mykey" "ALICLOUD_ACCESS_KEY_SECRET=mysecret" "META_PASSWORD=mypassword"
   What=mysql://juicefs@(mysql.host:3306)/juicefs
   Where=/juicefs
   Type=juicefs
   Options=_netdev,allow_other,writeback_cache

   [Install]
   WantedBy=remote-fs.target
   WantedBy=multi-user.target
   ```

   你可以根据需要更改环境变量、挂载选项等。

2. 使用以下命令启用和启动 JuiceFS 挂载：

   ```sh
   ln -s /usr/local/bin/juicefs /sbin/mount.juicefs
   systemctl enable juicefs.mount
   systemctl start juicefs.mount
   ```

完成这些步骤后，就可以访问 `/juicefs` 目录来存取文件了。

再k3s上安装juicefs
![clipboard4.png](/posts/juicefs_clipboard4-png.png)
创建一个nginx来试试
service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-run-service
spec:
  selector:
    app: nginx
  ports:
    - name: http
      port: 80

```
deployment.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Pi
  storageClassName: juicefs-sc
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-run
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: linuxserver/nginx
          ports:
            - containerPort: 80
          volumeMounts:
            - mountPath: /config
              name: web-data
      volumes:
        - name: web-data
          persistentVolumeClaim:
            claimName: web-pvc

```

![clipboard4.png](/posts/juicefs_clipboard4-png.png)
## juice-fs 的storageclass

创建storageclass

```

xfhuang@ubuntu2:~$ cat juicefs-sc.yaml
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://:xj2023@10.7.20.12:6379/1"
  storage: "s3"
  bucket: "http://10.7.20.12:9000/juicefs"
  access-key: "c6VzVSfQvgspXBTW"
  secret-key: "QMY4kHz1y8l1xNEFLX7khVxgilYwuemL"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: juicefs-sc
provisioner: csi.juicefs.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
parameters:
  csi.storage.k8s.io/node-publish-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/node-publish-secret-namespace: kube-system
  csi.storage.k8s.io/provisioner-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system

```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-run-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: "/web"
            backend:
              service:
                name: nginx-run-service
                port:
                  number: 80

```

访问一下ingress
http://192.168.91.131:30805

![clipboard6.png](/posts/juicefs_clipboard6-png.png)

检查一下minio上看看 是否有文件了


查看一下filesystem，我需要等24个小时看看，占多少内存，just waiting。~~

参考文档：
https://juicefs.com/docs/community/juicefs_on_k3s/