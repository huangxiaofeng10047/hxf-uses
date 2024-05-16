---
description: neovim
slug: nvim
public: true
title: nvim
createdAt: 1714207270032
updatedAt: 1714231856593
tags:
  - nvim
heroImage: /blog.jpg
---

首先我们需要时用lazyvim来进行vim的设置，为什么采用lazynvim时因为lazynvim为我们准备了很多有用的插件配置，可以方便我们去使用。

![截屏2024-04-27 16.47.13.png](/posts/nvim_2024-04-27-16-47-13-png.png)

macos第一次用截图，shit+command+4 ，记住了。
设置LazyVim
首先备份一下你现在neovim文件。
```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
```
这样修改后时一个原始的nvim：
![截屏2024-04-27 17.14.09.png](/posts/nvim_2024-04-27-17-14-09-png.png)

# 安装需要的工具
```
brew install ripgrep fd
```
同步lazyvim的starter
```
git clone https://github.com/LazyVim/starter ~/.config/nvim
cd nvim
```
删除.git文件夹
```
rm -rf .git
```

启动nvim
```
nvim
```
![截屏2024-04-27 20.15.34.png](/posts/nvim_2024-04-27-20-15-34-png.png)
