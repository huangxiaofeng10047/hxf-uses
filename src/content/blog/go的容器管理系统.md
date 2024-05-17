---
description: 学习容器管理系统
slug: go的容器管理系统
public: true
title: 学习掘金的容器管理系统
createdAt: 1715566956963
updatedAt: 1715840691741
tags:
  - go
  - gin
heroImage: /blog.jpg
---

## 第一步使用gin开始开发项目

```shell
mkdir -p godemo
cd godemo
go mod init godemo

```
可以看见go.mod 创建
 安装gin
 ```shell
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
 
 
 ```go
 
 ```
 
 ## 中间件 Middleware
 
 全局中间件
 
 ```go
package main

import (
    "fmt"
		"time"
    "github.com/gin-gonic/gin"
)

// 定义中间件
func MiddleWare() gin.HandlerFunc {
    return func(c *gin.Context) {
        t := time.Now()
        fmt.Println("中间件开始执行了")
        // 设置变量到Context的key中，可以通过Get()取
        c.Set("request", "中间件")
        status := c.Writer.Status()
        fmt.Println("中间件执行完毕", status)
        t2 := time.Since(t)
        fmt.Println("time:", t2)
    }
}

func main() {
    // 1.创建路由
    // 默认使用了2个中间件Logger(), Recovery()
    r := gin.Default()
    // 注册中间件，全局中间件用.Use注册
    r.Use(MiddleWare())
    // {}为了代码规范
    {
        r.GET("/ce", func(c *gin.Context) {
            // 取值
            req, _ := c.Get("request")
            fmt.Println("request:", req)
            // 页面接收
            c.JSON(200, gin.H{"request": req})
        })

    }
    r.Run()
}


```

## 局部中间件

```go

package main

import (
    "fmt"
    "time"
    "github.com/gin-gonic/gin"
)

// 定义中间件
func MiddleWare() gin.HandlerFunc {
    return func(c *gin.Context) {
        t := time.Now()
        fmt.Println("中间件开始执行了")
        // 设置变量到Context的key中，可以通过Get()取
        c.Set("request", "中间件")
        // 执行函数
        c.Next()
        // 中间件执行完后续的一些事情
        status := c.Writer.Status()
        fmt.Println("中间件执行完毕", status)
        t2 := time.Since(t)
        fmt.Println("time:", t2)
    }
}

func main() {
    // 1.创建路由
    // 默认使用了2个中间件Logger(), Recovery()
    r := gin.Default()
    //局部中间键使用
    r.GET("/ce", MiddleWare(), func(c *gin.Context) {
        // 取值
        req, _ := c.Get("request")
        fmt.Println("request:", req)
        // 页面接收
        c.JSON(200, gin.H{"request": req})
    })
    r.Run()
}



```

 在gin框架中，可以为每个路由添加任意数量的中间件，可以跨中间件取值。  

## 请求拦截

1、前置拦截
毫无疑问，对于中间件来说，请求拦截是最重要的作用，如果你和我一样之前是写前端的，可以自己代入一下 vue-router 中的路由守卫的作用。
那如果我们认为用户的请求有问题，不想让他进行下一步操作的时候我们可以怎么做呢？
这时候，gin的Abort系列函数就能帮助我们做到这件事了，注意，错误处理请求返回要使用c.Abort，不要只是return哦

```go
func (c *Context) Abort()
func (c *Context) AbortWithStatus(code int)
func (c *Context) AbortWithStatusJSON(code int, jsonObj interface{})
func (c *Context) AbortWithError(code int, err error)
```
Abort()
Abort 在被调用的函数中阻止挂起函数。注意这将不会停止当前的函数，所以还得配合 return 食用。例如，你有一个验证当前的请求是否是认证过的 Authorization 中间件。如果验证失败(例如，密码不匹配)，调用 Abort 以确保这个请求的其他函数不会被调用。
使用Abort() 中断请求之后会直接返回200，但响应的body中不会有数据。
AbortWithStatusJSON()
使用AbortWithStatusJSON()方法，中断用户请求后，则可以返回json格式的数据
2、后置拦截
gin.Context的Next()方法，可以请求到达并完成业务处理后，再经过中间件后置拦截处理
例如：

```go
func Middleware1(c *gin.Context){
		fmt.Println("1 开始")
	  //c.Next()会跳过当前中间件后续的逻辑，类似defer，最后再执行c.Next后面的逻辑
		//多个c.Next()谁在前面谁后执行，跟defer很像，类似先进后出的栈
    c.Next()
    fmt.Println("1 结束")
}

func Middleware2(c *gin.Context){
		fmt.Println("2 开始")
    c.Next()
    fmt.Println("2 结束")
}

r.Use(Middleware1, Middleware2)
r.GET("/", func(c *gin.Context) {
		c.Next()
		fmt.Println("处理方法执行")
	})

```

会输出
1 开始
2 开始
处理方法执行
2 结束
1 结束

调用 Next() 之后会执行下一个中间件的操作或自定义的处理方法，简单来说可以理解为继续执行下一个的意思。
(5) 定义项目中的全局中间件


在根目录下新建一个文件夹 middleware ,然后在下面再新建一个global 来存放我们定义好的全局中间件，新建一个custom来存放我们的局部中间件


在global下新建一个示例中间件文件夹 auth ，并在文件夹中新建 auth.go

```go
#/middleware/global/auth/auth.go

package AuthMiddleware
import (
	"github.com/gin-gonic/gin"
)
// 用户校验
func UserAuth() gin.HandlerFunc {
	//自定义逻辑
	//返回中间件
	return func(c *gin.Context) {
		//中间件逻辑
	}
}
```


在main.go中引入该中间件并使用

```go 
package main

import (
	"fmt"
	"go-server-template/middleware/global/auth"
	"go-server-template/routers"
)

func main() {
	r := routers.InitRouter()
	r.Use(authMiddleware.UserAuth())
	err := r.Run(":8080")
	if err != nil {
		fmt.Println("服务器启动失败！")
	}
}
```

# 参考文档：

[容器管理系统](https://juejin.cn/post/7011711744359792654)
[gin](https://www.topgoer.com/gin%E6%A1%86%E6%9E%B6/gin%E4%B8%AD%E9%97%B4%E4%BB%B6/%E5%85%A8%E5%B1%80%E4%B8%AD%E9%97%B4%E4%BB%B6.html)
