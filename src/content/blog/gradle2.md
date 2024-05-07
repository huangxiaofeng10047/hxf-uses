---
description: gradle 配置项目，这个是kotlin方式的
slug: gradle2
public: true
title: SpringBoot+Java17+Gradle+Docker+K8s 环境构建及一键部署
createdAt: 1715046361144
updatedAt: 1715053998525
tags: []
heroImage: /astrojs.jpg
---
使用gradle配置的项目，选择了kotlin的语言，查看一下配置文件
build.gradle.kts
```kotlin
plugins {
    java
    id("org.springframework.boot") version "3.2.5"
    id("io.spring.dependency-management") version "1.1.4"
}

group = "com.todocoder.gradle"
version = "0.0.1-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_17
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

//repositories {
//    mavenCentral()
//}
repositories {
    maven {
        setUrl("https://maven.aliyun.com/repository/public/")
    }
    maven {
        setUrl("https://maven.aliyun.com/repository/spring/")
    }
    mavenCentral()
}
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

```
使用idea构建成功后显示如下：
![clipboard.png](/posts/gradle2_clipboard-png.png)
通过调用application下的bootRun来运行项目
![clipboard2.png](/posts/gradle2_clipboard2-png.png)
调用接口测试
```shell
 curl -XGET http://127.0.0.1:8080/api/todocoder/helloword -H "Content-Type: application/json"

helloword%          
```
bootJar 可以打包运行的jar包。
接下来自定义打包命令。
```kotlin

val jarname= String.format("%s-%s.jar",project.name,version)
// 定义拷贝文件任务
val copyConfigFile by tasks.registering(Copy::class) {
    dependsOn("bootJar")
    // 清除 app 目录的历史文件
    delete("app/")
    // 从 build/libs/ 目录复制 jar 包到 app/ 目录
    from("build/libs/$jarname")
    into("app/")
    // 重命名成我们要的名字
    rename(jarname, "${project.name}.jar")
}

// 定义构建 TodoCoderJar 任务
val buildTodoCoderJar by tasks.registering {
    dependsOn("clean", copyConfigFile)
}
```
使用gradle buildTodoCOderJar
![clipboard3.png](/posts/gradle2_clipboard3-png.png)
基于Docker部署
dockerfile如下
```dockerfile
# jre 17 的镜像
FROM todocoder/jre:17
MAINTAINER todocoder
WORKDIR /todocoder
# jvm启动参数
ENV APP_ARGS="-XX:+UseG1GC -Xms1024m -Xmx1024m -Xss256k -XX:MetaspaceSize=128m"
ADD app/todocoder-gradle.jar /todocoder/app.jar
# 镜像启动后运行的脚本
ENTRYPOINT ["java","-jar","/todocoder/app.jar","${APP_ARGS}","--spring.profiles.active=dev","-c"]
```

build.sh
```shell
#!/bin/bash
# 打jar包
./gradlew buildTodoCoderJar
# 构建docker镜像
docker build -t todocoder/todocoder-gradle:v1.0.0 .
# 运行镜像
docker run --name=todocoder-gradle -d -p 8080:8080 todocoder/todocoder-gradle:v1.0.0
```
执行build.sh
![clipboard2.png](/posts/gradle2_clipboard2-png.png)
![clipboard4.png](/posts/gradle2_clipboard4-png.png)
## 基于k8s部署
采用yaml部署
```
cat <<EOF | kubectl apply -f -
# 创建命名空间
apiVersion: v1
kind: Namespace
metadata:
  name: todocoder
---
# deployment 构建
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todocoder-gradle
  namespace: todocoder
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todocoder-gradle
  template:
    metadata:
      labels:
        app: todocoder-gradle
    spec:
      containers:
        - image: todocoder/todocoder-gradle:v1.0.0
          imagePullPolicy: Always
          name: todocoder-gradle
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          resources:
            limits:
              cpu: "2"
              memory: 4Gi
            requests:
              cpu: "1"
              memory: 2Gi
---
# service
apiVersion: v1
kind: Service
metadata:
  name: todocoder-gradle
  namespace: todocoder
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      targetPort: 8080
  selector:
    app: todocoder-gradle
---
# node service
apiVersion: v1
kind: Service
metadata:
  name: todocoder-gradle-nodeport
  namespace: todocoder
spec:
  type: NodePort
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      nodePort: 38080
  selector:
    app: todocoder-gradle
EOF

```
![clipboard5.png](/posts/gradle2_clipboard5-png.png)
执行完这个报错，接下来解决这个问题，如何处理了。给k8s增加nodeport的端口
要修改 Kubernetes 中 NodePort 的端口范围，您可以按照以下步骤进行操作：

1. 找到 kube-apiserver 的配置文件。这里以 Mac 集成的 Kubernetes 为例，您需要修改 kube-apiserver 服务的配置文件。在使用 `kubeadm` 安装 Kubernetes 集群的情况下，Master 节点上会有一个文件 `/etc/kubernetes/manifests/kube-apiserver.yaml`。

2. 在 `kube-apiserver.yaml` 文件中添加 `--service-node-port-range=20000-32767`（或您自己需要的端口范围）。具体操作如下所示：

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
    - command:
        - kube-apiserver
        # 其他参数...
        - --service-node-port-range=20000-32767
      image: k8s.gcr.io/kube-apiserver:v1.13.3
      # 其他容器配置...
```

3. 保存文件并重启 kube-apiserver 服务，使更改生效。

这样，您就可以将可用的 NodePort 端口范围扩大，使其更加易用。如果您还有其他问题，请随时告知！😊

参考资料：

1. [如何更改 Kubernetes NodePort 范围 (亲测有效)](https://zhuanlan.zhihu.com/p/470647732)
2. [修改 NodePort 端口范围让 Kubernetes 更好用](https://zhuanlan.zhihu.com/p/613834350)
3. [修改 NodePort 的范围 | Kuboard](https://www.kuboard.cn/install/install-node-port-range.html)
参照解决后如下图所示即可
![clipboard5.png](/posts/gradle2_clipboard5-png.png)
部署成功后，通过k9s看到
![clipboard6.png](/posts/gradle2_clipboard6-png.png)
