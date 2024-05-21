---
description: '# minikube配置网络为calico BGP模式'
slug: minikube
public: true
title: minikube配置网络为calico BGP模式
createdAt: 1716168024270
updatedAt: 1716259081398
tags: []
heroImage: /cover.webp
---
## 1.基础环境

卸载单机版的k8s
使用kubespray卸载
```shell

 ansible all -i inventory/mycluster/hosts.yaml -m shell -a "sudo systemctl stop firewalld && sudo systemctl disable firewalld"
 ansible-playbook -i inventory/mycluster/hosts.yaml -u root  --become --become-user=root reset.yml

注意查看网络，发现了一个dnsmasq 启动了一个libvert的虚拟网卡。
```

### 1.1 硬件基础信息

| CPU | 内存 | 存储 | 备注 |
| --- | --- | --- | --- |
| 4 vcpu | 12G RAM | 160GB | VM中开启嵌套虚拟化 |

### 1.2 软件基础信息

| 主机名 | OS | IP | 容器 |
| --- | --- | --- | --- |
| minikube.sec.com | AlmaLinux release 9.2 | 10.20.28.170 | docker 24.0.2 |

### 1.3 minikube版本信息

| Minikube版本 | Kubernetes版本 | CNI | 备注 |
| --- | --- | --- | --- |
| minikube v1.30.1 | kubernetes v1.26.3 | calico v3.26.0 |  |

## 2.基础配置

### 2.1 基础配置

```sh
# 优化SSH链接 
sed -i 's/^#UseDNS no/UseDNS no/g' /etc/ssh/sshd_config 
sed -i 's/^GSSAPIAuthentication no/GSSAPIAuthentication no/g' /etc/ssh/sshd_config 
# 关闭防火墙 
systemctl stop firewalld 
systemctl disable firewalld 
# 关闭selinux 
setenforce 0 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 
# 网络相关的配置 
/etc/NetworkManager/system-connections/ens192.nmconnection 
# 安装一些常用工具 
yum install wget curl net-tools vim -y
```

### 2.2 安装docker

```sh
# 设置docker软件安装源 
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo 
# docker 安装 
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y 
# 设置docker镜像加速源 
cat <<EOF > /etc/docker/daemon.json 
{ 
"registry-mirrors": [ 
   "https://docker.nju.edu.cn/" 
   ] 
}
EOF 
# 启动docker和设置docker开机自启动 
systemctl enable docker 
systemctl start docker
```

### 3.1 部署minikube

-   \[[minikube start | minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/start/)\]([minikube start | minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/start/))

```sh
# 下载minikube软件 
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 
# 指定下载特定版本 
curl -LO https://storage.googleapis.com/minikube/releases/v1.30.1/minikube-linux-amd64 
# 安装minikube 
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
![clipboard.png](/posts/minikube_clipboard-png.png)

### 3.2 部署kubernetes

-   查看可部署的kubernetes版本

```sh
$ minikube config defaults kubernetes-version 
* v1.27.0-rc.0
……………省略………………… 
* v1.16.13
```

-   [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/)
-   [https://docs.tigera.io/calico/latest/getting-started/kubernetes/minikube](https://docs.tigera.io/calico/latest/getting-started/kubernetes/minikube)

```sh
minikube start \
--nodes 3 \
--driver=docker \
--network-plugin=cni \
--extra-config=kubeadm.pod-network-cidr=192.168.0.0/16 \
--service-cluster-ip-range=10.96.0.0/16 \
--kubernetes-version=v1.30.0 \
--base-image=docker.io/kicbase/stable:v0.0.39 \
--registry-mirror=https://docker.nju.edu.cn \
--cpus=2 \
--memory=4096mb \
--container-runtime=containerd
--force

```
![clipboard2.png](/posts/minikube_clipboard2-png.png)

-   可用词解释

```sh
--nodes 3 设置节点为3个 
--driver=docker 设置驱动类型为docker 
--network-plugin=cni 设置cni为calico 
--extra-config=kubeadm.pod-network-cidr=192.168.0.0/16 设置podIP 
--service-cluster-ip-range=10.96.0.0/16 设置cluster ip 
--kubernetes-version=v1.26.3 设置kubernetes版本 
--registry-mirror=https://docker.nju.edu.cn 设置生成的容器内的docker镜像源 
--base-image=docker.io/kicbase/stable:v0.0.39 指定base image 
--image-mirror-country=cn 设置kubernetes源为阿里，本次实验阿里源有问题，故不设置 
--cpus=2 设置每个虚拟节点为2vcpu 
--memory=4096mb 设置每个虚拟节点为4G 
--container-runtime=containerd 设置containerd为运行环境
```
![clipboard4.png](/posts/minikube_clipboard4-png.png)
![clipboard5.png](/posts/minikube_clipboard5-png.png)

-   给node打标签

```sh
# 原有状态 
$kubectl get nodes 
# 打标签 
kubectl label node minikube kubernetes.io/role=master 
kubectl label node minikube-m02 kubernetes.io/role=worker 
kubectl label node minikube-m03 kubernetes.io/role=worker 
# 新标签状态 
$ kubectl get nodes 
# 查看机器状态 
$ kubectl get nodes -o wide 
```
![clipboard6.png](/posts/minikube_clipboard6-png.png)
打标签之后查看
![clipboard7.png](/posts/minikube_clipboard7-png.png)
![clipboard8.png](/posts/minikube_clipboard8-png.png)
-   实际k8s以docker形态运行

```sh
$ docker ps -a 

```
出现docker无法下载镜像报错，连接192.168.49.1 timeout，解决办法，进入到docker容器内部
```shell
start minikube normally minikube start
enter the container where minikube is running minikube ssh or you can use docker exec -it minikube /bin/bash
raise sudo su privileges
then you can cat your /etc/resolv.conf file and you will have output like this:
root@minikube:~$ cat /etc/resolv.conf
nameserver 192.168.49.1
options ndots:0
add nameserver 8.8.8.8 to your /etc/resolv.conf file, you can do it as follows:
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```
![clipboard14.png](/posts/minikube_clipboard14-png.png)

### 3.3 部署calico

```sh
$ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml 
$ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml
```
![clipboard12.png](/posts/minikube_clipboard12-png.png)
## 4\. 安装kubernetes插件

### 4.1 部署dashboard

```sh
$ minikube addons enable dashboard
```

-   运行状态

```sh
$ kubectl get pods -n kubernetes-dashboard 
```
等待成功部署
![clipboard13.png](/posts/minikube_clipboard13-png.png)
去掉镜像后面的hash校验。
![clipboard14.png](/posts/minikube_clipboard14-png.png)

### 4.2 部署metrics-server

```sh
$ minikube addons enable metrics-server
```

-   镜像下载异常的处理方式

```sh
$ minikube addons enable metrics-server 
* metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub. You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS - Using image registry.k8s.io/metrics-server/metrics-server:v0.6.3 * The 'metrics-server' addon is enabled 
# 会显示失败，原因为registry.k8s.io/metrics-server/metrics-server:v0.6.3镜像没有下载完成 
$kubectl get pods -n kube-system -l k8s-app=metrics-server 
NAME READY STATUS RESTARTS AGE 
metrics-server-6588d95b98-8lnkh 0/1 ImagePullBackOff 0 8m39s 
# 处理方式，修改配置中的image为docker.io/bitnami/metrics-server:0.6.3 
$ minikube image pull docker.io/bitnami/metrics-server:0.6.3 
$ kubectl edit deployment metrics-server -n kube-system # 处理后的运行状态 
$ kubectl get pods -n kube-system -l k8s-app=metrics-server N
AME READY STATUS RESTARTS AGE metrics-server-674d9c9c69-tc896 1/1 Running 0 12h metrics-server-77f9d5b8d7-b5cpw 1/1 Running 0 12h metrics-server-85cd7db5fb-p76xn 1/1 Running 0 12h
```
minikube image load registry.tar


## 5\. 网络开启BGP

### 5.1 宿主机开启BGP

-   安装frr软件

```sh
$ sudo yum install -y epel-release 
$ sudo yum install -y frr 
$ sudo sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons 
$ sudo systemctl enable frr 
$ sudo systemctl start frr
```

-   配置BGP,语法和cisco一致

```text
$ sudo vtysh 
minikube.sec.com# conf t 
minikube.sec.com(config)# 
minikube.sec.com(config-router)# router bgp 65001 
minikube.sec.com(config-router)# bgp router-id 192.168.49.1 
minikube.sec.com(config-router)# no bgp ebgp-requires-policy 
minikube.sec.com(config-router)# neighbor 192.168.49.2 remote-as 65002 
minikube.sec.com(config-router)# neighbor 192.168.49.3 remote-as 65002 
minikube.sec.com(config-router)# neighbor 192.168.49.4 remote-as 65002 
minikube.sec.com(config-router)# exit 
minikube.sec.com(config-router)# end
```

### 5.2 Calico开启BGP

-   配置calico模式为BGP

```sh
$ cat calico-bgp-configuration.yaml 
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: false
  asNumber: 65002
  serviceClusterIPs:
  - cidr: 10.96.0.0/18
  serviceExternalIPs:
  - cidr: 10.110.0.0/18
  listenPort: 179
  bindMode: NodeIP
  communities:
  - name: bgp-minikube
    value: 65002:300:100
  prefixAdvertisements:
  - cidr: 192.168.0.0/18
    communities:
    - bgp-minikube
    - 65002:120
$ kubectl apply -f calico-bgp-configuration.yaml
```
报错crd not found
帮助下载镜像的命令
```shell
 minikube image pull docker.io/calico/cni:v3.25.1 
```
安装成功
![clipboard14.png](/posts/minikube_clipboard14-png.png)


-   配置calico对端BGP邻居

```sh
$ cat calico-bgp-peer.yaml 
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: centos9-peer
spec:
  peerIP: 192.168.49.1
  keepOriginalNextHop: true
  asNumber: 65001
$ kubectl apply -f calico-bgp-peer.yaml

```

### 5.3 查看BGP路由

```sh
$ sudo vtysh
minikube.sec.com# show ip route bgp 
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

B>* 10.96.0.0/18 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
  *                     via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
  *                     via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 10.110.0.0/18 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
  *                      via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
  *                      via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.0.0/24 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.0.1/32 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.0.2/32 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.0.3/32 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.1.0/24 [20/0] via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.1.1/32 [20/0] via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.1.2/32 [20/0] via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.2.0/24 [20/0] via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.2.1/32 [20/0] via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.2.2/32 [20/0] via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.2.3/32 [20/0] via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.23.0/26 [20/0] via 192.168.49.4, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.29.192/26 [20/0] via 192.168.49.3, br-2004107383f1, weight 1, 00:04:56
B>* 192.168.39.0/26 [20/0] via 192.168.49.2, br-2004107383f1, weight 1, 00:04:56
B   192.168.49.0/24 [20/0] via 192.168.49.2 inactive, weight 1, 00:04:56
                           via 192.168.49.3 inactive, weight 1, 00:04:56
                           via 192.168.49.4 inactive, weight 1, 00:04:56
minikube.sec.com# 


``` 

![clipboard15.png](/posts/minikube_clipboard15-png.png)
### 5.4 远程机器添加路由网段

-   在终端机器中执行路由添加

```bat
route add  10.96.0.0 mask 255.255.192.0 10.7.20.12
route add  10.110.0.0 mask 255.255.192.0 10.7.20.12
route add  192.168.49.0 mask 255.255.255.0 10.7.20.12


```

-   在终端windows机器上测试网络

```powershell
$ kubectl get svc -A
NAMESPACE          NAME                              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   calico-api                        ClusterIP   10.96.29.75   <none>        443/TCP                  26h
calico-system      calico-kube-controllers-metrics   ClusterIP   None          <none>        9094/TCP                 26h
calico-system      calico-typha                      ClusterIP   10.96.60.16   <none>        5473/TCP                 26h
default            kubernetes                        ClusterIP   10.96.0.1     <none>        443/TCP                  27h
kube-system        kube-dns                          ClusterIP   10.96.0.10    <none>        53/UDP,53/TCP,9153/TCP   27h

# 测试网络


```

### 5.5 iptables放行

-   查看现有iptables策略

```sh
$ sudo iptables -L
……………………………………………………………………省略………………………………………………………………………………………………
Chain DOCKER (2 references)
target     prot opt source               destination
ACCEPT     tcp  --  anywhere             192.168.49.2         tcp dpt:32443
ACCEPT     tcp  --  anywhere             192.168.49.2         tcp dpt:pcsync-https
ACCEPT     tcp  --  anywhere             192.168.49.2         tcp dpt:commplex-main
ACCEPT     tcp  --  anywhere             192.168.49.2         tcp dpt:docker-s
ACCEPT     tcp  --  anywhere             192.168.49.2         tcp dpt:ssh
ACCEPT     tcp  --  anywhere             192.168.49.3         tcp dpt:32443
ACCEPT     tcp  --  anywhere             192.168.49.3         tcp dpt:pcsync-https
ACCEPT     tcp  --  anywhere             192.168.49.3         tcp dpt:commplex-main
ACCEPT     tcp  --  anywhere             192.168.49.3         tcp dpt:docker-s
ACCEPT     tcp  --  anywhere             192.168.49.3         tcp dpt:ssh
ACCEPT     tcp  --  anywhere             192.168.49.4         tcp dpt:32443
ACCEPT     tcp  --  anywhere             192.168.49.4         tcp dpt:pcsync-https
ACCEPT     tcp  --  anywhere             192.168.49.4         tcp dpt:commplex-main
ACCEPT     tcp  --  anywhere             192.168.49.4         tcp dpt:docker-s
ACCEPT     tcp  --  anywhere             192.168.49.4         tcp dpt:ssh
……………………………………………………………………省略………………………………………………………………………………………………

```

-   放行策略，允许外部访问pod，cluster，external-cluster ip

```sh
 sudo iptables -t filter -I DOCKER -d 192.168.0.0/18 ! -i br-f9a7012660d1 -o  br-f9a7012660d1 -j ACCEPT
 sudo iptables -t filter -I DOCKER -d 10.96.0.0/18 ! -i  br-f9a7012660d1 -o  br-f9a7012660d1 -j ACCEPT
 sudo iptables -t filter -I DOCKER -d 10.110.0.0/18 ! -i  br-f9a7012660d1 -o  br-f9a7012660d1 -j ACCEPT

```

## 6\. 配置负载为IPVS

-   每个虚拟K8S容器都需要执行

```sh
# 远程到对应k8s容器中
minikube ssh -n 'name'

# 执行ipvs组件安装
sudo apt install -y ipset ipvsadm

# 设置加载模块
cat <<EOF > /etc/modules-load.d/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF

# 加载模块
chmod 755 /etc/modules-load.d/ipvs.modules && bash /etc/modules-load.d/ipvs.modules

```

-   执行修改为ipvs模式

```sh
# 修改mode为ipvs 
$ kubectl edit configmap kube-proxy -n kube-system 
mode: ""#原配置此处为空，需要修改为mode: "ipvs"
```

## 7\. 配置purelb负载均衡

### 7.1 部署purelb

```sh
wget https://gitlab.com/api/v4/projects/purelb%2Fpurelb/packages/generic/manifest/0.0.1/purelb-complete.yaml
# 第一次可能会报错，需要再次运行一次
kubectl apply -f purelb-complete.yaml
kubectl apply -f purelb-complete.yaml

```

### 7.2 配置purelb地址池

```sh
# 删除不需要的功能
kubectl delete ds -n purelb lbnodeagent

# 配置purelb地址池
-> cat purelb-ipam.yaml
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: bgp-ippool
  namespace: purelb
spec:
  local:
    v4pool:
      subnet: '10.110.0.0/18'
      pool: '10.110.0.0-10.110.63.254'
      aggregation: /32

```


-   **本文作者：** [二乘八是十六](https://www.cnblogs.com/amsilence)
-   **本文链接：** [https://www.cnblogs.com/amsilence/p/17478716.html](https://www.cnblogs.com/amsilence/p/17478716.html)
-   **关于博主：** 评论和私信会在第一时间回复。或者[直接私信](https://msg.cnblogs.com/msg/send/amsilence)我。
-   **版权声明：** 本博客所有文章除特别声明外，均采用 [BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/ "BY-NC-SA") 许可协议。转载请注明出处！

测试
部署完成之后我们在k8s集群中部署一个nginx测试一下是否能够正常工作。首先我们创建一个名为`nginx-quic`的命名空间（`namespace`），然后在这个命名空间内创建一个名为`nginx-quic-deployment`的`deployment`用来部署pod，最后再创建一个`service`用来暴露服务，这里我们同时使用`nodeport`和`LoadBalancer`两种方式来暴露服务，并且其中一个`LoadBalancer`的服务还要指定`LoadBalancerIP`方便我们测试。
```shell
# cat ngx-system.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-quic

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-quic-deployment
  namespace: nginx-quic
spec:
  selector:
    matchLabels:
      app: nginx-quic
  replicas: 4
  template:
    metadata:
      labels:
        app: nginx-quic
    spec:
      containers:
      - name: nginx-quic
        image: tinychen777/nginx-quic:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-headless-service
  namespace: nginx-quic
spec:
  selector:
    app: nginx-quic
  clusterIP: None


---

apiVersion: v1
kind: Service
metadata:
  name: nginx-quic-service
  namespace: nginx-quic
spec:
  externalTrafficPolicy: Cluster
  selector:
    app: nginx-quic
  ports:
  - protocol: TCP
    port: 8080 # match for service access port
    targetPort: 80 # match for pod access port
    nodePort: 30088 # match for external access port
  type: NodePort


---

apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip-service
  namespace: nginx-quic
spec:
  selector:
    app: nginx-quic
  ports:
  - protocol: TCP
    port: 8080 # match for service access port
    targetPort: 80 # match for pod access port
  type: ClusterIP

---

apiVersion: v1
kind: Service
metadata:
  annotations:
    purelb.io/service-group: bgp-ippool
  name: nginx-lb-service
  namespace: nginx-quic
spec:
  allocateLoadBalancerNodePorts: true
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  selector:
    app: nginx-quic
  ports:
  - protocol: TCP
    port: 80 # match for service access port
    targetPort: 80 # match for pod access port
  type: LoadBalancer
  loadBalancerIP: 10.33.192.80


---

apiVersion: v1
kind: Service
metadata:
  annotations:
    purelb.io/service-group: bgp-ippool
  name: nginx-lb2-service
  namespace: nginx-quic
spec:
  allocateLoadBalancerNodePorts: true
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  selector:
    app: nginx-quic
  ports:
  - protocol: TCP
    port: 80 # match for service access port
    targetPort: 80 # match for pod access port
  type: LoadBalancer
```
部署完成之后我们检查各项服务的状态

```shell
-bash-4.2$ kubectl get pods -n nginx-quic -o wide                              NAME                                     READY   STATUS    RESTARTS   AGE     IP                NODE           NOMINATED NODE   READINESS GATES
nginx-quic-deployment-684bc585f7-446sf   1/1     Running   0          2m59s   192.168.205.194   minikube-m02   <none>           <none>
nginx-quic-deployment-684bc585f7-dlwpp   1/1     Running   0          2m59s   192.168.120.65    minikube       <none>           <none>
nginx-quic-deployment-684bc585f7-ghtfx   1/1     Running   0          2m59s   192.168.205.195   minikube-m02   <none>           <none>
nginx-quic-deployment-684bc585f7-lnps2   1/1     Running   0          2m59s   192.168.151.9     minikube-m03   <none>           <none>
-bash-4.2$ kubectl get svc -n nginx-quic -o wide                               NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE     SELECTOR
nginx-clusterip-service   ClusterIP      10.96.178.183   <none>        8080/TCP         4m23s   app=nginx-quic
nginx-headless-service    ClusterIP      None            <none>        <none>           4m23s   app=nginx-quic
nginx-lb-service          LoadBalancer   10.96.36.21     <pending>     80:30203/TCP     4m23s   app=nginx-quic
nginx-lb2-service         LoadBalancer   10.96.18.228    10.110.0.0    80:32202/TCP     4m23s   app=nginx-quic
nginx-quic-service        NodePort       10.96.248.61    <none>        8080:30088/TCP   4m23s   app=nginx-quic
-bash-4.2$ curl 10.110.0.0
192.168.49.2:36881

```
随后我们分别在集群内外的机器进行测试，分别访问podIP 、clusterIP和loadbalancerIP。

```shell
# 查看是否能够正确返回集群外的客户端的IP地址10.31.100.100
# 在集群外访问pod IP
root@tiny-unraid:~# curl 10.33.26.2
10.31.100.100:43240
# 在集群外访问clusterIP
root@tiny-unraid:~# curl 10.33.151.137
10.31.90.5:52758
# 在集群外访问loadbalancerIP
root@tiny-unraid:~# curl 10.33.192.0
10.31.90.5:7319
# 在集群外访问loadbalancerIP
root@tiny-unraid:~# curl 10.33.192.80
10.31.90.5:38170

# 查看是否能够正确返回集群内的node的IP地址10.31.90.1
# 在集群内的node进行测试
[root@k8s-calico-master-10-31-90-1 ~]# curl 10.33.26.2
10.31.90.1:40222
[root@k8s-calico-master-10-31-90-1 ~]# curl 10.33.151.137
10.31.90.1:50773
[root@k8s-calico-master-10-31-90-1 ~]# curl 10.33.192.0
10.31.90.1:19219
[root@k8s-calico-master-10-31-90-1 ~]# curl 10.33.192.80
10.31.90.1:22346

# 查看是否能够正确返回集群内的pod的IP地址10.33.93.3
# 在集群内的pod进行测试
[root@nginx-quic-deployment-5d7d9559dd-8gm7s /]# curl 10.33.26.2
10.33.93.3:39560
[root@nginx-quic-deployment-5d7d9559dd-8gm7s /]# curl 10.33.151.137
10.33.93.3:58160
[root@nginx-quic-deployment-5d7d9559dd-8gm7s /]# curl 10.33.192.0
10.31.90.6:34183
[root@nginx-quic-deployment-5d7d9559dd-8gm7s /]# curl 10.33.192.80
10.31.90.6:64266
```
最后检测一下路由器端的情况，可以看到对应的podIP、clusterIP和loadbalancerIP段路由

### 测试

正常情况下启用BGP广播后，三分钟内核心交换即可接收到路由信息。

```shell
-bash-4.2$ dig -x 192.168.205.194 @10.96.0.10

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> -x 192.168.205.194 @10.96.0.10
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19212
;; flags: qr aa rd; QUERY: 1, ANSWER: 5, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;194.205.168.192.in-addr.arpa.  IN      PTR

;; ANSWER SECTION:
194.205.168.192.in-addr.arpa. 30 IN     PTR     192-168-205-194.nginx-headless-service.nginx-quic.svc.cluster.local.
194.205.168.192.in-addr.arpa. 30 IN     PTR     192-168-205-194.nginx-clusterip-service.nginx-quic.svc.cluster.local.
194.205.168.192.in-addr.arpa. 30 IN     PTR     192-168-205-194.nginx-quic-service.nginx-quic.svc.cluster.local.
194.205.168.192.in-addr.arpa. 30 IN     PTR     192-168-205-194.nginx-lb2-service.nginx-quic.svc.cluster.local.
194.205.168.192.in-addr.arpa. 30 IN     PTR     192-168-205-194.nginx-lb-service.nginx-quic.svc.cluster.local.

;; Query time: 1 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Tue May 21 10:34:06 CST 2024
;; MSG SIZE  rcvd: 588


# 输出

-bash-4.2$ curl 192.168.205.194
192.168.49.3:49676

```