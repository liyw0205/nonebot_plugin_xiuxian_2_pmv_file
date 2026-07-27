# nonebot_plugin_xiuxian_2_pmv_file

修仙 2 插件的**大文件 / Release 资产仓库**。

- 不放业务源码
- 不放一键安装脚本（脚本在主仓库）
- 只通过 GitHub Releases 分发 Docker 镜像分片、插件包、表情包、运行资源等

主仓库（代码 + 文档 + 安装脚本）：

https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv

---

## Releases 一览

| Tag | 用途 |
|-----|------|
| [`docker-latest`](https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/releases/tag/docker-latest) | Docker 底座分片 + 插件包 + `manifest.json` |
| [`stickers-latest`](https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/releases/tag/stickers-latest) | Web 消息面板表情包 |
| [`v0`](https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv_file/releases/tag/v0) | 启动资源（如 `xiuxian.zip` 字体/图片等） |

Tag 名尽量固定（`*-latest` / `v0`），日常只**覆盖上传资产**，主仓库脚本与文档一般不用跟着改。

---

## Docker（`docker-latest`）

采用 **base + plugin** 两层，避免每次小改都下完整镜像。

### 资产

| 文件 | 说明 |
|------|------|
| `manifest.json` | 总清单（md5 / 版本 / 分片列表） |
| `xiuxian2-base-amd64.tar.gz.part00` ~ `partN` | 底座镜像分片（系统 + Python 依赖，变更少） |
| `xiuxian2-base-amd64.tar.gz.md5` | 合并后整包 md5 |
| `xiuxian2-base-amd64.tar.gz.partXX.md5` | 各分片 md5 |
| `xiuxian2-plugin-latest.tar.gz` | **仅插件**单包（日常更新通常只下这个） |
| `xiuxian2-plugin-latest.tar.gz.md5` | 插件包 md5 |

### 安装 / 更新（请用主仓库脚本）

```bash
# 安装
curl -fsSL https://raw.githubusercontent.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/main/scripts/install_docker.sh | bash

# smart 更新：base 未变则只下 plugin
curl -fsSL https://raw.githubusercontent.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/main/scripts/install_docker.sh | bash -s -- update

# 仅插件 / 强制整包
bash install_docker.sh update --plugin
bash install_docker.sh update --full
```

说明与目录结构见主仓库：

- https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/blob/main/docker/README.md
- https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/blob/main/scripts/install_docker.sh

### 发布（维护者）

在主仓库执行：

```bash
bash scripts/build_docker_release.sh /tmp/xiuxian2-docker-split-release
# 上传到本仓库 docker-latest（覆盖 clobber）
# 日常只改插件：上传 plugin + 更新 manifest 即可
# requirements / Dockerfile.base 变了：再上传 base 分片
```

---

## 表情包（`stickers-latest`）

| 文件 | 说明 |
|------|------|
| `stickers-manifest.json` | 套装清单 |
| `stickers-kokomi.zip` | 心海 |
| `stickers-doro.zip` | doro |
| `stickers-miku.zip` | 初音 |

Web 消息面板首次打开表情会按 manifest 下载并缓存到运行目录 `data/xiuxian/stickers/`。

---

## 启动资源（`v0`）

插件首次启动若检测不到必要资源（如字体），会自动下载本 tag 下的资源包（例如 `xiuxian.zip`）解压到 `data/`。

- 资源在 data 卷里，**日常更新插件不会强制重下**
- 只有清空 data / 新环境 / 关键文件缺失时才会再下

---

## 非 Docker 安装

请使用**主仓库**脚本与文档，不要再从本仓库拉 `install.sh`：

```bash
# 以主仓库 README 为准
https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv
```

---

## 仓库约定

1. **主仓库**：源码、文档、`scripts/install_docker.sh`、`scripts/build_docker_release.sh`
2. **本仓库**：仅 Releases 大文件；git 主分支保持轻量（可只有本 README）
3. 凭据、密钥、用户数据禁止提交
4. 大文件用 Release 覆盖上传，不把镜像/分片 commit 进 git

---

## License

与主仓库插件许可保持一致；资产仅作对应插件分发使用。
