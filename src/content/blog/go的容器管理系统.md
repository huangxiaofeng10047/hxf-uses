---
description: 学习容器管理系统
slug: go的容器管理系统
public: true
title: 学习掘金的容器管理系统
createdAt: 1715566956963
updatedAt: 1715571408699
tags: []
heroImage: /blogjpg.jpeg
---
## 第一步使用gin开始开发项目
```
mkdir -p godemo
cd godemo
go mod init godemo

```
可以看见go.mod 创建
 安装gin
 ```
 go get -u github.com/gin-gonic/gin

 ```
 输出如下
 ![clipboard.png](/posts/go的容器管理系统_clipboard-png.png)
 创建入口的main.go
 ![clipboard2.png](/posts/go的容器管理系统_clipboard2-png.png)
 看到这个，证明服务器正常启动。
 添加路由看看
 ![clipboard4.png](/posts/go的容器管理系统_clipboard4-png.png)
 
 ## 路由分组
 ```
 
 ```