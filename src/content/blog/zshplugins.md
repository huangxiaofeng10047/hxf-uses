---
description: 记录一下zsh-plugins.txt
slug: zshplugins
public: true
title: 记录一下zsh_plugins.txt
createdAt: 1716455831144
updatedAt: 1716456345785
tags: []
heroImage: /cover.webp
---

## 使用 antidote 来管理zsh的plugins
什么是antidote，来一段官网的解释


Antidote is a Zsh plugin manager made from the ground up thinking about performance.

It is fast because it can do things concurrently, and generates an ultra-fast static plugin file that you can easily load from your Zsh config.

It is written natively in Zsh, is well tested, and picks up where [Antibody](https://github.com/getantibody/antibody) left off.


他是从 antigen 》》 antibody 》》 antidote
这几个我都用过，感觉都还行。

```shell

# source antidote
source /usr/share/zsh-antidote/antidote.zsh
# ~/.zshrc

# Set the name of the static .zsh plugins file antidote will generate.
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins.zsh

# Ensure you have a .zsh_plugins.txt file where you can add plugins.
[[ -f ${zsh_plugins:r}.txt ]] || touch ${zsh_plugins:r}.txt
# Lazy-load antidote.
fpath+=(${ZDOTDIR:-~}/.antidote)
autoload -Uz $fpath[-1]/antidote
# Generate static file in a subshell when .zsh_plugins.txt is updated.
if [[ ! $zsh_plugins -nt ${zsh_plugins:r}.txt ]]; then
  (antidote bundle <${zsh_plugins:r}.txt >|$zsh_plugins)
fi
# Source your static plugins file.
source $zsh_plugins

```

主要看看 .zsh_plugins.txt文件
```shell
 cat .zsh_plugins.txt
# zsh plugins
ohmyzsh/ohmyzsh path:plugins/brew
ohmyzsh/ohmyzsh path:plugins/fzf
ohmyzsh/ohmyzsh path:plugins/gcloud
ohmyzsh/ohmyzsh path:plugins/git
ohmyzsh/ohmyzsh path:plugins/pyenv kind:defer
ohmyzsh/ohmyzsh path:plugins/rust
ohmyzsh/ohmyzsh path:plugins/thefuck
ohmyzsh/ohmyzsh path:plugins/volta
ohmyzsh/ohmyzsh path:plugins/vscode
ohmyzsh/ohmyzsh path:plugins/yarn

zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search

mattmc3/zephyr path:plugins/completion
# .zsh_plugins.txt

# comments are supported like this
rupa/z
zsh-users/zsh-completions

# empty lines are skipped

# annotations are also allowed:
romkatv/zsh-bench kind:path
olets/zsh-abbr    kind:defer

# frameworks like oh-my-zsh are supported
ohmyzsh/ohmyzsh path:lib
ohmyzsh/ohmyzsh path:plugins/colored-man-pages
ohmyzsh/ohmyzsh path:plugins/magic-enter

# or lighter-weight ones like zsh-utils
belak/zsh-utils path:editor
belak/zsh-utils path:history
belak/zsh-utils path:prompt
belak/zsh-utils path:utility
belak/zsh-utils path:completion

# prompts:
#   with prompt plugins, remember to add this to your .zshrc:
#   `autoload -Uz promptinit && promptinit && prompt pure`
sindresorhus/pure     kind:fpath
romkatv/powerlevel10k kind:fpath

# popular fish-like plugins
mattmc3/zfunctions
zsh-users/zsh-autosuggestions
zdharma-continuum/fast-syntax-highlighting kind:defer
zsh-users/zsh-history-substring-search
ohmyzsh/ohmyzsh path:plugins/command-not-found
ohmyzsh/ohmyzsh path:plugins/docker
# ohmyzsh/ohmyzsh path:plugins/wd
ohmyzsh/ohmyzsh path:plugins/last-working-dir
# ohmyzsh/ohmyzsh path:plugins/zsh-interactive-cd
ohmyzsh/ohmyzsh path:plugins/fzf
ohmyzsh/ohmyzsh path:plugins/compleat

ohmyzsh/ohmyzsh path:plugins/gh
ohmyzsh/ohmyzsh path:plugins/gitfast
ohmyzsh/ohmyzsh path:plugins/thefuck
ohmyzsh/ohmyzsh path:plugins/ripgrep
# ohmyzsh/ohmyzsh path:plugins/rsync
ohmyzsh/ohmyzsh path:plugins/safe-paste
ohmyzsh/ohmyzsh path:plugins/scd
# ohmyzsh/ohmyzsh path:plugins/tmux
# ohmyzsh/ohmyzsh path:plugins/tmux-cssh

mafredri/zsh-async
# zsh-users/zsh-autosuggestions
marlonrichert/zsh-autocomplete
zsh-users/zsh-history-substring-search
# zsh-users/zsh-syntax-highlighting
# z-shell/fast-syntax-highlighting
# zsh-users/zsh-completions

caarlos0/zsh-mkc
djui/alias-tips
rupa/z

# Aloxaf/fzf-tab

# should be last
sindresorhus/pure%

```

