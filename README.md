# nonebot_plugin_xiuxian_2_pmv_file

## Debian / Linux 安装命令

`install.sh` 面向 Debian / Ubuntu / VPS 等常规 Linux 环境，默认目录为 `/root/xiu2`。

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

单独更新依赖：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install.sh | bash -s -- update-deps
```

## Termux 安装命令

`install_termux.sh` 面向安卓 Termux 原生环境，不使用 `/root`、`/bin`、`/etc`，默认安装到 `$HOME/xiu2`，虚拟环境为 `$HOME/myenv`，管理命令写入 `$PREFIX/bin/xiu2`。

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

单独更新依赖：

```
curl -fsSL https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/raw/refs/heads/main/install_termux.sh | bash -s -- update-deps
```

Termux 安装完成后建议执行一次：

```
termux-wake-lock
```

避免 Android 休眠时停止后台进程。

如果 `termux-wake-lock` 执行失败，可安装 Termux:API 应用后重试；不使用也不影响安装，只影响后台保活。

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
