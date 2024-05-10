---
description: wsl2 网络配置
slug: wsl2
public: true
title: WSL2的网络配置方案
createdAt: 1715238289405
updatedAt: 1715332619620
tags:
  - wsl
  - archlinxu
heroImage: /astrojs.jpg
---
wsl.config
```
[wsl2]                      # 核心配置
autoProxy=false             # 是否强制 WSL2/WSLg 子系统使用 Windows 代理设置（请根据实际需要启用）
dnsTunneling=true           # WSL2/WSLg DNS 代理隧道，以便由 Windows 代理转发 DNS 请求（请根据实际需要启用）
firewall=true               # WSL2/WSLg 子系统的 Windows 防火墙集成，以便 Hyper-V 或者 WPF 能过滤子系统流量（请根据实际需要启用）
guiApplications=true        # 启用 WSLg GUI 图形化程序支持
ipv6=true                   # 启用 IPv6 网络支持
localhostForwarding=true    # 启用 localhost 网络转发支持
memory=16GB                  # 限制 WSL2/WSLg 子系统的最大内存占用
nestedVirtualization=true   # 启用 WSL2/WSLg 子系统嵌套虚拟化功能支持
networkingMode=mirrored     # 启用镜像网络特性支持
#pageReporting=true          # 启用 WSL2/WSLg 子系统页面文件通报，以便 Windows 回收已分配但未使用的内存
processors=6                # 设置 WSL2/WSLg 子系统的逻辑 CPU 核心数为 8（最大肯定没法超过硬件的物理逻辑核心数）
kernel=D:\\bzImage


[experimental]                  # 实验性功能
autoMemoryReclaim=gradual       # 启用空闲内存自动缓慢回收
hostAddressLoopback=true        # 启用 WSL2/WSLg 子系统和 Windows 宿主之间的本地回环互通支持
sparseVhd=true                  # 启用 WSL2/WSLg 子系统虚拟硬盘空间自动回收
useWindowsDnsCache=false        # 和 dnsTunneling 配合使用，决定是否使用 Windows DNS 缓存池
```
在wsl2的系统中/etc/wsl.config
```
# 此配置文件不能通过 cd /etc && ln -Ps /mnt/d/Devs/WSL/wsl.conf wsl.conf 来配置，只能通过拷贝副本
# https://docs.microsoft.com/en-us/windows/wsl/wsl-config

[automount]
enabled=true
mountFsTab=true
options="metadata,dmask=0022,fmask=0077,umask=0022"
root=/mnt/

[filesystem]
umask=0022

[interop]
enabled=true
appendWindowsPath=false   # 不添加 Windows 环境变量 Path，防止路径变量污染带来的干扰

# 其它网络配置
[network]
generateHosts=true
generateResolvConf=true


# boot command 暂不支持 nohup 后台启动
# command=nohup service cron start >/dev/null 2>&1 &
[boot]
# command=/root/.start.sh
systemd=true
```
idea配置需要如下所示：
这个是help-》 find Action -》 registry 
![clipboard2.png](/posts/wsl2_clipboard2-png.png)
运行过程直接选择应用，不可以在下方的maven界面执行maven命令
![clipboard3.png](/posts/wsl2_clipboard3-png.png)
执行命令请到terminal中执行。