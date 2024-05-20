---
description: 使用stow来管理还原配置文件
slug: stow
public: true
title: 使用dotfiles和stow管理配置文件
createdAt: 1715910251240
updatedAt: 1715915744645
tags:
  - stow
heroImage: /cover.webp
---
# 使用Stow和dotfiles来管理配置文件

```
stow tmux

```
![clipboard.png](/posts/stow_clipboard-png.png)

# submodule vs subtree



但是我有些配置文件其实在另外一个 repo 上，这时候我怎么能跟这个 `dotfiles` repo 合到一起呢？

比如[我的 emacs 配置文件](https://github.com/jcouyang/.emacs.d)，其实是单独管理在另一 repo 的。

这时候 git 为我们提供了两种方式来管理 submodule 和 subtree。 我用的是后一种，至于 submodule 为什么不适用，网上有[大量文章](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/)解释，我就懒得翻译了。

```shell
⋊> ~/dotfiles on master ⨯ git subtree add --prefix emacs/.emacs.d git@github.com:jcouyang/.emacs.d.git master --squash
```

这行 subtree 命令把我的 emacs 配置从我的 repo 下下来作为 subtree，并 squash(合成一个) commits

这时我的 git树是这样的

```
\* commit b33c46bfebe4a28849aa967222555a4676fdb9f4 (HEAD -> master)
|\  Merge: 1b240f8 e6dacdc
| | Author: Jichao Ouyang <oyanglulu@gmail.com>
| | Date:   Thu Oct 29 21:33:06 2015 +0800
| |
| |     Merge commit 'e6dacdcd1f85cdcb3b5fa488edb7b8f31c297b3f' as 'emacs/.emacs.d'
| |
| * commit e6dacdcd1f85cdcb3b5fa488edb7b8f31c297b3f
```

可以看见把 我的 emacs repo merge 了进来，这样就跟在 `dotfiles` repo 的代码一样，该 commit 的 commit 该 push 的 push。

下面看如何 push 回我的 emacs repo。

比如我现在对 subtree emacs 做了改动并 commit 了。然后

```
git remote add emacs git@github.com:jcouyang/.emacs.d.git
git subtree push --prefix emacs/.emacs.d emacs master
```

1. 先把 emacs 的 repo 加到我的 remote 里，给个名字 emacs
2. 用 subtree push 直接 push 到 remote emacs，branch master

# ㊙ Sensitive dotfiles



有些 dotfiles 中可能涉及一些 token 或者密码，如果把他们 push 到 public 的 github 上， ~~有可能~~ 肯定会对你个人或者公司造成巨大的损失（最近公司就开始扫描个人 github 账户了🙀 好紧张）。于是我们需要对这些敏感的 dotfiles 做加密。

比如 `~/.config/hub` 里面，有我和公司的 github 的 token，我可不像这玩意被弄到 github 上。

目前最广泛使用的加密手段是 Gnupg，简称 gpg，一样使用 brew 装就好了

```shell
brew install gnupg2
```

安装完之后需要生成一个 keypair

```shell
gpg --gen-key
```

输入名字，邮箱，密码之后，就 ok 了

然后呢，我并不希望手动的每次加密完再push 到我的私有 git 上（对，即使是私有 git，安全考虑我还是需要加密，绝对不能明文存储，就是这么任性）。

那么到底去哪弄一个私有 git 呢？如果没有，dropbox 就可以，然后现在的问题是如何在 push 的时候自动的 gpg 加密。

现在 git remote crypt 大法就该登场了，到这里 <https://github.com/spwhitton/git-remote-gcrypt> 把 repo 下下来执行 `./install.sh`, 之后就应该有 `git-remote-gcrypt` 这样一个命令，先别跑

关键在于见 remote 的时候。当我在 home 目录建了一个 `dotfiles-private` 的文件夹，stow 完各种敏感 dotfiles 之后

```shell
git init
git add .
git commit -m "some private dotfiles"
git remote add dropbox gcrypt::///Users/jcouyang/Dropbox/dotfiles-private.git
git push
```

你会被问到刚才创建 gpg keypair 时输入的密码，然后…

看，两坨 gpg 加密过的文件

