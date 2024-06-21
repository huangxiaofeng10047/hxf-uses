---
description: k3s 创建一主一从的集群
slug: k3s
public: true
title: k3s实践
createdAt: 1718872466238
updatedAt: 1718946068425
tags: []
heroImage: /cover.webp
---
# Use JuiceFS on K3s

[K3s](https://k3s.io/) is a functionally optimized lightweight Kubernetes distribution that is fully compatible with Kubernetes.In other words, almost all operations performed on Kubernetes can also be executed on K3s. K3s packages the entire container orchestration system into a binary program with a size of less than 100MB, significantly reducing the environment dependencies and installation steps required to deploy Kubernetes production clusters. Compared to Kubernetes, K3s has lower performance requirements for the operating system.

In this article, we will build a K3s cluster with two nodes, install and configure [JuiceFS CSI Driver](https://github.com/juicedata/juicefs-csi-driver) for the cluster, and lastly create an NGINX Pod for verification.

## Deploy a K3s cluster[​](https://juicefs.com/docs/community/juicefs_on_k3s/#deploy-a-k3s-cluster "Direct link to heading")

K3s has very low **minimum requirements** for hardware:

- **Memory**: 512MB+ (recommend 1GB+)
- **CPU**: 1 core

When deploying a production cluster, it is recommended to start with a minimum hardware configuration of 4 cores and 8GB of memory per node. For more detailed information, please refer to the [Hardware Requirements](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#hardware) documentation.

### K3s server node[​](https://juicefs.com/docs/community/juicefs_on_k3s/#k3s-server-node "Direct link to heading")

The IP address of the server node is: `192.168.1.35`

You can use the official script provided by K3s to deploy the server node on a regular Linux distribution.

```shell
curl -sfL https://get.k3s.io | sh -
```

After the deployment is successful, the K3s service will automatically start, and kubectl and other tools will also be installed at the same time.

You can execute the following command to view the status of the node:

```shell
$ sudo kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
k3s-s1   Ready    control-plane,master   28h   v1.21.4+k3s1
```

Get the `node-token`:

```shell
sudo -u root cat /var/lib/rancher/k3s/server/node-token
```

### K3s worker node[​](https://juicefs.com/docs/community/juicefs_on_k3s/#k3s-worker-node "Direct link to heading")

The IP address of the worker node is: `192.168.1.36`

Execute the following command and change the value of `K3S_URL` to the IP or domain name of the server node (the default port is `6443`). Replace the value of `K3S_TOKEN` with the `node-token` obtained from the server node.

```shell
curl -sfL https://get.k3s.io | K3S_URL=http://192.168.1.35:6443 K3S_TOKEN=K1041f7c4fabcdefghijklmnopqrste2ec338b7300674f::server:3d0ab12800000000000000006328bbd80 sh -
```

After the deployment is successful, go back to the server node to check the node status:

```shell
xfhuang@ubuntu2:~$ sudo kubectl get nodes
NAME       STATUS   ROLES                  AGE     VERSION
ubuntu2    Ready    control-lane,master   7m33s   v1.29.5+k3s1
ubuntu-1   Ready    <none>                 80s     v1.29.5+k3s1
```

![thumb.png](/posts/k3s_thumb-png.png)
## Install CSI Driver[​](https://juicefs.com/docs/community/juicefs_on_k3s/#install-csi-driver "Direct link to heading")

It is consistent with the method of [Use JuiceFS on Kubernetes](https://juicefs.com/docs/community/how_to_use_on_kubernetes). Therefore, you can install CSI Driver through Helm or kubectl.

Here we use kubectl as an example. Execute the following command to install the CSI Driver:

```shell
kubectl apply -f https://raw.githubusercontent.com/juicedata/juicefs-csi-driver/master/deploy/k8s.yaml
```
![clipboard.png](/posts/k3s_clipboard-png.png)
### Create Storage Class[​](https://juicefs.com/docs/community/juicefs_on_k3s/#create-storage-class "Direct link to heading")

Copy and modify the following code to create a configuration file, for example: `juicefs-sc.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://juicefs.afyq4z.0001.use1.cache.amazonaws.com/3"
  storage: "s3"
  bucket: "https://juicefs-test.s3.us-east-1.amazonaws.com"
  access-key: "<your-access-key-id>"
  secret-key: "<your-access-key-secret>"
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


接下来看看资源，毕竟是一个小集群
一个主节点 一个从节点，都是1g2核心
非常的小。


```
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://10.7.20.12:6379"
  storage: "s3"
  bucket: "http://10.7.20.12:9000"
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