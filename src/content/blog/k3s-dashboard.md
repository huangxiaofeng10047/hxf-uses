---
description: k3s上安装kubernetes-dashboard
slug: k3s-dashboard
public: true
title: k3s上安装kubernetes仪表盘
createdAt: 1719372128789
updatedAt: 1719391289815
tags: []
heroImage: /cover.webp
---

## 部署 Kubernetes 仪表盘[#](https://docs.rancher.cn/docs/k3s/installation/kube-dashboard/_index/#%E9%83%A8%E7%BD%B2-kubernetes-%E4%BB%AA%E8%A1%A8%E7%9B%98 "Direct link to heading")

```shell
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
sudo k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yam

```

## 仪表盘 RBAC 配置[#](https://docs.rancher.cn/docs/k3s/installation/kube-dashboard/_index/#%E4%BB%AA%E8%A1%A8%E7%9B%98-rbac-%E9%85%8D%E7%BD%AE "Direct link to heading")

dashboard.admin-user.yml
```yaml
cat > dashboard.admin-user.yml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```


不行的，用户helm来部署吧

```
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

```



![clipboard.png](/posts/k3s-dashboard_clipboard-png.png)

登录界面为

![clipboard2.png](/posts/k3s-dashboard_clipboard2-png.png)
创建 serviceAccount
```
kubectl -n kubernetes-dashboard create serviceaccount admin-user

```

给sa绑定集团

```cat <<EOF  |  kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

```
3 获取bearer token

```

kubectl -n kubernetes-dashboard create token admin-user
```

获取到token

![clipboard3.png](/posts/k3s-dashboard_clipboard3-png.png)
修改界面为Nodeport进行访问

![clipboard4.png](/posts/k3s-dashboard_clipboard4-png.png)
获取如下的界面。

参考文档：

[创建dashboard的访问](https://www.kerno.io/learn/kubernetes-dashboard-deploy-visualize-cluster)


但是通过traefik来访问dashboard就报错了，这是什么原因，这是因为kong-proxy和traefik冲突了，解决办法如下

![clipboard101.png](/posts/k3s-dashboard_clipboard101-png.png)

a Traefik ServersTransport resource
```
 cat serverTransport.yaml
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: skipverify
  namespace: kubernetes-dashboard
spec:
  insecureSkipVerify: true

```
修改dashboard-ingress.yaml

```
 cat ingress-dashboard.yaml
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
        - name: kubernetes-dashboard-kong-proxy
          port: 443
          serversTransport: skipverify
  tls:
    secretName: dashboard-tls

```

再点击提交，就可以正常访问页面了。

![clipboard5.png](/posts/k3s-dashboard_clipboard5-png.png)

上面的方式会创建临时的token ，如何创建长期token,注意这里需要用kube-system下的admin-user



```
cat > dashboard-user.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF
 
kubectl  apply -f dashboard-user.yaml
 
# 创建token
kubectl -n kube-system create token admin-user
 
eyJhbGciOiJSUzI1NiIsImtpZCI6Im5vZExpNi1tTERLb09ONVM2cEE0SWNCUnA4eTZieE81RnVGb1IwSk5QVFEifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzA4MjQ4NjM4LCJpYXQiOjE3MDgyNDUwMzgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiMTQ1YTdmZTktMTQ0YS00NDZmLWI1M2QtNDk4OGM3YjIyZjgyIn19LCJuYmYiOjE3MDgyNDUwMzgsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphZG1pbi11c2VyIn0.H2Oxxrb5BVLH1iDOA-Uo1I7aiAUZX1wK-xBiV9NJXQ32EDyQvss95yQbCNHtPMhQZ8jFE3NRhyjkgZMZmX7kR9J-89QXLqKhE8Qnihd1mq5HOEVQ8tjZ6ix8ymxs5QkfSvd_OUzILKBtfYAMb4Fer67Dyf14oBHWVKU9LQkCdtFaLxerK--N7gLWeGXzavqzOlEPZR5UZWUPwP5dJmAQtvSToPVMaKiA49LjaGJid0F5Pxnutr80oZRsLfKr0MpoEG6jrow1QeJ2PgVksDTcqMTpye-M6jmIbuxabsRSskTT_zEDT0J86BiLYIHnh79D-P7IUUq6GOp8DgG-wXhICQ


cat > dashboard-user-token.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF
 
kubectl  apply -f dashboard-user-token.yaml
 
# 查看密码
kubectl get secret admin-user -n kube-system -o jsonpath={".data.token"} | base64 -d

eyJhbGciOiJSUzI1NiIsImtpZCI6Ilp0dmNzenhMRmFQMTUxOU1hNVFoQ2RyS0ZFNWV2YjEtbFFwRjNVLVlQR2cifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI1Y2EyZWM2Yi02NjJiLTRjYTgtODNiMS1mZDViODUyYzEyYzAiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.dAln0so1zQrRhaPQga60LotrLdQueNoLGxVo0Zk_hRgRC8X0CZQ2r6lXDSLMxTh7BnxnGYm28H5SnDiMdIOJVb3p5N7jQKtlYOvqoQ1jmDMQ14quekjpuqnQbd_xCs9uHOsPkxYn38nOB9oI0fode0tF0R2jS1fXY4d9BKu3yq6THJQfNXPBD0FeI10VvAkwPLs_hsnwZBZ94KxCb10rPRcUzGqVfA_yify0R_9eIL5ZciaAIL2UoG2zxUET4v4Xc3MWgyP6MreBZtbDOwRUh9hC864HcUFPHkZpH7Vm2ZY2q5LW0NJVtaU6M7Ku_gTiuGnVxh0Tgsjth2c_l61dkg%


```
登录成功，


参考文档：
https://blog.csdn.net/qq_33921750/article/details/136668014