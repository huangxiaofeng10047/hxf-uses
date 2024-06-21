---
description: k3s 工具完全指南
slug: k3s_tools
public: true
title: k3s工具进阶完全指南
createdAt: 1718958074941
updatedAt: 1718958352505
tags: []
heroImage: /cover.webp
---


> **深入理解官方文档，轻松学会使用 K3S 工具！**

`K3s` 是一个轻量级的 `Kubernetes` 发行版，它针对边缘计算、物联网等场景进行了高度优化。

-   `CNCF` 认证的 `Kubernetes` 发行版
-   支持 `X86_64`, `ARM64`, `ARMv7` 平台
-   单一进程包含 `Kubernetes master`，`kubelet` 和 `containerd`


**K3S工具进阶指南**

___

> **为你提供 k3s 的产品介绍**

`K3s` 有以下增强功能：

-   **打包为单个二进制文件**
    -   把 `K8S` 相关的组件，比如 `kube-api`/ `kube-manager` 都打包到同一个二进制文件里面，这样的话，只需要启动这个文件就可以快速的启动对应的组件。
-   **使用基于 sqlite3 的默认存储机制**
    -   同时支持使用 `etcd3`、`MySQL` 和 `PostgreSQL` 作为存储机制。
-   **默认情况下是安全的**
    -   在 `K3s` 中有一个默认的证书管理机制(默认一年有效期)，也有一个可以轮转证书的功能(就是在小于九十天之内重启 `K3s` 的话，就会自动续一年)。
-   **功能强大的 `batteries-included` 功能**
    -   就是虽然有些服务本身这个二进制文件并没有提供，但是可以通过内置的服务，将配置文件放到指定的目录下面，就可以在启动的时候一并将该服务启动或替换默认组件。
-   **所有 `K8S control-plane` 组件都封装在单个二进制文件和进程中**
    -   因为封装在二进制文件中，所以启动的时候只有一个进程。好处在于只需要管理这个单一进程就可以了，同时也具备操作复杂集群的能力。
-   **最大程度减轻了外部依赖性**
    -   即稍新一点的 `Linux` 内核就可以了(需要 `kernel` 和 `cgroup` 挂载)。

之所以叫做 `K3S` 是因为希望安装的 `K8S` 在内存占用方面只是一半的大小，而一半大的东西就是一个 `5` 个字母的单词，简写为 `K3S`。

-   **生命周期**
    -   同时支持 `3` 个 `K8s` 版本，支持的生命周期与 `K8s` 相同
    -   可以参考: [Kubernetes 版本及版本偏差支持策略](https://kubernetes.io/zh/docs/setup/release/version-skew-policy/) 进行学习
-   **更新周期**
    -   当 `K8s` 更新新版本后，一般 `K3s` 在一周内同步更新
    -   可以通过 [这个链接](https://update.k3s.io/v1-release/channels) 获取 **`latest`/`stable`/`testing`** 版本
    -   我们默认安装的是 `stable` 版本，可以运行通过命令进行查看
-   **命名规范**
    -   **v1.20.4+k3s1**: `v1.20.4`  为 `K8s` 版本，`k3s1`  为补丁版本

bash

```bash
# K3s软件包需要的依赖项 containerd # 容器运行时(可以使用docker替代) Flannel # 网络 CoreDNS # DNS CNI # CNI Traefik # 默认的controller服务(apisix/ingress-controller) iptables # 主机实用程序 service load balancer # 嵌入式服务负载均衡器 network policy controller # 嵌入式网络策略控制器 # K3s适用于以下场景 CI Development ARM 嵌入 K8s 物联网-IoT 边缘计算-Edge
```

与此同时，`Rancher` 中国团队推出了一款针对 `K3s` 的效率提升工具：**AutoK3s**。只需要输入一行命令，即可快速创建 `K3s` 集群并添加指定数量的 `master` 节点和 `worker` 节点。

___

## [](https://www.escapelife.site/posts/754ba85c.html#2-K3S-%E5%BF%AB%E9%80%9F%E5%85%A5%E9%97%A8 "2. K3S 快速入门")2\. K3S 快速入门

> **原理就是，将 K8S 的相关组件封装到 K3S 的二进制文件中去！**

原理就是，将 `K8S` 的相关组件封装到 `K3S` 的二进制文件中去，然后启动这二进制文件就可以启动一个成熟的 `K8S` 集群。我们可以看到 `K3S` 和 `K8S` 的架构基本差不多，其中 `k3s-server` 对应这个 `control-plane`，而 `k3s-agent` 对应着 `node` 节点。

可以看到 `k3s` 中使用的默认存储是 `SQLite`(自带)，且默认的网络使用的是 `Flannel`(自带)。当服务端和客户端都启动之后，通过 `Tunnel-Proxy` 这个组件进行通信，通过这个通道去管理网络流量。在 `agent` 节点中，通过 `kubelet` 操作 `contaninerd` 来创建对应 `Pod`。

-   **K3s 架构**


**K3S工具进阶指南**

-   **K8s 架构**


**K3S工具进阶指南**

国内的话，建议使用官方提供的 [镜像地址](https://mirror.rancher.cn/)，这样不但可以加速本地 `K3s` 的时候，而且方便部署和更新服务。这也是为什么建议国内使用 `k3s-install.sh` 部署服务的原因，因为其内部使用的地址都是从国内去获取的。

___

## 3\. K3S 安装事项 - 安装指南

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

虽然可以通过下载二进制文件进行服务端和工作节点的运行(`./k3s server`)，但是一旦我们退出进程，之前创建的节点也就立即销毁了，所以还是建议使用脚本进行安装。

bash

```bash
# 主节点 $ ./k3s server # 工作节点 $ ./k3s agent K3S_URL=xxx K3S_TOKEN=xxx # 清除垃圾文件 $ rm -rf /etc/rancher /var/lib/rancher
```

-   **镜像加速**

bash

```bash
# 添加配置 $ cat >> /etc/rancher/k3s/registries.yaml <<EOF mirrors: "docker.io": endpoint: - "https://fogjl973.mirror.aliyuncs.com" - "https://registry-1.docker.io" EOF # 重启服务 $ sudo systemctl restart k3s # 是否生效 $ sudo crictl info | grep -A 2 "endpoint"
```

`K3s` 提供了一个安装脚本，可以方便的在 `systemd` 或 `openrc` 的系统上将其作为服务安装。运行此安装后，`K3s` 服务将被配置为在节点重启后或进程崩溃或被杀死时自动重启。

-   **安装内容**
    -   `kubectl`、`crictl`、`ctr`
    -   `k3s-killall.sh`、`k3s-uninstall.sh`
-   **执行操作**
    -   将 `kubeconfig` 文件写入到 `/etc/rancher/k3s/k3s.yaml` 里面
    -   由 `K3s` 安装的 `kubectl` 工具将自动使用该文件的配置来运行
    -   其他机器可以通过复制这个配置文件并修改 `server` 地址来操作 `K3s` 集群

___

-   **主节点 - 192.168.100.100**

bash

```bash
# 安装脚本 # https://get.k3s.io $ curl -sfL https://get.k3s.io | sh - # 建议使用这个安装脚本(国内化了) $ curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_NODE_NAME=k3s1 \ K3S_KUBECONFIG_OUTPUT=/home/escape/.kube/config \ INSTALL_K3S_EXEC="--docker" sh -
```

bash

```bash
# 查找stable分支版本信息 [INFO] Finding release for channel stable [INFO] Using v1.23.6+k3s1 as release # 获取国内镜像版本地址 [INFO] Downloading hash https://rancher-mirror.rancher.cn/k3s/v1.23.6-k3s1/sha256sum-amd64.txt [INFO] Downloading binary https://rancher-mirror.rancher.cn/k3s/v1.23.6-k3s1/k3s [INFO] Verifying binary download # 安装k3s二进制工具并链接相关工具(内置) [INFO] Installing k3s to /usr/local/bin/k3s [INFO] Skipping installation of SELinux RPM [INFO] Creating /usr/local/bin/kubectl symlink to k3s [INFO] Creating /usr/local/bin/crictl symlink to k3s [INFO] Skipping /usr/local/bin/ctr symlink to k3s, command exists in PATH at /usr/bin/ctr # 安装清除和卸载k3s生成的配置和工具 [INFO] Creating killall script /usr/local/bin/k3s-killall.sh [INFO] Creating uninstall script /usr/local/bin/k3s-uninstall.sh # 常见了两个systemd的配置 [INFO] env: Creating environment file /etc/systemd/system/k3s.service.env [INFO] systemd: Creating service file /etc/systemd/system/k3s.service [INFO] systemd: Enabling k3s unit Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service. # 启动k3s服务 [INFO] systemd: Starting k3s
```

-   **工作节点 - 192.168.100.101**

bash

```bash
# 工作节点上安装并将它们添加到集群 # https://docs.rancher.cn/docs/k3s/architecture/_index#注册-agent-节点 $ curl -sfL https://get.k3s.io | \ K3S_URL=https://myserver:6443 \ K3S_TOKEN=mynodetoken sh - # 建议使用这个安装命令(国内化了) # K3S_URL: 会使K3s以worker模式运行 # K3S_TOKEN: 使用的值存储在你的服务器节点上 # K3S_NODE_NAME: 为每个节点提供一个有效且唯一的主机名 $ curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_NODE_NAME=k3s2 \ K3S_KUBECONFIG_OUTPUT=/home/escape/.kube/config \ K3S_URL=https://192.168.100.100:6443 \ K3S_TOKEN=mynodetoken sh - # mynodetoken $ sudo cat /var/lib/rancher/k3s/server/token
```

bash

```bash
# 查找stable分支版本信息 [INFO] Finding release for channel stable [INFO] Using v1.23.6+k3s1 as release # 获取国内镜像版本地址 [INFO] Downloading hash https://rancher-mirror.rancher.cn/k3s/v1.23.6-k3s1/sha256sum-amd64.txt [INFO] Downloading binary https://rancher-mirror.rancher.cn/k3s/v1.23.6-k3s1/k3s [INFO] Verifying binary download # 安装k3s二进制工具并链接相关工具(内置) [INFO] Installing k3s to /usr/local/bin/k3s [INFO] Creating /usr/local/bin/kubectl symlink to k3s [INFO] Creating /usr/local/bin/crictl symlink to k3s [INFO] Skipping /usr/local/bin/ctr symlink to k3s # 安装清除和卸载k3s生成的配置和工具 [INFO] Creating killall script /usr/local/bin/k3s-agent-killall.sh [INFO] Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh # 常见了两个systemd的配置 [INFO] env: Creating environment file /etc/systemd/system/k3s-agent.service.env [INFO] systemd: Creating service file /etc/systemd/system/k3s-agent.service [INFO] systemd: Enabling k3s-agent unit Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service. # 启动k3s服务 [INFO] systemd: Starting k3s-agent
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E9%85%8D%E7%BD%AE%E8%A6%81%E6%B1%82 "3. K3S 安装事项 - 配置要求")3\. K3S 安装事项 - 配置要求

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

-   **\[1\] 先决条件**
    -   选择上，两个节点不能有相同的主机名
    -   不修改主机名可以通过添加随机后缀或指定主机名

bash

```bash
# 为每个节点添加随机后缀 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.100.100:6443 \ K3S_TOKEN=xxx sh -s - --with-node-id # 为每个节点指定主机名 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ K3S_NODE_NAME="k3s2" INSTALL_K3S_MIRROR=cn \ K3S_URL=https://192.168.64.3:6443 K3S_TOKEN=xxx sh - # 为每个节点指定主机名 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.64.3:6443 \ K3S_TOKEN=xxx sh -s - --node-name k3s2
```

-   **\[2\] 硬件信息**
    -   操作系统：可以在大多数现代 `Linux` 系统上运行
    -   磁盘设备：`K3s` 的性能取决于数据库的性能(建议使用 `SSD` 硬盘)
    -   网络相关：`K3s Server` 节点的入站规则，所有出站流量都是允许的

| 协议 | 端口 | 源 | 描述 |
| --- | --- | --- | --- |
| TCP | 6443 | K3s agent 节点 | Kubernetes API Server |
| UDP | 8472 | K3s server 和 agent 节点 | 仅对 Flannel VXLAN 需要 |
| TCP | 10250 | K3s server 和 agent 节点 | Kubelet metrics |
| TCP | 2379-2380 | K3s server 节点 | 只有嵌入式 etcd 高可用才需要 |

-   **\[3\] 安装选项**
    -   [官方安装参数文档](https://docs.rancher.cn/docs/k3s/autok3s/_index)
    -   [安装选项示例演示](https://github.com/kingsd041/k3s-tutorial/blob/main/03-%E5%AE%89%E8%A3%85-%E8%A6%81%E6%B1%82%E5%8F%8A%E9%80%89%E9%A1%B9/README.md)

| Environment Variable | Description |
| --- | --- |
| `INSTALL_K3S_EXEC` | 用于在服务中启动 `K3s` 的后续子命令 |
| `K3S_CONFIG_FILE` | 指定配置文件的位置 |
| `K3S_TOKEN` | 用于将 `server/agent` 加入集群的共享 `secret` 值 |
| `K3S_TOKEN_FILE` | 用于将 `server/agent` 加入集群的共享 `secret` 文件 |
| `INSTALL_K3S_VERSION` | 指定下载 `K3s` 的版本 |
| `K3S_TOKEN_FILE` | 指定  `cluster-secret`/`token` 的文件目录 |
| `INSTALL_K3S_SKIP_START` | 将不会启动 `K3s` 服务 |
| `INSTALL_K3S_SKIP_DOWNLOAD` | 用于离线安装；设置之后不会下载远程工具 |

bash

```bash
# 其实就把对应参数加到systemd配置文件里面去了 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--docker" sh - # 自动化部署(不用获取token值了) # 主节点和工作节点使用我们指定的key来通信 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ K3S_TOKEN=rancher-k3s sh - $ sudo cat /var/lib/rancher/k3s/server/token
```

-   **\[4\] 其他说明**
    -   运行 `agent` 时还必须设置 `K3S_TOKEN`
    -   以 `K3S_` 开头的环境变量将被保留，供 `systemd/openrc` 使用
    -   没有明确设置 `exec` 并设置 `K3S_URL` 的话会将命令默认为工作节点

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E5%91%BD%E4%BB%A4%E5%8F%82%E6%95%B0 "3. K3S 安装事项 - 命令参数")3\. K3S 安装事项 - 命令参数

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

在整个 K3s 文档中，你会看到一些选项可以作为命令标志和环境变量传递进来，那该如何使用标志和环境变量呢？

-   **\[1\] 使用标志和环境变量**

bash

```bash
# 使用标志 $ curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - $ curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 # 环境变量 $ curl -sfL https://get.k3s.io | \ INSTALL_K3S_EXEC="--flannel-backend none" sh -s - $ curl -sfL https://get.k3s.io | \ sh -s - server --flannel-backend none
```

-   **\[2\] K3s Server/Agent - 常用配置**

bash

```bash
# write-kubeconfig # 将管理客户端的kubeconfig写入这个文件 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ K3S_KUBECONFIG_OUTPUT=/root/.kube/config \ sh -
```

bash

```bash
# 使用docker作为容器运行时 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--docker" sh - # 指定运行时工具 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--container-runtime-endpoint containerd" \ sh - # 设置私有镜像仓库配置文件 # 默认配置文件: /etc/rancher/k3s/registries.yaml $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--private-registry xxx" \ sh -
```

bash

```bash
# 针对多网卡主机安装K3s集群 # 默认多网卡会使用默认网关的那个卡 $ rout -n # K3s server $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--node-ip=192.168.100.100" \ sh - # K3s agent $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ K3S_URL=https://192.168.99.211:6443 K3S_TOKEN=xxx \ INSTALL_K3S_EXEC="--node-ip=192.168.100.100" \ sh -
```

bash

```bash
# --tls-san # 在TLS证书中添加其他主机名或IP作为主机备用名称 # 即在公网环境下允许通过公网IP访问控制、操作远程集群 # 或者部署多个Server并使用LB进行负责，就需要保留公网地址 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC="--tls-san 1.1.1.1" \ sh - # 获取配置 $ kubectl get secret k3s-serving -n kube-system -o yaml # 然后本机复制公网主节点对应的yaml文件即可本地操作了 $ scp ci@1.1.1.1:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```

bash

```bash
# 修改启动的服务对应配置(调整节点的启动的最大Pod数量) $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--kubelet-arg=max-pods=200' \ sh - # 修改启动的服务对应配置(使用ipvs作为服务调度工具) $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--kube-proxy-arg=proxy-mode=ipvs' \ sh - # 修改启动的服务对应配置(调整服务启动的端口范围) $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--kube-apiserver-arg=service-node-port-range=40000-50000' \ sh - # kubelet-arg --kubelet-arg # kube-apiserver --kube-apiserver-arg # kube-proxy-arg --kube-proxy-arg # kube-proxy-arg --kube-proxy-arg=proxy-mode=ipvs
```

bash

```bash
# --data-dir # 修改K3s数据存储目录 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--data-dir=/opt/k3s-data' \ sh -
```

bash

```bash
# 禁用组件 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--disable traefik' \ sh - # 自己加自己需要的服务 $ ls /var/lib/rancher/k3s/server/manifests $ kubectl get pods -A | grep traefik
```

bash

```bash
# 添加label和taint标识 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--node-label foo=bar,hello=world \ --node-taint key1=value1:NoExecute' sh - # 查看一下 $ kubectl describe nodes
```

-   **\[3\] K3s Server/Agent - 数据库选项**

bash

```bash
# 指定数据源名称 # 标志位: --datastore-endpoint&nbsp;value # 环境变量: K3S_DATASTORE_ENDPOINT $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--datastore-endpoint&nbsp;etcd' \ sh -
```

bash

```bash
# cron规范中的快照间隔时间 # --etcd-snapshot-schedule-cron&nbsp;value $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--etcd-snapshot-schedule-cron *&nbsp;*/5&nbsp;*&nbsp;*&nbsp;*' \ sh -
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E7%BD%91%E7%BB%9C%E9%80%89%E9%A1%B9 "3. K3S 安装事项 - 网络选项")3\. K3S 安装事项 - 网络选项

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

默认情况下，`K3s` 将以 `flannel` 作为 `CNI` 运行，使用 `VXLAN` 作为默认后端，`CNI` 和默认后端都可以通过参数修改。要启用加密，请使用下面的 `IPSec` 或 `WireGuard` 选项。

bash

```bash
# 默认安装K3s之后的网络配置 $ sudo cat /var/lib/rancher/k3s/agent/etc/flannel/net-conf.json { "Network": "10.42.0.0/16", "EnableIPv6": false, "EnableIPv4": true, "IPv6Network": "::/0", "Backend": { "Type": "vxlan" } }
```

| CLI Flag 和 Value | 描述 |
| --- | --- |
| `--flannel-backend=vxlan` | 使用 `VXLAN` 后端(默认) |
| `--flannel-backend=host-gw` | 使用 `host-gw` 后端 |
| `--flannel-backend=ipsec` | 使用 `IPSEC` 后端；对网络流量进行加密 |
| `--flannel-backend=wireguard` | 使用 `WireGuard` 后端；对网络流量进行加密 |

-   **配置 Flannel 选项**

这样，我就可以在安装 `K3s` 或者之后修改对应配置文件，来修改 `Flannel` 默认的后端网络配置选项(重启会覆盖不生效)了。下面，我们演示下，如何修改为 `host-gw` 模式。

bash

```bash
# 主节点 # flannel-backend使用host-gw # 该模式会把对端主机的IP当做默认网管(多Server情况) $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--flannel-backend=host-gw' \ sh - # 工作节点 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.100.100:6443 \ K3S_TOKEN=xxx sh -
```

bash

```bash
# 默认的路由信息 $ route -n 0.0.0.0 172.16.64.1 0.0.0.0 UG 100 0 0 enp0s2 10.42.1.0 172.16.64.9 255.255.255.0 UG 0 0 0 enp0s2 # 查看配置之后的网络配置 $ sudo cat /var/lib/rancher/k3s/agent/etc/flannel/net-conf.json { "Network": "10.42.0.0/16", "Backend": { "Type": "host-gw" } }
```

-   **启用 Directrouting 特性**

**Flannel 自身的特性**：当主机在同一子网时，启用 `direct routes`(如 `host-gw`)。`vxlan`  只用于将数据包封装到不同子网的主机上，同子网的主机之间使用  `host-gw`，默认值为  `false`。

要添加我们就不能修改其对应的网络配置文件，因为重新安装或者重启都会把这个配置冲掉(变成默认配置)，所以需要折中下。我们自建一个网络配置文件，然后在启动的时候执行从哪个配置文件里面加载对应配置。

bash

```bash
# k3s的master和agent $ sudo cat /etc/flannel/net-conf.json { "Network": "10.42.0.0/16", "Backend": { "Type": "vxlan", "Directrouting": true } } # k3s master $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--flannel-backend=host-gw' \ sh -
```

-   **自定义 CNI**

使用  `--flannel-backend=none`(禁用)  运行 `K3s`，然后在安装你选择的 `CNI`。按照 [Calico CNI 插件指南](https://docs.projectcalico.org/master/reference/cni-plugin/configuration) 来修改 `Calico` 的 `YAML` 配置文件，在 `container_settings` 部分中允许 `IP` 转发。

bash

```bash
# 加到Calico的YAML文件中 # 允许IP转发(这个是K3s的一个限制；需要开启) "container_settings": { "allow_ip_forwarding": true } - name: CALICO_IPV4POOL_CIDR value: "192.168.200.0/24"
```

bash

```bash
# 通过在主机上运行以下命令，确保设置已被应用(true) $ sudo cat /etc/cni/net.d/10-canal.conflist # calico # 其中--cluster-cidr可不设置 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--flannel-backend=none \ --cluster-cidr=192.168.200.0/24"' \ sh - # 启动网络服务 $ kubectl apply -f ./calico.yaml
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E5%A4%96%E9%83%A8%E6%95%B0%E6%8D%AE%E5%BA%93 "3. K3S 安装事项 - 外部数据库")3\. K3S 安装事项 - 外部数据库

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

-   **\[1\] 使用外部数据库实现高可用安装**
    -   两个或多个`server` 节点
    -   零个或多个`agent` 节点
    -   外部数据存储(`Etcd/MySQL/PostgRES`)
    -   固定的注册地址(`LB`)
    -   [这应该是最适合国内用户的 K3s HA 方案](https://mp.weixin.qq.com/s/0Wk2MzfWqMqt8DfUK_2ICA)

虽然单节点 `k3s server` 集群可以满足各种用例，但是对于需要稳定运行的重要环境，可以在 `HA` 配置中运行 `K3s`，如何使用外部数据库安装一个高可用的 `K3s` 集群？


**K3S安装事项 - 外部数据库**

| 主机名 | 角色 | IP |
| --- | --- | --- |
| k3s-server-1 | k3s master | 172.31.2.134 |
| k3s-server-2 | k3s master | 172.31.2.42 |
| k3s-db | DB | 172.31.10.251 |
| k3s-lb | LB | 172.31.13.97 |
| k3s-agent | k3s agent | 172.31.15.130 |

bash

```bash
# 1.创建一个外部数据存储 $ docker run --name some-mysql \ --restart=unless-stopped -p 3306:3306 \ -e MYSQL_ROOT_PASSWORD=password -d mysql:5.7 # 2.启动k3s-server节点(有读写权限不用加库名) # mysql://username:password@tcp(hostname:3306)/database-name # 可加污点 --node-taint CriticalAddonsOnly=true:NoExecute $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn sh - server \ --datastore-endpoint="mysql://root:password@ip:3306/k3s" \ --tls-san 172.31.13.97
```

bash

```bash
# 3.配置固定的注册地址(k3s-lb节点) # Agent节点需要一个URL来注册(LB) $ cat >> /etc/nginx.conf <<EOF worker_processes 4; worker_rlimit_nofile 40000; events { worker_connections 8192; } stream { upstream k3s_api { least_conn; server 172.31.2.134:6443 max_fails=3 fail_timeout=5s; server 172.31.2.42:6443 max_fails=3 fail_timeout=5s; } server { listen 6443; proxy_pass k3s_api; } } EOF # 启动服务 $ docker run -d --restart=unless-stopped \ -p 6443:6443 \ -v /etc/nginx.conf:/etc/nginx/nginx.conf \ nginx:1.14
```

bash

```bash
# 4.加入Agent节点 # Agent会保存LB节点和每个Server节点的IP信息 # cat /var/lib/rancher/k3s/agent/etc/k3s-agent-load-balancer.json $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_URL=https://172.31.13.97:6443 K3S_TOKEN=mynodetoken \ sh - # 5.通过kubeconfig访问K3s集群 $ kubectl get nodes NAME STATUS ROLES AGE VERSION k3s-server-1 Ready control-plane,master 68s v1.20.7+k3s1 k3s-server-2 Ready control-plane,master 66s v1.20.7+k3s1
```

___

-   **\[2\] 嵌入式 DB 的高可用**

要在这种模式下运行 `K3s`，你必须有奇数的服务器节点，建议从三个节点开始。在嵌入式中，默认使用 `Etcd` 作为高可用的数据库。

bash

```bash
# 服务器节点(启动etcd集群) # SECRET我们预定一个key值 # 使用cluster-init标志来启用集群 # 并使用一个标记作为共享的密钥来加入其他服务器到集群中 $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_TOKEN=SECRET \ sh -s - --cluster-init # 查看类型 $ sudo kubectl get nodes NAME STATUS ROLES AGE VERSION ip-xxx Ready control-plane,etcd,master 19h v1.23.6+k3s1 # 其他服务器节点(2/3) $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn K3S_TOKEN=SECRET \ sh -s - --server https://<ip-or-host-server>:6443 # 查询ETCD集群状态 # etcd证书默认目录：/var/lib/rancher/k3s/server/tls/etcd # etcd数据默认目录：/var/lib/rancher/k3s/server/db/etcd $ ETCDCTL_ENDPOINTS='https://172.31.12.136:2379,\ https://172.31.4.43:2379,\ https://172.31.4.190:2379' \ ETCDCTL_CACERT='/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt' \ ETCDCTL_CERT='/var/lib/rancher/k3s/server/tls/etcd/server-client.crt'\ ETCDCTL_KEY='/var/lib/rancher/k3s/server/tls/etcd/server-client.key' \ ETCDCTL_API=3 etcdctl endpoint status --write-out=table
```

___

-   **\[3\] 集群数据存储选项**

使用 `etcd` 以外的数据存储运行 `K8S` 的能力使 `K3s` 区别于其他 `K8S` 发行版。该功能为 `K8S` 操作者提供了灵活性，可用的数据存储选项允许你选择一个最适合用例的数据存储。

如果你的团队没有操作 `etcd` 的专业知识，可以选择 `MySQL` 或 `PostgreSQL` 等企业级 `SQL` 数据库。如果您需要在 `CI/CD` 环境中运行一个简单的、短暂的集群，可以使用嵌入式 `SQLite` 数据库

如果你想使用外部数据存储，如 `PostgreSQL`、`MySQL` 或 `etcd`，你必须设置 `datastore-endpoint` 参数，以便 `K3s` 知道如何连接到它，也可以指定参数来配置连接的认证和加密。下表总结了这些参数，它们可以作为 `CLI` 标志或环境变量传递。

| CLI Flag | 环境变量 | 描述 |
| --- | --- | --- |
| `--datastore-endpoint` | `K3S_DATASTORE_ENDPOINT` | 指定一个 PostgresSQL、MySQL 或 etcd 连接字符串。用于描述与数据存储的连接。这个字符串的结构是特定于每个后端的，详情如下。 |
| `--datastore-cafile` | `K3S_DATASTORE_CAFILE` | TLS 证书颁发机构（CA）文件，用于帮助确保与数据存储的通信安全。如果你的数据存储通过 TLS 服务请求，使用由自定义证书颁发机构签署的证书，你可以使用这个参数指定该 CA，这样 K3s 客户端就可以正确验证证书。 |
| `--datastore-certfile` | `K3S_DATASTORE_CERTFILE` | TLS 证书文件，用于对数据存储进行基于客户端证书的验证。要使用这个功能，你的数据存储必须被配置为支持基于客户端证书的认证。如果你指定了这个参数，你还必须指定`datastore-keyfile`参数。 |
| `--datastore-keyfile` | `K3S_DATASTORE_KEYFILE` | TLS 密钥文件，用于对数据存储进行基于客户端证书的认证。更多细节请参见前面的`datastore-certfile`参数。 |

作为最佳实践，我们建议将这些参数设置为环境变量，而不是命令行参数，这样你的数据库证书或其他敏感信息就不会作为进程信息的一部分暴露出来。

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E7%A7%81%E6%9C%89%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93 "3. K3S 安装事项 - 私有镜像仓库")3\. K3S 安装事项 - 私有镜像仓库

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

`K3s` 默认使用 `containerd` 作为容器运行时，所以在 `docker` 上配置镜像仓库是不生效的。`K3s` 镜像仓库配置文件由两大部分组成：`mirrors`  和  `configs`。

-   `Mirrors` 是一个用于定义专用镜像仓库的名称和 `endpoint` 的指令
-   `Configs` 部分定义了每个 `mirror` 的 `TLS` 和证书配置
-   对于每个 `mirror`，你可以定义 `auth` 和 `/` 或 `tls`

`K3s registry` 配置目录为： `/etc/rancher/k3s/registries.yaml`。`K3s` 启动时会检查  `/etc/rancher/k3s/`  中是否存在  `registries.yaml`  文件，并指示 `containerd` 使用文件中定义的镜像仓库。如果你想使用一个私有的镜像仓库，那么你需要在每个使用镜像仓库的节点上以 `root` 身份创建这个文件。

请注意，`server` 节点默认是可以调度的。如果你没有在 `server` 节点上设置污点，那么将在它们上运行工作负载，请确保在每个 `server` 节点上创建  `registries.yaml`  文件。

`containerd` 使用了类似 `K8S` 中 `svc` 与 `endpoint` 的概念，`svc` 可以理解为访问名称，这个名称会解析到对应的 `endpoint` 上。也可以理解 `mirror` 配置就是一个反向代理，它把客户端的请求代理到 `endpoint` 配置的后端镜像仓库。`mirror` 名称可以随意填写，但是必须符合 `IP` 或域名的定义规则。并且可以配置多个 `endpoint`，默认解析到第一个 `endpoint`，如果第一个 `endpoint` 没有返回数据，则自动切换到第二个 `endpoint`，以此类推。

yaml

```yaml
# /etc/rancher/k3s/registries.yaml # 同时可以设置多个mirrors地址 # 可以对mirrors设置权限和证书 mirrors: "172.31.6.200:5000": endpoint: - "http://172.31.6.200:5000" - "http://x.x.x.x:5000" - "http://y.y.y.y:5000" "rancher.ksd.top:5000": endpoint: - "http://172.31.6.200:5000" "docker.io": endpoint: - "https://fogjl973.mirror.aliyuncs.com" - "https://registry-1.docker.io" configs: "172.31.6.200:5000": auth: username: admin password: Harbor@12345 tls: cert_file: /home/ubuntu/harbor2.escapelife.site.cert key_file: /home/ubuntu/harbor2.escapelife.site.key ca_file: /home/ubuntu/ca.crt
```

bash

```bash
# 镜像都是从同一个仓库获取到的 $ sudo systemctl restart k3s.service $ sudo crictl pull 172.31.6.200:5000/library/alpine $ sudo crictl pull rancher.ksd.top:5000/library/alpine
```

这里我们介绍下，如何使用 `TLS` 配置。

bash

```bash
# 证书颁发机构颁发的证书 $ cat >> /etc/rancher/k3s/registries.yaml <<EOF mirrors: "harbor.escapelife.site": endpoint: - "https://harbor.escapelife.site" configs: "harbor.escapelife.site": auth: username: admin password: Harbor@12345 EOF $ sudo systemctl restart k3s
```

bash

```bash
# 自签名证书 $ cat >> /etc/rancher/k3s/registries.yaml <<EOF mirrors: "harbor2.escapelife.site": endpoint: - "https://harbor2.escapelife.site" configs: "harbor2.escapelife.site": auth: username: admin password: Harbor@12345 tls: cert_file: /home/ubuntu/harbor2.escapelife.site.cert key_file: /home/ubuntu/harbor2.escapelife.site.key ca_file: /home/ubuntu/ca.crt EOF $ sudo systemctl restart k3s
```

bash

```bash
# 不使用TLS证书 $ cat >> /etc/rancher/k3s/registries.yaml <<EOF mirrors: "docker.io": endpoint: - "https://fogjl973.mirror.aliyuncs.com" - "https://registry-1.docker.io" EOF $ sudo systemctl restart k3s
```

`K3s` 将会在 `/var/lib/rancher/k3s/agent/etc/containerd/config.toml` 中为 `containerd` 生成  `config.toml`。如果要对这个文件进行高级设置，你可以在同一目录中创建另一个名为  `config.toml.tmpl`  的文件，此文件将会代替默认设置。

bash

```bash
# 完整示例 $ cat >> /etc/rancher/k3s/registries.yaml mirrors: "harbor.escapelife.site": endpoint: - "https://harbor.escapelife.site" "harbor2.escapelife.site": endpoint: - "https://harbor2.escapelife.site" "172.31.19.227:5000": endpoint: - "http://172.31.19.227:5000" "docker.io": endpoint: - "https://fogjl973.mirror.aliyuncs.com" - "https://registry-1.docker.io" configs: "harbor.escapelife.site": auth: username: admin password: Harbor@12345 "harbor2.escapelife.site": auth: username: admin password: Harbor@12345 tls: cert_file: /home/ubuntu/harbor2.escapelife.site.cert key_file: /home/ubuntu/harbor2.escapelife.site.key ca_file: /home/ubuntu/ca.crt
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E7%A6%BB%E7%BA%BF%E5%AE%89%E8%A3%85 "3. K3S 安装事项 - 离线安装")3\. K3S 安装事项 - 离线安装

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

离线安装的过程主要分为以下两个步骤：

-   **步骤 1**：部署镜像
    -   **部署私有镜像仓库**
    -   **手动部署镜像**
-   **步骤 2**：安装 `K3s` 工具
    -   **单节点安装**
    -   **高可用安装**

___

-   **通过私有镜像仓库安装 K3s**
    -   `k3s-images.txt` 包含对于版本依赖的镜像文件
    -   `k3s-airgap-images-amd64.tar` 包含对于版本的镜像文件

bash

```bash
# 将所需镜像上传到私有镜像仓库 # https://github.com/k3s-io/k3s/releases 可以从K3s镜像列表获取到版本，下载上传到私有镜像仓库 # 创建镜像仓库(YAML) # 按照私有镜像仓库配置指南创建并配置registry.yaml文件 $ mkdir -p /etc/rancher/k3s/ cat >> /etc/rancher/k3s/registries.yaml <<EOF mirrors: "docker.io": endpoint: - "https://harbor.escapelife.site" configs: "docker.io": auth: username: admin password: Harbor@12345 EOF
```

bash

```bash
# 安装单节点K3s集群 # https://github.com/k3s-io/k3s/releases 可以从K3s仓库获取到版本(二进制文件) # 获取K3s安装脚本 $ wget https://get.k3s.io -o ./install.sh $ wget http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh # 安装K3s-server $ INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh # 将agent加入到K3s集群 $ INSTALL_K3S_SKIP_DOWNLOAD=true \ K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken \ ./install.sh
```

-   **通过手动部署镜像安装 K3s**

bash

```bash
# 从Github页面获取你所运行的K3s版本及文件 # https://github.com/rancher/k3s/releases k3s二进制文件+镜像tar文件 # 将tar文件放在images目录下 $ sudo mkdir -p /var/lib/rancher/k3s/agent/images/ $ sudo cp ./k3s-airgap-images-$ARCH.tar /var/lib/rancher/k3s/agent/images/ # 将k3s二进制文件放在/usr/local/bin/k3s路径上 $ mv ./k3s /usr/local/bin/ $ chmod 755 /usr/local/bin/k3s # 安装K3s-server $ INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh # 将agent加入到K3s集群 $ INSTALL_K3S_SKIP_DOWNLOAD=true \ K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken \ ./install.sh
```

离线升级 `K3s` 版本，完成离线安装 `K3s` 后，还可以通过脚本升级 `K3s` 版本，或启用自动升级功能，以保持离线环境中的 `K3s` 版本与最新的 `K3s` 版本同步。

-   **升级 K3s 版本**

bash

```bash
# 通过脚本升级 # https://github.com/rancher/k3s/releases 从Github页面下载要升级到的K3s版本 # 替换 # 复制并替换每个节点上/usr/local/bin中的旧K3s二进制文件 $ mv ./k3s /usr/local/bin/ $ chmod 755 /usr/local/bin/k3s $ wget http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh # 重启K3s服务 $ sudo systemctl restart k3s.service
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E4%BB%AA%E8%A1%A8%E7%9B%98%E5%8F%8A%E5%8D%B8%E8%BD%BD "3. K3S 安装事项 - 仪表盘及卸载")3\. K3S 安装事项 - 仪表盘及卸载

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

推荐使用三种仪表盘工具，分别是对应是 `Kubernetes Dashboard`、`kube-explorer` 和 `Rancher UI`，其各自各有优劣。

-   **\[1\] Kubernetes Dashboard**

bash

```bash
# 部署Kubernetes仪表盘 $ GITHUB_URL=https://github.com/kubernetes/dashboard/releases $ VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S \ ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||') $ sudo k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
```

bash

```bash
# 仪表盘RBAC配置 # 本指南中创建的admin-user将在仪表盘中拥有管理权限 $ sudo k3s kubectl create \ -f dashboard.admin-user.yml \ -f dashboard.admin-user-role.yml # dashboard.admin-user.yml apiVersion: v1 kind: ServiceAccount metadata: name: admin-user namespace: kubernetes-dashboard # dashboard.admin-user-role.yml apiVersion: rbac.authorization.k8s.io/v1 kind: ClusterRoleBinding metadata: name: admin-user roleRef: apiGroup: rbac.authorization.k8s.io kind: ClusterRole name: cluster-admin subjects: - kind: ServiceAccount name: admin-user namespace: kubernetes-dashboard
```

bash

```bash
# 获得Bearer-Token $ sudo k3s kubectl -n kubernetes-dashboard \ describe secret admin-user-token | grep '^token' # 本地访问仪表盘 # https://192.168.100.100:8443 # https://www.escapelife.site/posts/180e93f1.html # https://www.escapelife.site/posts/538ec6b1.html $ sudo k3s kubectl proxy $ sudo kubectl -n kubernetes-dashboard port-forward \ --address 0.0.0.0 svc/kubernets-dashboard 8443:443
```

bash

```bash
# 升级仪表盘 $ sudo k3s kubectl delete ns kubernetes-dashboard $ GITHUB_URL=https://github.com/kubernetes/dashboard/releases $ VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||') $ sudo k3s kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml # ## 删除仪表盘和admin-user配置 $ sudo k3s kubectl delete ns kubernetes-dashboard $ sudo k3s kubectl delete clusterrolebinding kubernetes-dashboard $ sudo k3s kubectl delete clusterrole kubernetes-dashboard
```

-   **\[2\] kube-explorer**
    -   `kube-explorer` 是 `K8S` 的便携式资源管理器，没有任何依赖
    -   并提供了一个几乎完全无状态的 `K8S` 资源管理器

bash

```bash
# 从发布页面下载二进制文件 # https://github.com/cnrancher/kube-explorer # 运行 # --kubeconfig 可以不配置(自己可以找到) $ ./kube-explorer --kubeconfig=/etc/rancher/k3s/kube.yaml \ --http-listen-port=9898 \ --https-listen-port=0 # 打开浏览器访问 http://192.168.100.100:9898
```

-   **\[3\] Rancher UI**
    -   可以将 `K3s` 导入到 `Rancher UI` 中去管理
    -   官网 [导入 K3s 集群](http://docs.rancher.cn/docs/rancher2/cluster-provisioning/imported-clusters/_index/#%E5%AF%BC%E5%85%A5-k3s-%E9%9B%86%E7%BE%A4) 指导文档

bash

```bash
# 导入K3s集群时，Rancher会将其识别为K3s类型，并且附件额外功能 # 1.能够升级K3s版本 # 2.可配置升级集群时升级的最大节点数 # 3.在主机详情页能够查看启动K3s集群时每个节点的配置参数和环境变量 # 配置K3s集群以允许导入到Rancher $ curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn sh -s - \ --write-kubeconfig-mode 644
```

-   **\[4\] 卸载 K3s 服务**

bash

```bash
# 主节点 $ /usr/local/bin/k3s-uninstall.sh # 工作节点 $ /usr/local/bin/k3s-agent-uninstall.sh
```

bash

```bash
# 包括docker等信息一并清理 #!/bin/bash KUBE_SVC=' kubelet kube-scheduler kube-proxy kube-controller-manager kube-apiserver ' for kube_svc in ${KUBE_SVC}; do # 停止服务 if [[ `systemctl is-active ${kube_svc}` == 'active' ]]; then systemctl stop ${kube_svc} fi # 禁止服务开机启动 if [[ `systemctl is-enabled ${kube_svc}` == 'enabled' ]]; then systemctl disable ${kube_svc} fi done # 停止所有容器 docker stop $(docker ps -aq) # 删除所有容器 docker rm -f $(docker ps -qa) # 删除所有容器卷 docker volume rm $(docker volume ls -q) # 卸载mount目录 for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done # 备份目录 mv /etc/kubernetes /etc/kubernetes-bak-$(date +"%Y%m%d%H%M") mv /var/lib/etcd /var/lib/etcd-bak-$(date +"%Y%m%d%H%M") mv /var/lib/rancher /var/lib/rancher-bak-$(date +"%Y%m%d%H%M") mv /opt/rke /opt/rke-bak-$(date +"%Y%m%d%H%M") # 删除残留路径 rm -rf /etc/ceph \ /etc/cni \ /opt/cni \ /run/secrets/kubernetes.io \ /run/calico \ /run/flannel \ /var/lib/calico \ /var/lib/cni \ /var/lib/kubelet \ /var/log/containers \ /var/log/kube-audit \ /var/log/pods \ /var/run/calico \ /usr/libexec/kubernetes # 清理网络接口 no_del_net_inter=' lo docker0 eth ens bond ' network_interface=`ls /sys/class/net` for net_inter in $network_interface; do if ! echo "${no_del_net_inter}" | grep -qE ${net_inter:0:3}; then ip link delete $net_inter fi done # 清理残留进程 port_list=' 80 443 6443 2376 2379 2380 8472 9099 10250 10254 ' for port in $port_list; do pid=`netstat -atlnup | grep $port | awk '{print $7}' | awk -F '/' '{print $1}' | grep -v - | sort -rnk2 | uniq` if [[ -n $pid ]]; then kill -9 $pid fi done kube_pid=`ps -ef | grep -v grep | grep kube | awk '{print $2}'` if [[ -n $kube_pid ]]; then kill -9 $kube_pid fi # 清理Iptables表 ## 注意：如果节点Iptables有特殊配置，以下命令请谨慎操作 sudo iptables --flush sudo iptables --flush --table nat sudo iptables --flush --table filter sudo iptables --table nat --delete-chain sudo iptables --table filter --delete-chain systemctl restart docker
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#3-K3S-%E5%AE%89%E8%A3%85%E4%BA%8B%E9%A1%B9-%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9 "3. K3S 安装事项 - 注意事项")3\. K3S 安装事项 - 注意事项

> **理解 Server 节点的安装，以及注册 Agent 节点的步骤！**

-   **Helm**
    
    -   如果需要使用 `helm` 操作 `K3s` 集群，需要创建 `~/.kube/conf` 目录
    -   需要执行 `cp /etc/rancher/k3s/k3s.yaml ~/.kube/config` 命令
-   **自动部署的清单**
    
    -   将由 `rancher/helm-controller` 在运行时安装
    -   目录路径：`/var/lib/rancher/k3s/server/manifests`
    -   目录下面的每个 `yaml` 就代表这个一个需要启动的服务

对于我们希望使用的组件，可以在启动的时候禁用默认组件，在手动部署你需要的一些组件(通常是放到一个指定目录下面，随着服务启动自动拉起)，从而达到灵活使用的目的。

bash

```bash
# 查看所有Pod服务 # 比如helm/coredns也不是自带的就是通过这个方式创建的 $ sudo kubectl get pods -A
```

-   **注册 Agent 节点**
    -   工作节点密码存储：`/etc/rancher/node/password`
    -   主节点的密码存储：`/var/lib/rancher/k3s/server/cred/node-passwd`

在 `agent` 节点运行注册命令，会和 `server` 节点发起 `websocket` 连接，然后会在工作节点上面创建一个随机的密码。然后会拿着这个密码和工作节点的主机名，发送给主节点。然后主节点会将这个信息在保存(`k8s secrets`)起来，随后的任何尝试都必须使用相同的密码。

bash

```bash
# 工作节点的密码信息(password+hostname) $ sudo cat /etc/rancher/node/password # 查看主节点的密码信息 # https://docs.rancher.cn/docs/k3s/architecture/_index#注册-agent-节点 $ sudo kubectl get secret k3s2.node-password.k3s -o yaml -n kube-system # 可以查看日志信息验证这个信息的存在 $ sudo tail -200f /var/log/syslog | grep k3s
```

bash

```bash
# 发现节点信息提示NotReady状态 # 可以尝试删除节点的密码存储信息，之后会自动获取新的 $ sudo kubectl delete secret k3s2.node-password.k3s -n kube-system
```

-   **自定义存储类型**

集群启动之后，默认会启动一个 `local-path` 的组件，用于提供服务挂载存储使用，其默认以 `PVC` 的形式。之后，将其存储在 `/var/lib/rancher/k3s/server/storageclass` 目录下面。

bash

```bash
# 查看组件 $ sudo kubectl get pods -A # 查看对应存储 $ sudo kubectl get storageclass # 可以使用参数修改默认存储地址 # --default-local-storage-path&nbsp;value $ curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | \ INSTALL_K3S_MIRROR=cn \ INSTALL_K3S_EXEC='--etcd-snapshot-schedule-cron *&nbsp;*/5&nbsp;*&nbsp;*&nbsp;*' \ sh -
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#4-K3S-%E9%9B%86%E7%BE%A4%E5%8D%87%E7%BA%A7 "4. K3S 集群升级")4\. K3S 集群升级

> **手动升级 + 自动升级**

当升级 `K3s` 时，`K3s` 服务会重启或停止，但 `K3s` 容器会继续运行。 要停止所有的 `K3s` 容器并重置容器的状态，可以使用  `k3s-killall.sh`  脚本。 `killall` 脚本清理容器、`K3s` 目录和网络组件，同时也删除了 `iptables` 链和所有相关规则。集群数据不会被删除。

-   **\[1\] 手动升级 - 使用安装脚本升级 K3s**

你可以通过使用安装脚本升级 `K3s`，或者手动安装所需版本的二进制文件。

bash

```bash
# 升级到最新stable版本 $ curl -sfL https://get.k3s.io | sh - # 升级到latest版本 $ curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh - # 升级到v1.20的最新版本 $ curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL="v1.20" sh - # 升级到指定版本 $ curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=vX.Y.Z-rc1 sh -
```

-   **\[2\] 手动升级 - 使用二进制文件手动升级 K3s**

你可以通过使用安装脚本升级 `K3s`，或者手动安装所需版本的二进制文件。

bash

```bash
# 从发布下载所需版本的K3s二进制文件 https://github.com/rancher/k3s/releases # 将下载的二进制文件复制到/usr/local/bin/k3s $ mv ./k3s /usr/local/bin/k3s # 停止旧的K3s二进制文件 $ curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL="v1.20" sh - # 启动新的K3s二进制文件 $ curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=vX.Y.Z-rc1 sh -
```

你可以使用 `Rancher` 的 `system-upgrad-controller` 来管理 `K3s` 集群升级。这是一种 `Kubernetes` 原生的集群升级方法。它利用自定义资源定义(`CRD`)、计划和控制器，根据配置的计划安排升级。

控制器通过监控计划和选择要在其上运行升级 `job`  的节点来调度升级，计划通过标签选择器定义哪些节点应该升级。当一个 `job` 成功运行完成后，控制器会给它运行的节点打上相应的标签。

-   **\[3\] 自动升级 - 使用二进制文件手动升级 K3s**
    -   [k3s-upgrade](https://github.com/rancher/k3s-upgrade)
    -   [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller)

bash

```bash
# 将system-upgrade-controller安装到您的集群中 $ kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
```

yaml

```yaml
# 配置计划 # 建议您最少创建两个计划 # 升级server节点的计划和升级agent节点的计划 # Server plan apiVersion: upgrade.cattle.io/v1 kind: Plan metadata: name: server-plan namespace: system-upgrade spec: concurrency: 1 cordon: true nodeSelector: matchExpressions: - key: node-role.kubernetes.io/master # 选择主节点 operator: In values: - "true" serviceAccountName: system-upgrade upgrade: image: rancher/k3s-upgrade version: v1.20.4+k3s1 # Agent plan apiVersion: upgrade.cattle.io/v1 kind: Plan metadata: name: agent-plan namespace: system-upgrade spec: concurrency: 1 cordon: true nodeSelector: matchExpressions: - key: node-role.kubernetes.io/master # 选择工作节点 operator: DoesNotExist prepare: args: - prepare - server-plan image: rancher/k3s-upgrade serviceAccountName: system-upgrade upgrade: image: rancher/k3s-upgrade version: v1.20.4+k3s1
```

yaml

```yaml
# 自动升级到最新版本(不指定版本) apiVersion: upgrade.cattle.io/v1 kind: Plan ... spec: ... upgrade: image: rancher/k3s-upgrade channel: https://update.k3s.io/v1-release/channels/stable
```


**K3S集群升级**

___

## 5\. K3S 备份恢复

> **SQLite + etcd + 外部数据存储**

-   **\[1\] 使用嵌入式 SQLite 数据存储进行备份和恢复**

bash

```bash
# 方式1：备份/恢复数据目录 # 备份 $ cp -rf /var/lib/rancher/k3s/server/db /opt/db # 恢复 $ systemctl stop k3s $ rm -rf /var/lib/rancher/k3s/server/db $ cp -rf /opt/db /var/lib/rancher/k3s/server/db $ systemctl start k3s
```

bash

```bash
# 方式2：通过 SQLite cli # 备份 sqlite3 /var/lib/rancher/k3s/server/db/state.db SQLite version 3.22.0 2018-01-22 18:45:57 Enter ".help" for usage hints. sqlite> .backup "/opt/kine.db" sqlite> .exit # 恢复 $ sudo systemctl stop k3s sqlite3 /var/lib/rancher/k3s/server/db/state.db SQLite version 3.22.0 2018-01-22 18:45:57 Enter ".help" for usage hints. sqlite> .restore '/opt/kine.db' sqlite> .exit $ sudo systemctl start k3s
```

当使用外部数据存储时，备份和恢复操作是在 `K3s` 之外处理的。数据库管理员需要对外部数据库进行备份，或者从快照或转储中进行恢复。我们建议将数据库配置为执行定期快照。

-   **\[2\] 使用外部数据存储进行备份和恢复**

bash

```bash
# 备份 $ mysqldump -uroot -p --all-databases --master-data > k3s-dbdump.db # 恢复 $ systemctl stop k3s $ mysql -uroot -p < k3s-dbdump.db $ systemctl start k3s
```

-   **\[3\] 使用嵌入式 etcd 数据存储进行备份和恢复**

bash

```bash
# 创建快照(K3s默认启用快照) # 快照目录默认: /var/lib/rancher/k3s/server/db/snapshots # 要配置快照间隔或保留的快照数量 --etcd-disable-snapshots 禁用自动etcd快照 --etcd-snapshot-schedule-cron 定时快照的时间点；认值为每12小时触发一次 --etcd-snapshot-retention 保留的快照数量；默认值为5 --etcd-snapshot-dir 保存数据库快照的目录路径 --cluster-reset 忘记所有的对等体；成为新集群的唯一成员 --cluster-reset-restore-path 要恢复的快照文件的路径
```

当 `K3s` 从备份中恢复时，旧的数据目录将被移动到`/var/lib/rancher/k3s/server/db/etcd-old/`。然后 `K3s` 会尝试通过创建一个新的数据目录来恢复快照，然后从一个带有一个 `etcd` 成员的新 `K3s` 集群启动 `etcd`。

bash

```bash
# 从快照恢复集群 # 使用--cluster-reset选项运行K3s # 同时给出--cluster-reset-restore-path $ ./k3s server \ --cluster-reset \ --cluster-reset-restore-path=<PATH-TO-SNAPSHOT>
```

___

## 6. K3S 卷和存储

> **介绍了如何通过 local storage provider 或 Longhorn 来设置持久存储。**

当部署一个需要保留数据的应用程序时，你需要创建持久存储。持久存储允许您从运行应用程序的 `pod` 外部存储应用程序数据。即使应用程序的 `pod` 发生故障，这种存储方式也可以使您维护应用程序数据。

-   **\[1\] 设置 Local Storage Provider 支持**

`K3s` 自带 `Rancher` 的 `Local Path Provisioner`(`LPP`)，这使得能够使用各自节点上的本地存储来开箱即用地创建 `pvc`。根据用户配置，`LPP` 将自动在节点上创建基于 `hostPath` 的持久卷。它利用了 `K8s` 的 `Local Persistent Volume` 特性引入的特性，但它比 `K8s` 中内置的  `local pv`  特性更简单的解决方案。

yaml

```yaml
# pvc.yaml apiVersion: v1 kind: PersistentVolumeClaim metadata: name: local-path-pvc namespace: default spec: accessModes: - ReadWriteOnce storageClassName: local-path resources: requests: storage: 2Gi # pod.yaml apiVersion: v1 kind: Pod metadata: name: volume-test namespace: default spec: containers: - name: volume-test image: nginx:stable-alpine imagePullPolicy: IfNotPresent volumeMounts: - name: volv mountPath: /data ports: - containerPort: 80 volumes: - name: volv persistentVolumeClaim: claimName: local-path-pvc
```

bash

```bash
# 应用yaml服务 $ kubectl create -f pvc.yaml pod.yaml # 确认PV和PVC已创建 $ kubectl get pv $ kubectl get pvc
```

-   **\[2\] 设置 Longhorn 支持**

`K3s` 支持 `Longhorn`(是 `K8s` 的一个开源分布式块存储系统)。

bash

```bash
# 安装Longhorn # 将被安装在命名空间longhorn-system中 $ kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml # pvc.yaml apiVersion: v1 kind: PersistentVolumeClaim metadata: name: longhorn-volv-pvc spec: accessModes: - ReadWriteOnce storageClassName: longhorn resources: requests: storage: 2Gi # pod.yaml apiVersion: v1 kind: Pod metadata: name: volume-test namespace: default spec: containers: - name: volume-test image: nginx:stable-alpine imagePullPolicy: IfNotPresent volumeMounts: - name: volv mountPath: /data ports: - containerPort: 80 volumes: - name: volv persistentVolumeClaim: claimName: longhorn-volv-pvc
```

bash

```bash
# 应用yaml服务 $ kubectl create -f pvc.yaml pod.yaml # 确认PV和PVC已创建 $ kubectl get pv $ kubectl get pvc
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#7-K3S-%E7%BD%91%E7%BB%9C%E7%9B%B8%E5%85%B3 "7. K3S 网络相关")7\. K3S 网络相关

> **简单介绍下 K3s 相关的网络配置组件！**

-   **CoreDNS**

`CoreDNS` 是在 `agent` 节点启动时部署的。要禁用，请在每台服务器上运行 `--disable coredns` 选项。如果你不安装 `CoreDNS`，你将需要自己安装一个集群 `DNS` 提供商。

bash

```bash
# 如何修改coredns参数 # /var/lib/rancher/k3s/server/manifests/coredns.yaml # 该文件重启K3s服务的话会导致coredns配置重新初始化 1.将coredns.yaml保存到其他目录 2.通过 --disable coredns 禁用coredns 3.复制coredns.yaml到/var/lib/rancher/k3s/server/manifests/目录并修改参数
```

-   **Traefik Ingress Controller**

启动 `server` 时，默认情况下会部署 `Traefik`，对该文件的任何修改都会以类似 `kubectl apply` 的方式自动部署到 `Kubernetes` 中，将使用主机上的 `80` 和 `443` 端口。

bash

```bash
# 操作和上面基本是一致的 # 请使用 --disable traefik 选项启动每个server # /var/lib/rancher/k3s/server/manifests/traefik.yaml
```

yaml

```yaml
# 如何启用 treafik2 dashboard # http://traefik.example.com/dashboard # Note: in a kubernetes secret the string (e.g. generated by htpasswd) must be base64-encoded first. # To create an encoded user:password pair, the following command can be used: # htpasswd -nb admin admin | openssl base64 apiVersion: v1 kind: Secret metadata: name: authsecret namespace: default data: users: |2 YWRtaW46JGFwcjEkLkUweHd1Z0EkUjBmLi85WndJNXZWRFMyR2F2LmtELwoK --- apiVersion: traefik.containo.us/v1alpha1 kind: IngressRoute metadata: name: traefik-dashboard spec: routes: - match: Host(`traefik.example.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`)) kind: Rule services: - name: api@internal kind: TraefikService middlewares: - name: auth --- apiVersion: traefik.containo.us/v1alpha1 kind: Middleware metadata: name: auth spec: basicAuth: secret: authsecret # Kubernetes secret named "secretName"
```

-   **Service Load Balancer**

`K3s` 提供了一个名为 `Klipper Load Balancer` 的负载均衡器，它可以使用可用的主机端口。 允许创建 `LoadBalancer` 类型的 `Service`，但不包括 `LB` 的实现。某些 `LB` 服务需要云提供商，例如 `Amazon EC2`。相比之下，`K3s service LB` 使得可以在没有云提供商的情况下使用 `LB` 服务。

___

## [](https://www.escapelife.site/posts/754ba85c.html#8-K3S-%E4%B8%8E-Helm "8. K3S 与 Helm")8\. K3S 与 Helm

> **`Helm` 是 `Kubernetes` 的包管理工具！**

`Helm` 是 `Kubernetes` 的包管理工具。`Helm Chart` 为 `Kubernetes YAML` 清单文件提供了模板化语法，可以通过 `Helm` 安装对应的 `chart`。`K3s` 不需要任何特殊的配置就可以使用 `Helm` 命令行工具。

-   **自动部署 Helm charts**

在 `/var/lib/rancher/k3s/server/manifests` 中找到的任何 `Kubernetes` 清单将以类似 `kubectl apply` 的方式自动部署到 `K3s`。以这种方式部署的 `manifests` 是作为 `AddOn` 自定义资源来管理的。你会发现打包组件的 `AddOns`，如 `CoreDNS`、`Local-Storage` 等。`AddOns` 是由部署控制器自动创建的，并根据它们在 `manifests` 目录下的文件名命名。

bash

```bash
# 查看运行AddOn资源 $ kubectl get addon -A # 也可以将Helm-Chart作为AddOns部署 https://github.com/rancher/helm-controller/
```

-   **使用 Helm CRD**

`HelmChart CRD` 捕获了大多数你通常会传递给 `helm` 命令行工具的选项。下面是一个例子，说明如何从默认的 `Chart` 资源库中部署 `Grafana`，覆盖一些默认的 `Chart` 值。请注意，`HelmChart` 资源本身在 `kube-system` 命名空间，但 `Chart` 资源将被部署到 `monitoring` 命名空间。

yaml

```yaml
apiVersion: helm.cattle.io/v1 kind: HelmChart metadata: name: grafana namespace: kube-system spec: chart: stable/grafana targetNamespace: monitoring set: adminPassword: "NotVerySafePassword" valuesContent: |- image: tag: master env: GF_EXPLORE_ENABLED: true adminUser: admin sidecar: datasources: enabled: true
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#9-K3S-%E9%AB%98%E7%BA%A7%E9%80%89%E9%A1%B9 "9. K3S 高级选项")9\. K3S 高级选项

> **[包含高级选项和配置](https://github.com/kingsd041/k3s-tutorial/blob/main/17-%E9%AB%98%E7%BA%A7%E9%80%89%E9%A1%B9%E5%92%8C%E9%85%8D%E7%BD%AE/README.md)**

-   **证书轮换**

默认情况下，`K3s` 的证书在 `12` 个月内过期。如果证书已经过期或剩余的时间不足 `90` 天，则在 `K3s` 重启时轮换证书。

bash

```bash
# 查询K3s证书过期时间 $ for i in `ls /var/lib/rancher/k3s/server/tls/*.crt`; \ do \ echo $i;\ openssl x509 -enddate -noout -in $i; \ done # 修改系统时间为证书过期前90天或证书过期后 $ timedatectl set-ntp no $ date -s 20220807 # 重启K3s服务 $ service k3s restart
```

-   **Red Hat 和 CentOS 的额外准备**

建议运行以下命令，关闭 `firewalld` 防火墙。

shell

```shell
$ sudo systemctl disable firewalld --now
```

___

## [](https://www.escapelife.site/posts/754ba85c.html#10-%E5%8F%82%E8%80%83%E9%93%BE%E6%8E%A5 "10. 参考链接")10\. 参考链接

> **送人玫瑰，手有余香！**

-   **\[1\] 文档教程**
    
    -   [K3s 中文文档 - 国外](http://mirror.cnrancher.com/)
    -   [K3s 中文文档 - 国内](https://docs.rancher.cn/k3s)
    -   [K3s 国内镜像站 - 加速](https://mirror.rancher.cn/)
    -   [K3s 系列教程 - 官方制作](https://github.com/kingsd041/k3s-tutorial)
-   **\[2\] 代码地址**
    
    -   [K3s 仓库地址 - Github](https://github.com/k3s-io)
-   **\[3\] 周边项目**
    
    -   [K3s 周边项目 - k3os](https://github.com/rancher/k3os)
        -   完全基于 `K8S` 管理的轻量级操作系统
    -   [K3s 周边项目 - autok3s](https://github.com/cnrancher/autok3s)
        -   用于简化 `K3s` 集群部署和管理的轻量级工具
        -   即在阿里云和 `aws` 等云服务器上面部署 `k3s`
    -   [K3s 周边项目 - k3d](https://github.com/rancher/k3d)
        -   可以在 `k3d` 创建容器化的 `k3s` 集群
        -   可以使用容器在单台计算机上启动多节点 `k3s` 集群
    -   [K3s 周边项目 - harvester](https://github.com/rancher/harvester)
        -   基于 `K8S` 构建的开源超融合基础架构(`HCI`)软件
        -   旨在替换 `vSphere` 和 `Nutanix` 的开源替代方案
    -   [K3s 周边项目 - octopus](https://github.com/cnrancher/octopus)
        -   主要用于边缘计算相关
        -   用于 `K8S` 和 `k3s` 的轻量级云原生设备管理系统
        -   集群可以将边缘设备作为自定义 `k8s` 资源进行管理
-   **\[4\] 学习视频**
    
    -   [K3s 快闪直播系列 01-课程介绍及 K3s 介绍](https://www.bilibili.com/video/BV1yR4y1g7Ud)
    -   [K3s 快闪直播系列: 02-K3s 架构及快速入门](https://www.bilibili.com/video/BV14u411m7YT)
    -   [K3s 快闪直播系列: 03-安装-要求及选项](https://www.bilibili.com/video/BV1Gu411m7vx)
    -   [K3s 快闪直播系列: 04-安装-K3s Server 和 Agent 配置](https://www.bilibili.com/video/BV1du41127YC)
    -   [K3s 快闪直播系列: 05-安装-网络选项](https://www.bilibili.com/video/BV1uR4y1M7Nm)
    -   [K3s 快闪直播系列: 06-08 K3s 高可用安装](https://www.bilibili.com/video/BV1c3411Y7mM)
    -   [K3s 快闪直播系列: 09-安装-私有镜像仓库配置参考](https://www.bilibili.com/video/BV16m4y1U7LS)
    -   [K3s 快闪直播系列: 10-安装-离线安装](https://www.bilibili.com/video/BV1Q44y157LM)
    -   [K3s 快闪直播系列: 11-安装-仪表盘及卸载 K3s](https://www.bilibili.com/video/BV1SL4y1b7g7)
    -   [K3s 快闪直播系列: 12-升级 k3s 集群](https://www.bilibili.com/video/BV16R4y1g77f)
    -   [K3s 快闪直播系列: 13-备份和恢复](https://www.bilibili.com/video/BV1Dm4y1U7fw)
    -   [K3s 快闪直播系列: 14-卷和存储](https://www.bilibili.com/video/BV19r4y1v7UT)
    -   [K3s 快闪直播系列: 15-网络](https://www.bilibili.com/video/BV1tZ4y1f7Bb)
    -   [K3s 快闪直播系列: 16-Helm](https://www.bilibili.com/video/BV1wS4y1773w)
    -   [K3s 快闪直播系列: 17-高级选项和配置](https://www.bilibili.com/video/BV1cS4y177Lt)

原文地址： https://www.escapelife.site/posts/754ba85c.html 
防止丢失了。