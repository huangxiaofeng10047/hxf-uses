---
description: git no response on idea
slug: idea
public: true
title: idea踩坑
createdAt: 1714372117821
updatedAt: 1714457017365
tags:
  - idea
heroImage: /blogjpg.jpeg
---
今天在idea上打开wsl2中的java项目，报错了，git。
```
Cannot identify version of git executable no response on start up
```
![clipboard.png](/posts/idea_clipboard-png.png)

解决办法是关闭调registry中的配置，打开find action，输入“registry"
超找![clipboard.png](/posts/idea_clipboard-png.png)
注意这个wsl.use.remote.agent.for.launch.processes.去掉勾选即可。目前看是因为在wsl2的mirrored模式下，网络以及发现git都会存在问题。

现在发现idea无法运行，
报错 
```
Traceback (most recent call last):
  File "/usr/sbin/autojump", line 39, in <module>
    from autojump_argparse import ArgumentParser
ModuleNotFoundError: No module named 'autojump_argparse'
错误: 找不到或无法加载主类 org.jetbrains.jps.cmdline.Launcher
原因: java.lang.ClassNotFoundException: org.jetbrains.jps.cmdline.Launcher
```
这个原因依然无法解决。