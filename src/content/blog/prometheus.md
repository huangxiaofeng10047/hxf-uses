---
description: 使用prometheus监控k3s
slug: prometheus
public: true
title: 使用prometheus监控k3s
createdAt: 1719067555251
updatedAt: 1719131305704
tags: []
heroImage: /cover.webp
---

安装prometheus
```

 wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
 
 tar -xvf  helm-v3.12.0-linux-amd64.tar.gz
 

sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo helm install my-kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 55.5.1



Author: Koufuchi
Link: https://koufuchi.com/Kubernetes/PrometheusGrafanaK3s/index.html
Source: Koufuchi's blog
Copyright is owned by the author. For commercial reprints, please contact the author for authorization. For non-commercial reprints, please indicate the source.

```

暴露一下服务

```
openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 3650 -out tls.crt

如果服务在多个ns,需要多个ns中创建secret
kubectl create secret generic dashboard-tls --from-file=tls.crt --from-file=tls.key -n kube-system


```

安装dashboard

```

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
"kubernetes-dashboard" has been added to your repositories
root@k-m1:~/k3s-dashboard# helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
Release "kubernetes-dashboard" does not exist. Installing it now.
```

接下来暴露服务
ingress.yaml

```yaml
root@k-m1:~# cat ingress.yaml
#创建对应的 IngressRoute
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
  - websecure
  tls:
    secretName: dashboard-tls
  routes:
  - match: Host(`traefik.cluster.local`)  #匹配的域名
    kind: Rule
    services:
    - name: api@internal      #traefik内置服务
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: mytransport
  namespace: kubernetes-dashboard
spec:
  serverName: "dashboard.cluster.local"
  insecureSkipVerify: true
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: dashboard-k8s
  namespace: kubernetes-dashboard
spec:
  entryPoints:
    - websecure
  routes:
    - match: "Host(`dashboard.cluster.local`)"
      kind: Rule
      services:
      - name: kubernetes-dashboard  #绑定的后端service
        port: 443
        serversTransport: mytransport
  tls:
    secretName: dashboard-tls
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: prometheus-grafana
spec:
  entryPoints:
  - websecure
  tls:
    secretName: dashboard-tls
  routes:
  - match: Host(`grafana.cluster.local`)
    kind: Rule
    services:
    - name:  my-kube-prometheus-stack-grafana
      port: 80

```

对应的就应该暴露服务的hosts修改
![clipboard.png](/posts/prometheus_clipboard-png.png)
下面访问一下网页看看

![clipboard2.png](/posts/prometheus_clipboard2-png.png)
注意登陆的时候的密码获取
获取用户名

root@k-m1:~# kubectl get secret my-kube-prometheus-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode
admin
可以看到密码就是admin
获取密码如下

root@k-m1:~# kubectl get secret my-kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
prom-operatorroot@k-m1:~#

键盘蓝牙配对成功了。