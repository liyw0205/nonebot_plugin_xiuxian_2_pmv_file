# nonebot_plugin_xiuxian_2_pmv_file

## Debian / Linux 安装命令

`install.sh` 面向 Debian / Ubuntu / VPS 等常规 Linux 环境，默认目录为 `/root/xiu2`。
当前版本使用本地 SQLite 数据库，脚本只负责安装运行环境、下载项目、安装 Python 依赖和生成 NoneBot 配置。
不带参数运行时会进入交互菜单，可选择安装、重装、更新、更新依赖或退出。

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash
```

自定义目录：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash -s -- install /root/xiuxian
```

更新：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash -s -- update
```

重装：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash -s -- reinstall
```

单独更新依赖：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash -s -- update-deps
```

## Termux 安装命令

`install_termux.sh` 面向安卓 Termux 原生环境，不使用 `/root`、`/bin`、`/etc`，默认安装到 `$HOME/xiu2`，虚拟环境为 `$HOME/myenv`，管理命令写入 `$PREFIX/bin/xiu2`。
当前版本使用本地 SQLite 数据库，不需要安装额外数据库服务。
不带参数运行时会进入交互菜单，可选择安装、重装、更新、更新依赖或退出。

安装：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash
```

自定义目录：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash -s -- install "$HOME/xiuxian"
```

更新：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash -s -- update
```

重装：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash -s -- reinstall
```

单独更新依赖：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash -s -- update-deps
```

Termux 安装完成后建议执行一次：

```
termux-wake-lock
```

避免 Android 休眠时停止后台进程。如果 `termux-wake-lock` 执行失败，可安装 Termux:API 应用后重试；不使用也不影响安装，只影响后台保活。

## SQLite 数据库

插件默认使用本地 SQLite，数据库文件位于项目的 `data/xiuxian/` 目录，例如：

- `xiuxian.db`
- `xiuxian_impart.db`
- `player.db`
- `trade.db`
- `message.db`

脚本不会写入数据库连接串，也不会启动外部数据库服务。更新和重装前建议先备份 `data/xiuxian/`；重装会删除目标安装目录，需要在二次确认时输入 `YES` 才会继续，虚拟环境目录不会随重装自动删除。

## Debian / Linux xiu 命令

```
用法: xiu2 [start|stop|status|update-deps|format [log_file]]
  start     - 启动 xiu2（默认，无需参数）
  status    - 查看 xiu2
  stop      - 停止 xiu2
  update-deps - 更新 Python 依赖到当前 pip 索引最新版本，并输出核心依赖安装路径
  format [log_file] - 格式化日志文件
```

## Termux xiu 命令

```
用法: xiu2 [start|stop|status|update|update-deps|format [log_file]]
  start     - 后台启动 xiu2（默认，无需参数）
  status    - 进入 screen 查看运行日志
  stop      - 停止 xiu2
  update    - 更新项目文件
  update-deps - 更新 Python 依赖到当前 pip 索引最新版本，并输出核心依赖安装路径
  format [log_file] - 格式化日志文件
```
