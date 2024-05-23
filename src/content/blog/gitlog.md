---
description: Git clone RPC fail 92
slug: gitlog
public: true
title: Git clone RPC fail 92
createdAt: 1716427805429
updatedAt: 1716427930701
tags: []
heroImage: /cover.webp
---
## 今天在安装neovim后，报错

报错：

```shell

   lazy.nvim (H)   Install (I)   Update (U)   Sync (S)   Clean (X)   Check (C)   Log (L)   Restore (R)  
   Profile (P)   Debug (D)   Help (?) 

  Total: 58 plugins

  Failed (1)
    ○ codesnap.nvim 
        Cloning into '/home/xfhuang/.local/share/nvim/lazy/codesnap.nvim'...
        remote: Enumerating objects: 820, done.        
        remote: Counting objects: 100% (165/165), done.        
        remote: Compressing objects: 100% (76/76), done.        
        remote: Total 820 (delta 109), reused 99 (delta 87), pack-reused 655        
        Receiving objects: 100% (820/820), 157.08 KiB | 18.00 KiB/s, done.
        Resolving deltas: 100% (395/395), done.
        error: RPC failed; curl 92 HTTP/2 stream 3 was not closed cleanly: CANCEL (err 8)
        error: 6192 bytes of body are still expected
        fetch-pack: unexpected disconnect while reading sideband packet
        fatal: early EOF
        fatal: index-pack failed
        fatal: could not fetch d47f983e474f82916a52740b6a253006043c4410 from promisor remote
        warning: Clone succeeded, but checkout failed.
        You can inspect what was checked out with 'git status'
        and retry with 'git restore --source=HEAD :/'

```

解决办法：

```shell
git config --global http.postBuffer 500M
git config --global http.maxRequestBuffer 100M
git config --global core.compression 0

```