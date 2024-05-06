---
description: gradle构建项目
slug: gradle
public: true
title: 使用gradle构建多项目模块
createdAt: 1714976457746
updatedAt: 1714978569865
tags: []
heroImage: /astrojs.jpg
---
## 前言
-- gradle
-- jdk17
-- idea2024
## 项目结构
```shell
 tree -L 2
.
├── build
│   └── libs
├── build.gradle
├── components
│   ├── yanx-api
│   ├── yanx-codegen
│   ├── yanx-common
│   ├── yanx-framework
│   └── yanx-security
├── doc
│   ├── docker-compose.yaml
│   ├── nacos
│   └── redis
├── gradle
│   ├── libs.versions.toml
│   └── wrapper
├── gradle.properties
├── LICENSE
├── Makefile
├── modules
│   ├── build.gradle
│   ├── yanx-auth
│   ├── yanx-monitor
│   └── yanx-system
├── readme.md
├── services
│   ├── build.gradle
│   └── yanx-boot
├── settings.gradle
├── spring.gradle
└── src
    └── main

```
## gradle wrapper包
gradle/wrapper包：Gradle 的一层包装，能够让机器在不安装 Gradle 的情况下运行程序，便于在团队开发过程中统一 Gradle 构建的版本，推荐使用。

gradlew：Gradle 命令的包装，当机器上没有安装 Gradle 时，可以直接用 gradlew 命令来构建项目。

settings.gradle：可以视为多模块项目的总目录， Gradle 通过它来构建各个模块，并组织模块间的关系。

build.gradle：管理依赖包的配置文件（相当于Maven的pom.xml）。

gradle.properties：需手动创建，配置gradle环境变量，或配置自定义变量供 build.gradle 使用。
### gradle的实践经验
gradle-wrapper.properties中gradle改为国内下载地址
![clipboard.png](/posts/gradle_clipboard-png.png)
在根目录下新建gradle.properties文件，配置gradle参数，提升构建速度
![clipboard2.png](/posts/gradle_clipboard2-png.png)
在spring.gradle配置文件，引用相关的spring依赖包
![clipboard3.png](/posts/gradle_clipboard3-png.png)
如何引用了，只需要在build.gradle中添加apply from
```
//在build.gradle里引用
apply from: "${rootDir}/spring.gradle"
```