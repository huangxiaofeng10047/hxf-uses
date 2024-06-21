---
description: etcd 操作学习
slug: etcd
public: true
title: etcd学习
createdAt: 1718869534095
updatedAt: 1718870227275
tags: []
heroImage: /cover.webp
---
#  增删改查
3.3.1 增
 etcdctl --endpoints=$ENDPOINTS put foo "Hello World!"
3.3.2 查 
etcdctl --endpoints=$ENDPOINTS get foo
etcdctl --endpoints=$ENDPOINTS --write-out="json" get foo 
 
基于相同前缀查找 
 
etcdctl --endpoints=$ENDPOINTS put web1 value1
etcdctl --endpoints=$ENDPOINTS put web2 value2
etcdctl --endpoints=$ENDPOINTS put web3 value3
 
etcdctl --endpoints=$ENDPOINTS get web --prefix
3.3.3 删 
etcdctl --endpoints=$ENDPOINTS put key myvalue
etcdctl --endpoints=$ENDPOINTS del key
 
etcdctl --endpoints=$ENDPOINTS put k1 value1
etcdctl --endpoints=$ENDPOINTS put k2 value2
etcdctl --endpoints=$ENDPOINTS del k --prefix
3.3.4 集群状态
集群状态主要是etcdctl endpoint status 和etcdctl endpoint health两条命令。

etcdctl --write-out=table --endpoints=$ENDPOINTS endpoint status
 
+------------------+------------------+---------+---------+-----------+-----------+------------+
|     ENDPOINT     |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+------------------+------------------+---------+---------+-----------+-----------+------------+
| 10.240.0.17:2379 | 4917a7ab173fabe7 | 3.0.0   | 45 kB   | true      |         4 |      16726 |
| 10.240.0.18:2379 | 59796ba9cd1bcd72 | 3.0.0   | 45 kB   | false     |         4 |      16726 |
| 10.240.0.19:2379 | 94df724b66343e6c | 3.0.0   | 45 kB   | false     |         4 |      16726 |
+------------------+------------------+---------+---------+-----------+-----------+------------+
 
etcdctl --endpoints=$ENDPOINTS endpoint health
 
10.240.0.17:2379 is healthy: successfully committed proposal: took = 3.345431ms
10.240.0.19:2379 is healthy: successfully committed proposal: took = 3.767967ms
10.240.0.18:2379 is healthy: successfully committed proposal: took = 4.025451ms
3.3.5 集群成员
跟集群成员相关的命令如下：

member add          Adds a member into the cluster
member remove    Removes a member from the cluster
member update     Updates a member in the cluster
member list            Lists all members in the cluster 

 例如 etcdctl member list列出集群成员的命令。

etcdctl --endpoints=http://172.16.5.4:12379 member list -w table
 
+-----------------+---------+-------+------------------------+-----------------------------------------------+
|       ID        | STATUS  | NAME  |       PEER ADDRS       |                 CLIENT ADDRS                  |
+-----------------+---------+-------+------------------------+-----------------------------------------------+
| c856d92a82ba66a | started | etcd0 | http://172.16.5.4:2380 | http://172.16.5.4:2379,http://172.16.5.4:4001 |
+-----------------+---------+-------+------------------------+-----------------------------------------------+
3.4 指定授权文件
在执行etcdctl命令时需要指定认证授权文件, 所以将认证授权步骤 别名至 etcdctl 简化操作

# 指定ETCDCTL_API版本为3
$ export ETCDCTL_API=3
 
# 创建etcdctl别名,指定监听地址,和证书
$ alias etcdctl='etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key'
3.4.1 查看etcd集群的成员节点
#etcdctl member list -w table
+------------------+---------+------------+------------------------+------------------------+------------+
|        ID        | STATUS  |    NAME    |       PEER ADDRS       |      CLIENT ADDRS      | IS LEARNER |
+------------------+---------+------------+------------------------+------------------------+------------+
| 8dc8eb40f5ed7ad6 | started | k8s-master | https://10.0.0.16:2380 | https://10.0.0.16:2379 |      false |
+------------------+---------+------------+------------------------+------------------------+------------+
3.4.2 查看etcd集群节点状态
[root@k8s-master][16:19:15][OK] ~/etcdctl/etcd-v3.4.20-linux-amd64 
#etcdctl endpoint status -w table
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://127.0.0.1:2379 | 8dc8eb40f5ed7ad6 |   3.5.3 |   46 MB |      true |      false |        10 |     380897 |             380897 |        |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
 
[root@k8s-master][16:20:35][OK] ~/etcdctl/etcd-v3.4.20-linux-amd64 
#etcdctl endpoint health -w table
+------------------------+--------+-------------+-------+
|        ENDPOINT        | HEALTH |    TOOK     | ERROR |
+------------------------+--------+-------------+-------+
| https://127.0.0.1:2379 |   true | 11.021122ms |       |
+------------------------+--------+-------------+-------+
3.5 备份数据
# 字符串拼接用于定时任务
etcdctl snapshot save `hostname`-etcd_`date +%Y%m%d%H%M`.db
3.6 恢复快照
#停止etcd和apiserver
## 移走当前数据目录
mv /var/lib/etcd/ /var/lib/etcd.bak
 
#恢复快照
etcdctl snapshot restore `hostname`-etcd_`date +%Y%m%d%H%M`.db --data-dir=/var/lib/etcd/
二进制部署的ETCD恢复快照


四、故障排查
journalctl -u etcd > a.log导出日志慢慢分析
