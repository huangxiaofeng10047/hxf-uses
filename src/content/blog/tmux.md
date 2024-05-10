---
description: tmux 配置
slug: tmux
public: true
title: tmux配置
createdAt: 1715332789180
updatedAt: 1715333027049
tags: []
heroImage: /astrojs.jpg
---

.tmux.conf.local
```
# : << EOF
# https://github.com/gpakosz/.tmux
# (‑●‑●)> dual licensed under the WTFPL v2 license and the MIT license,
#         without any warranty.
#         Copyright 2012— Gregory Pakosz (@gpakosz).


# -- navigation ----------------------------------------------------------------

# if you're running tmux within iTerm2
#   - and tmux is 1.9 or 1.9a
#   - and iTerm2 is configured to let option key act as +Esc
#   - and iTerm2 is configured to send [1;9A -> [1;9D for option + arrow keys
# then uncomment the following line to make Meta + arrow keys mapping work
#set -ga terminal-overrides "*:kUP3=\e[1;9A,*:kDN3=\e[1;9B,*:kRIT3=\e[1;9C,*:kLFT3=\e[1;9D"

# -- plugins -------------------------------------------------------------------
# /!\ the tpm bindings differ slightly from upstream:
#   - installing plugins: <prefix> + I
#   - uninstalling plugins: <prefix> + Alt + u
#   - updating plugins: <prefix> + u
set -g status-position top
# /!\ do not add set -g @plugin 'tmux-plugins/tpm'
# /!\ do not add run '~/.tmux/plugins/tpm/tpm'

# to enable a plugin, use the 'set -g @plugin' syntax:
# visit https://github.com/tmux-plugins for available plugins
#set -g @plugin 'tmux-plugins/tmux-cpu'
#set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
 set -g @plugin 'tmux-plugins/tpm'
 set -g @plugin 'tmux-plugins/tmux-yank'
 set -g @plugin 'tmux-plugins/tmux-copycat'
 set -g @plugin 'tmux-plugins/tmux-open'
 set -g @plugin 'tmux-plugins/tmux-sensible'
 set -g @catppuccin_flavour 'latte'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '30'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-save-shell-history 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @plugin 'catppuccin/tmux'
# ...alongside
set -g @plugin 'tmux-plugins/tpm'
# 定义变量
color_red="#ff0000" #定义一个红色`
# -- something -----------------------------------------------------------------
set -g @catppuccin_window_left_separator ""
set -g @catppuccin_window_right_separator " "
set -g @catppuccin_window_middle_separator " █"
set -g @catppuccin_window_number_position "right"

set -g @catppuccin_window_default_fill "number"
set -g @catppuccin_window_default_text "#W"

set -g @catppuccin_window_current_fill "number"
set -g @catppuccin_window_current_text "#W"

set -g @catppuccin_status_modules_right "directory user host session"
set -g @catppuccin_status_left_separator  " "
set -g @catppuccin_status_right_separator ""
set -g @catppuccin_status_fill "icon"
set -g @catppuccin_status_connect_separator "no"

set -g @catppuccin_directory_text "#{pane_current_path}"
# 状态栏实时更新
set -g status-interval 1
# 鼠标
set -g mouse on
# vim 风格
set -g status-keys vi
set -g mode-keys vi

# -- windows & pane creation ---------------------------------------------------

# new window retains current path, possible values are:
#   - true
#   - false (default)
tmux_conf_new_window_retain_current_path=false

# new pane retains current path, possible values are:
#   - true (default)
#   - false
tmux_conf_new_pane_retain_current_path=true

# new pane tries to reconnect ssh sessions (experimental), possible values are:
#   - true
#   - false (default)
tmux_conf_new_pane_reconnect_ssh=false

# prompt for session name when creating a new session, possible values are:
#   - true
#   - false (default)
tmux_conf_new_session_prompt=false


# -- display -------------------------------------------------------------------

# RGB 24-bit colour support (tmux >= 2.2), possible values are:
#  - true
#  - false (default)
tmux_conf_24b_colour=true

# default theme
tmux_conf_theme_colour_1="#080808"    # dark gray
tmux_conf_theme_colour_2="#303030"    # gray
tmux_conf_theme_colour_3="#8a8a8a"    # light gray
tmux_conf_theme_colour_4="#00afff"    # light blue
tmux_conf_theme_colour_5="#f1fa8c"    # yellow

# window style
tmux_conf_theme_window_fg="default"
tmux_conf_theme_window_bg="default"

# highlight focused pane (tmux >= 2.1), possible values are:
#   - true
#   - false (default)
tmux_conf_theme_highlight_focused_pane=false

# focused pane colours:
tmux_conf_theme_focused_pane_bg="$tmux_conf_theme_colour_2"

# pane border style, possible values are:
#   - thin (default)
#   - fat
tmux_conf_theme_pane_border_style=thin

# pane borders colours:
tmux_conf_theme_pane_border="$tmux_conf_theme_colour_2"
tmux_conf_theme_pane_active_border="$tmux_conf_theme_colour_4"

# pane indicator colours (when you hit <prefix> + q)
tmux_conf_theme_pane_indicator="$tmux_conf_theme_colour_4"
tmux_conf_theme_pane_active_indicator="$tmux_conf_theme_colour_4"

# status line style
tmux_conf_theme_message_fg="$tmux_conf_theme_colour_1"
tmux_conf_theme_message_bg="$tmux_conf_theme_colour_5"
tmux_conf_theme_message_attr="bold"

# status line command style (<prefix> : Escape)
tmux_conf_theme_message_command_fg="$tmux_conf_theme_colour_5"
tmux_conf_theme_message_command_bg="$tmux_conf_theme_colour_1"
tmux_conf_theme_message_command_attr="bold"

# window modes style
tmux_conf_theme_mode_fg="$tmux_conf_theme_colour_1"
tmux_conf_theme_mode_bg="$tmux_conf_theme_colour_5"
tmux_conf_theme_mode_attr="bold"

# 状态栏底栏
tmux_conf_theme_status_fg_colour="#8a8a8a"
tmux_conf_theme_status_bg_colour="#4e4e4e"
tmux_conf_theme_status_fg="$tmux_conf_theme_status_fg_colour"
tmux_conf_theme_status_bg="$tmux_conf_theme_status_bg_colour"
tmux_conf_theme_status_attr="none"

# terminal title
#   - built-in variables are:
#     - #{circled_window_index}
#     - #{circled_session_name}
#     - #{hostname}
#     - #{hostname_ssh}
#     - #{hostname_full}
#     - #{hostname_full_ssh}
#     - #{username}
#     - #{username_ssh}
tmux_conf_theme_terminal_title="#h ❐ #S ● #I #W"

# window status style
#   - built-in variables are:
#     - #{circled_window_index}
#     - #{circled_session_name}
#     - #{hostname}
#     - #{hostname_ssh}
#     - #{hostname_full}
#     - #{hostname_full_ssh}
#     - #{username}
#     - #{username_ssh}
tmux_conf_theme_window_status_fg_colour="#282a36"
tmux_conf_theme_window_status_bg_colour="#6272a4"
tmux_conf_theme_window_status_fg="$tmux_conf_theme_window_status_fg_colour"
tmux_conf_theme_window_status_bg="$tmux_conf_theme_window_status_bg_colour"
tmux_conf_theme_window_status_attr="none"
#tmux_conf_theme_window_status_format="#I #W"
#tmux_conf_theme_window_status_format="#{circled_window_index} #W"
tmux_conf_theme_window_status_format="#I #W#{?window_bell_flag, ,}#{?window_zoomed_flag, ,}"

# 当前窗口
#   - built-in variables are:
#     - #{circled_window_index}    窗口编号->① ②
#     - #{circled_session_name}
#     - #{hostname}
#     - #{hostname_ssh}
#     - #{hostname_full}
#     - #{hostname_full_ssh}
#     - #{username}
#     - #{username_ssh}
tmux_conf_theme_window_status_current_fg_colour="#282a36"
tmux_conf_theme_window_status_current_bg_colour="#ff0000"
tmux_conf_theme_window_status_current_fg="$tmux_conf_theme_window_status_current_fg_colour"
tmux_conf_theme_window_status_current_bg="$tmux_conf_theme_window_status_current_bg_colour"
tmux_conf_theme_window_status_current_attr="bold"
tmux_conf_theme_window_status_current_format=' #W '
#tmux_conf_theme_window_status_current_format='#{circled_window_index} #W'
#tmux_conf_theme_window_status_current_format="#{circled_window_index} #W"
#tmux_conf_theme_window_status_current_format=" #I #W#{?window_zoomed_flag, ,}"

# window activity status style
tmux_conf_theme_window_status_activity_fg="default"
tmux_conf_theme_window_status_activity_bg="default"
tmux_conf_theme_window_status_activity_attr="underscore"

# window bell status style
tmux_conf_theme_window_status_bell_fg="$tmux_conf_theme_colour_5"
tmux_conf_theme_window_status_bell_bg="default"
tmux_conf_theme_window_status_bell_attr="blink,bold"

# 非当前窗口
tmux_conf_theme_window_status_last_fg_colour="#282a36"
tmux_conf_theme_window_status_last_bg_colour="#6272a4"
tmux_conf_theme_window_status_last_fg="$tmux_conf_theme_window_status_last_fg_colour"
tmux_conf_theme_window_status_last_bg="$tmux_conf_theme_window_status_last_bg_colour"
tmux_conf_theme_window_status_last_attr="none"

# status left/right sections separators
#tmux_conf_theme_left_separator_main=""
#tmux_conf_theme_left_separator_sub="|"
#tmux_conf_theme_right_separator_main=""
#tmux_conf_theme_right_separator_sub="|"
tmux_conf_theme_left_separator_main='\uE0B0'  # /!\ you don't need to install Powerline
tmux_conf_theme_left_separator_sub='\uE0B1'   #   you only need fonts patched with
tmux_conf_theme_right_separator_main='\uE0B2' #   Powerline symbols or the standalone
tmux_conf_theme_right_separator_sub='\uE0B3'  #   PowerlineSymbols.otf font, see README.md

# status left/right content:
#   - separate main sections with "|"
#   - separate subsections with ","
#   - built-in variables are:
#     - #{battery_bar}             电池剩余进度条
#     - #{battery_hbar}
#     - #{battery_percentage}      电池剩余百分比
#     - #{battery_status}          电池状态 充电/未充电
#     - #{battery_vbar}
#     - #{circled_session_name}    会话名
#     - #{hostname_ssh}
#     - #{hostname}
#     - #{hostname_full}
#     - #{hostname_full_ssh}
#     - #{loadavg}
#     - #{mouse}
#     - #{pairing}
#     - #{prefix}
#     - #{root}
#     - #{synchronized}
#     - #{uptime_y}
#     - #{uptime_d} (modulo 365 when #{uptime_y} is used)
#     - #{uptime_h}
#     - #{uptime_m}
#     - #{uptime_s}
#     - #{username}
#     - #{username_ssh}
# 会话/启动时间
tmux_conf_theme_status_left="  #{username}#{root} |  #S "
#tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} ,  %b%d日 ,  %R | #{username}#{root} | #{hostname} "
tmux_conf_theme_status_right=" #{?uptime_y, #{uptime_y}y,}#{?uptime_d, #{uptime_d}d,}#{?uptime_h, #{uptime_h}h,}#{?uptime_m, #{uptime_m}m,} |  %R "

# status_left_colour
tmux_conf_theme_status_left_fg_colour_1="#282a36"    # 字体颜色->用户
tmux_conf_theme_status_left_fg_colour_2="#f8f8f2"    # 字体颜色->会话
tmux_conf_theme_status_left_bg_colour_1="#50fa7b"    # 背景颜色->用户
tmux_conf_theme_status_left_bg_colour_2="#ff79c6"    # 背景颜色->会话
# status_right_colour
tmux_conf_theme_status_right_fg_colour_1="#282a36"   # 字体颜色->启动时间
tmux_conf_theme_status_right_fg_colour_2="#282a36"   # 字体颜色->时间
tmux_conf_theme_status_right_bg_colour_1="#ffb86c"   # 背景颜色->启动时间
tmux_conf_theme_status_right_bg_colour_2="#ff5555"   # 背景颜色->时间

# status left style
# 会话/启动时间/窗口
tmux_conf_theme_status_left_fg="$tmux_conf_theme_status_left_fg_colour_1,$tmux_conf_theme_status_left_fg_colour_2"
tmux_conf_theme_status_left_bg="$tmux_conf_theme_status_left_bg_colour_1,$tmux_conf_theme_status_left_bg_colour_2"
tmux_conf_theme_status_left_attr="bold,none,none"

# status right style
# 时间/日期/用户
tmux_conf_theme_status_right_fg="$tmux_conf_theme_status_right_fg_colour_1,$tmux_conf_theme_status_right_fg_colour_2"
tmux_conf_theme_status_right_bg="$tmux_conf_theme_status_right_bg_colour_1,$tmux_conf_theme_status_right_bg_colour_2"
tmux_conf_theme_status_right_attr="none,none,bold"

# pairing indicator
tmux_conf_theme_pairing="⚇"                 # U+2687
tmux_conf_theme_pairing_fg="none"
tmux_conf_theme_pairing_bg="none"
tmux_conf_theme_pairing_attr="none"

# prefix indicator
tmux_conf_theme_prefix="⌨"                  # U+2328
tmux_conf_theme_prefix_fg="none"
tmux_conf_theme_prefix_bg="none"
tmux_conf_theme_prefix_attr="none"

# mouse indicator
tmux_conf_theme_mouse="↗"                   # U+2197
tmux_conf_theme_mouse_fg="none"
tmux_conf_theme_mouse_bg="none"
tmux_conf_theme_mouse_attr="none"

# root indicator
tmux_conf_theme_root="!"
tmux_conf_theme_root_fg="none"
tmux_conf_theme_root_bg="none"
tmux_conf_theme_root_attr="bold,blink"

# synchronized indicator
tmux_conf_theme_synchronized="⚏"            # U+268F
tmux_conf_theme_synchronized_fg="none"
tmux_conf_theme_synchronized_bg="none"
tmux_conf_theme_synchronized_attr="none"

# 电池状态标志
tmux_conf_battery_bar_symbol_full="◼"
tmux_conf_battery_bar_symbol_empty="◻"
#tmux_conf_battery_bar_symbol_full="♥"
#tmux_conf_battery_bar_symbol_empty="·"

# 正在充电/使用电池
#tmux_conf_battery_status_charging="↑"       # U+2191
#tmux_conf_battery_status_discharging="↓"    # U+2193
tmux_conf_battery_status_charging="🔌"     # U+1F50C
tmux_conf_battery_status_discharging="🔋"  # U+1F50B

# battery bar length (in number of symbols), possible values are:
#   - auto
#   - a number, e.g. 5
tmux_conf_battery_bar_length="auto"

# battery bar palette, possible values are:
#   - gradient (default)
#   - heat
#   - "colour_full_fg,colour_empty_fg,colour_bg"
tmux_conf_battery_bar_palette="gradient"
#tmux_conf_battery_bar_palette="#d70000,#e4e4e4,#000000"   # red, white, black

# battery hbar palette, possible values are:
#   - gradient (default)
#   - heat
#   - "colour_low,colour_half,colour_full"
tmux_conf_battery_hbar_palette="gradient"
#tmux_conf_battery_hbar_palette="#d70000,#ff5f00,#5fff00"  # red, orange, green

# battery vbar palette, possible values are:
#   - gradient (default)
#   - heat
#   - "colour_low,colour_half,colour_full"
tmux_conf_battery_vbar_palette="gradient"
#tmux_conf_battery_vbar_palette="#d70000,#ff5f00,#5fff00"  # red, orange, green

# clock style (when you hit <prefix> + t)
# you may want to use %I:%M %p in place of %R in tmux_conf_theme_status_right
tmux_conf_theme_clock_colour="$tmux_conf_theme_colour_4"
tmux_conf_theme_clock_style="24"


# -- clipboard -----------------------------------------------------------------

# in copy mode, copying selection also copies to the OS clipboard
#   - true
#   - false (default)
# on macOS, this requires installing reattach-to-user-namespace, see README.md
# on Linux, this requires xsel or xclip
tmux_conf_copy_to_os_clipboard=false


# -- user customizations -------------------------------------------------------
# this is the place to override or undo settings

# increase history size
#set -g history-limit 10000

# start with mouse mode enabled
#set -g mouse on

# force Vi mode
#   really you should export VISUAL or EDITOR environment variable, see manual

# replace C-b by C-a instead of using both prefixes
# set -gu prefix2
# unbind C-a
# unbind C-b
# set -g prefix C-a
# bind C-a send-prefix

# move status line to top
#set -g status-position top


# -- tpm -----------------------------------------------------------------------

# while I don't use tpm myself, many people requested official support so here
# is a seamless integration that automatically installs plugins in parallel

# whenever a plugin introduces a variable to be used in 'status-left' or
# 'status-right', you can use it in 'tmux_conf_theme_status_left' and
# 'tmux_conf_theme_status_right' variables.

# by default, launching tmux will update tpm and all plugins
#   - true (default)
#   - false
tmux_conf_update_plugins_on_launch=true

# by default, reloading the configuration will update tpm and all plugins
#   - true (default)
#   - false
tmux_conf_update_plugins_on_reload=true

# by default, reloading the configuration will uninstall tpm and plugins when no
# plugins are enabled
#   - true (default)
#   - false
tmux_conf_uninstall_plugins_on_reload=true



# -- custom variables ----------------------------------------------------------

# to define a custom #{foo} variable, define a POSIX shell function between the
# '# EOF' and the '# "$@"' lines. Please note that the opening brace { character
# must be on the same line as the function name otherwise the parse won't detect
# it.
#
# then, use #{foo} in e.g. the 'tmux_conf_theme_status_left' or the
# 'tmux_conf_theme_status_right' variables.

# # /!\ do not remove the following line
# EOF
#
# # /!\ do not "uncomment" the functions: the leading "# " characters are needed
#
# weather() {
#   curl -m 1 wttr.in?format=3 2>/dev/null
#   sleep 900 # sleep for 15 minutes, throttle network requests whatever the value of status-interval
# }
#
# online() {
#   ping -c 1 1.1.1.1 >/dev/null 2>&1 && printf '✔' || printf '✘'
# }
#
# "$@"
# # /!\ do not remove the previous line


```
展示效果如下
![tmux.png](/posts/tmux_tmux-png.png)
