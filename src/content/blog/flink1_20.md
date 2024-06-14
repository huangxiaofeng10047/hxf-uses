---
description: flink的源码编译
slug: flink1_20
public: true
title: flink的1.20编译
createdAt: 1718253935987
updatedAt: 1718266749556
tags: []
heroImage: /cover.webp
---

## jdk17 flink编译

安装json-smart

```shell
 mvn install:install-file -DgroupId=net.minidev -DartifactId=json-smart -Dversion=2.3 -Dpackaging=jar -Dfile=json-smart-2.3.jar

```

安装kafka-schema-registry-client
```shell
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=7.5.3 -Dpackaging=jar -Dfile=kafka-schema-registry-client-7.5.3.jar -DpomFile=kafka-schema-registry-client-7.5.3.pom

mvn install:install-file -DgroupId=io.confluent -DartifactId=rest-utils-parent -Dversion=7.5.3 -Dpackaging=pom -Dfile=rest-utils-parent-7.5.3.pom -DpomFile=rest-utils-parent-7.5.3.pom


mvn install:install-file -DgroupId=io.confluent -DartifactId=common -Dversion=7.5.3 -Dpackaging=pom -Dfile=common-7.5.3.pom -DpomFile=common-7.5.3.pom

mvn install:install-file -DgroupId=io.confluent -DartifactId=common-parent -Dversion=7.5.3 -Dpackaging=pom -Dfile=common-parent-7.5.3.pom -DpomFile=common-parent-7.5.3.pom
```
报错
 Could not resolve dependencies for project org.apache.flink:flink-avro-confluent-registry:jar:1.20-SNAPSHOT: The following artifacts could not be resolved: org.apache.kafka:kafka-clients:jar:7.5.3-ccs, io.confluent:common-utils:jar:7.5.3: Could not find artifact org.apache.kafka:kafka-clients:jar:7.5.3-ccs in maven-public (http://10.7.20.39:8081/repository/maven-public/)
 安装这个jar包
 ```shell
 
 mvn install:install-file -DgroupId=org.apache.kafka -DartifactId=kafka-clients -Dversion=7.5.3-ccs -Dpackaging=jar -Dfile=kafka-clients-7.5.3-ccs.jar -DpomFile=kafka-clients-7.5.3-ccs.pom
 
 
 
  mvn install:install-file -DgroupId=io.confluent -DartifactId=common-utils -Dversion=7.5.3 -Dpackaging=jar  -Dfile=/mnt/d/Users/Administrator/Downloads/common-utils-7.5.3.jar

```

编译命令为：
  mvn clean package  -DskipTests  -T 20  -DskipTests  -Dfast -Dmaven.compile.fork=true   -Pjava17-target

![clipboard.png](/posts/flink1_20_clipboard-png.png)
编译开始后，cpu占比超过百分之百，真猛。
![clipboard2.png](/posts/flink1_20_clipboard2-png.png)
花费14分钟构建。构建时间真长啊。
接下来把代码导入到idea中
使用jdk21 来进行idea导入
![clipboard3.png](/posts/flink1_20_clipboard3-png.png)
