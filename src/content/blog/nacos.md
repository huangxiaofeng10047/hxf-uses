---
description: nacos部署在k8s上
slug: nacos
public: true
title: nacos部署在k3s上
createdAt: 1719296088985
updatedAt: 1719386523788
tags: []
heroImage: /cover.webp
---

# 创建nacos2.3.2
所有服务都创建在namespace dev下

1. namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
   name: dev
   labels:
     name: dev

```
命令行为：
```shell

cat > namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
   name: dev
   labels:
     name: dev
EOF     
```

2. rbac.yaml
```yaml
cat > rbac.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: dev
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: dev
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: dev
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: dev
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF
``` 
创建nfs服务器、
![clipboard.png](/posts/nacos_clipboard-png.png)

deployment.yaml

```
cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: 10.7.20.12
            - name: NFS_PATH
              value: /home/nfs
      volumes:
        - name: nfs-client-root
          nfs:
            server: 10.7.20.12
            path: /home/nfs
EOF


```

class.yaml

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
  namespace: dev
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  pathPattern: ${.PVC.namespace}-${.PVC.name}
  archiveOnDelete: "false"
```

secret.yaml

```
cat > secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: secret
  namespace: dev
data:
  password: MTIzNDU2
EOF  
```

mysql.yaml

```
cat > mysql.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: dev
  labels:
    app: mysql
spec:
  ports:
    - port: 3306
  selector:
    app: mysql
    tier: mysql
  clusterIP: None
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  namespace: dev
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: dev
  labels:
    app: mysql
spec:
  selector:
    matchLabels:
      app: mysql
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
        tier: mysql
    spec:
      containers:
      - image: mysql:5.7
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: secret
              key: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
EOF
```

nacos-pvc-nfs.yaml

```yaml
 cat nacos-pvc-nfs.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-headless
  namespace: dev
  labels:
    app: nacos
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  ports:
    - port: 8848
      name: server
      targetPort: 8848
    - port: 9848
      name: client-rpc
      targetPort: 9848
    - port: 9849
      name: raft-rpc
      targetPort: 9849
    ## 兼容1.4.x版本的选举端口
    - port: 7848
      name: old-raft-rpc
      targetPort: 7848
  clusterIP: None
  selector:
    app: nacos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nacos-cm
  namespace: dev
data:
  mysql.service.host: "10.42.1.80"
  mysql.db.name: "nacos"
  mysql.port: "3306"
  mysql.user: "nacos"
  mysql.password: "nacos"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nacos
  namespace: dev
spec:
  serviceName: nacos-headless
  replicas: 2
  template:
    metadata:
      labels:
        app: nacos
      annotations:
        pod.alpha.kubernetes.io/initialized: "true"
    spec:
      initContainers:
        - name: peer-finder-plugin-install
          image: nacos/nacos-peer-finder-plugin:1.1
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /home/nacos/plugins/peer-finder
              name: data
              subPath: peer-finder
      containers:
        - name: nacos
          imagePullPolicy: Always
          image: nacos/nacos-server:latest
          resources:
            requests:
              memory: "2Gi"
              cpu: "500m"
          ports:
            - containerPort: 8848
              name: client-port
            - containerPort: 9848
              name: client-rpc
            - containerPort: 9849
              name: raft-rpc
            - containerPort: 7848
              name: old-raft-rpc
          env:
            - name: NACOS_AUTH_ENABLE
              value: "true"
            - name: NACOS_AUTH_TOKEN                    # token
              value: "Ym1GamIzTWdhWE1nZG1WeWVTQm5iMjlrSUhOdlpuUjNZWEpsQ2c9PQo="
            - name: NACOS_AUTH_IDENTITY_KEY             # 账号
              value: "nacos"
            - name: NACOS_AUTH_IDENTITY_VALUE   # 密码
              value: "nacos"
            - name: MODE                                                # nacos的模式，这里是单机
              value: "standalone"
            - name: NACOS_REPLICAS
              value: "2"
            - name: SERVICE_NAME
              value: "nacos-headless"
            - name: DOMAIN_NAME
              value: "cluster.local"
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
            - name: MYSQL_SERVICE_HOST
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.service.host
            - name: MYSQL_SERVICE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.db.name
            - name: MYSQL_SERVICE_PORT
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.port
            - name: MYSQL_SERVICE_USER
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.user
            - name: MYSQL_SERVICE_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.password
            - name: SPRING_DATASOURCE_PLATFORM
              value: "mysql"
            - name: MYSQL_SERVICE_DB_PARAM
              value: "characterEncoding=utf8&connectTimeout=10000&socketTimeout=30000&autoReconnect=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true"
            - name: NACOS_SERVER_PORT
              value: "8848"
            - name: NACOS_APPLICATION_PORT
              value: "8848"
            - name: PREFER_HOST_MODE
              value: "hostname"
            - name: NACOS_SERVERS
              value: "nacos-0.nacos-headless.dev.svc.cluster.local:8848 nacos-1.nacos-headless.dev.svc.cluster.local:8848"
          volumeMounts:
            - name: data
              mountPath: /home/nacos/plugins/peer-finder
              subPath: peer-finder
            - name: data
              mountPath: /home/nacos/data
              subPath: data
            - name: data
              mountPath: /home/nacos/logs
              subPath: logs
  volumeClaimTemplates:
    - metadata:
        name: data
        annotations:
          volume.beta.kubernetes.io/storage-class: "nfs-client"
      spec:
        accessModes: [ "ReadWriteMany" ]
        resources:
          requests:
            storage: 10Gi
  selector:
    matchLabels:
      app: nacos


```


ingress.yaml

```
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: dev
spec:
  ingressClassName: traefix
  rules:
  - host: nacos.dog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nacos-headless
            port:
              number: 8848
      - path: /consumer
        pathType: Prefix
        backend:
          service:
            name: spring-cloud-consumer
            port:
              number: 8080
EOF
```

![clipboard12.png](/posts/nacos_clipboard12-png.png)
nfs报错的话，就是nfs-utils 没有进行安装，ubuntu是nfs-common。

nacos部署页面

![clipboard5.png](/posts/nacos_clipboard5-png.png)
注意最新的版本限制

nacos配置登录认证密码
新版本的nacos需要自己设置参数来启动配置nacos的登录认证密码，因为默认nacos是没有账号密码可以直接登录的，这样显得不安全，而且新旧版本的配置还不一样，在官网说了：https://nacos.io/zh-cn/docs/v2/guide/user/auth.html
下面是k8s中部署nacos：2.3.1版本，启动nacos的授权登录：


![clipboard4.png](/posts/nacos_clipboard4-png.png)
