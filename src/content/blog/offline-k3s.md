---
description: 离线部署k3s
slug: offline-k3s
public: true
title: 离线部署k3s
createdAt: 1719471021602
updatedAt: 1719473497110
tags: []
heroImage: /cover.webp
---

安装registry

```
docker run -d -p 5000:5000 --name registry registry:2
0769aef593041f0dc19feef9590b8147dc9cd3abd537e1e7448c74c9cea4a19d
#检验一下
 curl 127.0.0.1:5000/v2/_catalog
{"repositories":[]}

```

上传镜像到registry中

```
docker pull docker.io/rancher/klipper-helm:v0.8.4-build20240523
docker pull docker.io/rancher/klipper-lb:v0.4.7
docker pull docker.io/rancher/local-path-provisioner:v0.0.27
docker pull docker.io/rancher/mirrored-coredns-coredns:1.10.1
docker pull docker.io/rancher/mirrored-library-busybox:1.36.1
docker pull docker.io/rancher/mirrored-library-traefik:2.10.7
docker pull docker.io/rancher/mirrored-metrics-server:v0.7.0
docker pull docker.io/rancher/mirrored-pause:3.6



docker tag docker.io/rancher/klipper-helm:v0.8.4-build20240523 10.7.20.12:5000/klipper-helm
docker tag docker.io/rancher/klipper-lb:v0.4.7 10.7.20.12:5000/klipper-lb
docker tag docker.io/rancher/local-path-provisioner:v0.0.27 10.7.20.12:5000/local-path-provisioner
docker tag docker.io/rancher/mirrored-coredns-coredns:1.10.1 10.7.20.12:5000/mirrored-coredns-coredns
docker tag docker.io/rancher/mirrored-library-busybox:1.36.1 10.7.20.12:5000/mirrored-library-busybox
docker tag docker.io/rancher/mirrored-library-traefik:2.10.7 10.7.20.12:5000/mirrored-library-traefik
docker tag docker.io/rancher/mirrored-metrics-server:v0.7.0 10.7.20.12:5000/mirrored-metrics-server
docker tag  docker.io/rancher/mirrored-pause:3.6 10.7.20.12:5000/mirrored-pause


docker push 10.7.20.12:5000/klipper-helm
docker push 10.7.20.12:5000/klipper-lb
docker push 10.7.20.12:5000/local-path-provisioner
docker push 10.7.20.12:5000/mirrored-coredns-coredns
docker push 10.7.20.12:5000/mirrored-library-busybox
docker push 10.7.20.12:5000/mirrored-library-traefik
docker push 10.7.20.12:5000/mirrored-metrics-server
docker push 10.7.20.12:5000/mirrored-pause



```

接下来下载k3s和install.sh

安装命令如下：

```
xfhuang@ubuntu-m1:~$ sudo INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh
[INFO]  Skipping k3s download and verify
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  Host iptables-save/iptables-restore tools not found
[INFO]  Host ip6tables-save/ip6tables-restore tools not found
[INFO]  systemd: Starting k3s


```


安装node

```

xfhuang@ubuntu-m1:~$ sudo cat /var/lib/rancher/k3s/server/node-token
K109b6f5284cb64f3bbd421992b7ef44f37e4888f33ea22438b6e0366e23024ec78::server:c0038051d3ff44eaa01d4e5f903dfe99


INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://10.7.10.17:6443 K3S_TOKEN=K109b6f5284cb64f3bbd421992b7ef44f37e4888f33ea22438b6e0366e23024ec78::server:c0038051d3ff44eaa01d4e5f903dfe99 ./install.sh
输出如下信息
[INFO]  Skipping k3s download and verify
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  Host iptables-save/iptables-restore tools not found
[INFO]  Host ip6tables-save/ip6tables-restore tools not found
[INFO]  systemd: Starting k3s-agent

```

去主节点看一下，是否过来了

![clipboard.png](/posts/offline-k3s_clipboard-png.png)
创建juicefs storageClass

```

juicefs format \
    --storage minio \
    --bucket http://10.7.20.12:9000/juicefs \
    --access-key Go3gWx4MvGz5EHvikJDA \
    --secret-key w9PcSjSnJYKhvl6aIFqVQFsFMhmEeNo3TFlGHQ4h \
    redis://:xj2023@10.7.20.12:6379/2 \
    myjfs2

```

创建storageclass

```
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://:xj2023@10.7.20.12:6379/2"
  storage: "s3"
  bucket: "http://10.7.20.12:9000/juicefs"
  access-key: "Go3gWx4MvGz5EHvikJDA"
  secret-key: "w9PcSjSnJYKhvl6aIFqVQFsFMhmEeNo3TFlGHQ4h"
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

创建一个nginx试试

```
cat > service.yaml << EOF
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
EOF
```

deployment

```
cat > deployment.yaml << EOF
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
EOF
```

ingress.yaml

```
cat > ingress.yaml << EOF
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
EOF                  

```

使用skopeo来进行镜像的同步

另外导入镜像是通过，上传tar包到/var/lib/rancher/k3s/agent/images/这个目录中，重启k3s即可。
