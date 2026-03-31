#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 带颜色的输出函数
ui_print() {
    local color=$1
    shift
    case $color in
        red) echo -e "${RED}$*${NC}" ;;
        green) echo -e "${GREEN}$*${NC}" ;;
        yellow) echo -e "${YELLOW}$*${NC}" ;;
        blue) echo -e "${BLUE}$*${NC}" ;;
        purple) echo -e "${PURPLE}$*${NC}" ;;
        cyan) echo -e "${CYAN}$*${NC}" ;;
        white) echo -e "${WHITE}$*${NC}" ;;
        *) echo -e "$*" ;;
    esac
}

# 显示操作状态
show_status() {
    local operation=$1
    local status=$2
    if [ "$status" = "success" ]; then
        ui_print "green" "✓ $operation 成功"
    else
        ui_print "red" "✗ $operation 失败"
    fi
}

# 显示进度
show_progress() {
    ui_print "blue" "正在 $1..."
}

# 读取输入（带默认值）
read_or() {
    local var_name="$1"
    local prompt="$2"
    local default_value="$3"

    printf "%s (默认: %s): " "$prompt" "$default_value"
    read -r input
    if [[ -z "$input" ]]; then
        input="$default_value"
    fi
    eval "$var_name=\"\$input\""
}

# 安全创建目录
ensure_dir() {
    local d="$1"
    mkdir -p "$d" || return 1
    return 0
}

# 检查 bc
check_bc_command() {
    if ! command -v bc &> /dev/null; then
        ui_print "yellow" "检测到bc命令不可用，正在尝试安装..."
        if command -v apt &> /dev/null; then
            apt update && apt install -y bc > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y bc > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y bc > /dev/null 2>&1
        else
            ui_print "yellow" "无法自动安装bc，将使用awk进行数值比较"
            return 1
        fi

        if command -v bc &> /dev/null; then
            ui_print "green" "✓ bc安装成功"
            return 0
        else
            ui_print "yellow" "bc安装失败，将使用awk进行数值比较"
            return 1
        fi
    fi
    return 0
}

# 数值比较（兼容无bc）
compare_numbers() {
    local num1=$1
    local op=$2
    local num2=$3
    if command -v bc &> /dev/null; then
        echo "$num1 $op $num2" | bc -l
    else
        awk "BEGIN {print ($num1 $op $num2)}"
    fi
}

# 测试代理
test_proxy() {
    local proxy_url="$1"
    local proxy_host
    proxy_host=$(echo "$proxy_url" | sed -E 's|^https?://([^/:]+).*|\1|')

    if ! command -v ping &> /dev/null; then
        ui_print "yellow" "警告: ping命令不可用，跳过连通性测试"
        echo "100"
        return 0
    fi

    local ping_time
    if ping -c 1 -W 3 "$proxy_host" &> /dev/null; then
        ping_time=$(ping -c 1 -W 3 "$proxy_host" | grep 'time=' | sed -E 's/.*time=([0-9.]+).*/\1/')
        [[ -z "$ping_time" ]] && ping_time="999"
        echo "$ping_time"
        return 0
    else
        echo "9999"
        return 1
    fi
}

# 获取可用代理
get_available_proxies() {
    local proxies=(
        "https://gh-proxy.net/"
        "https://ghfile.geekertao.top/"
        "https://git.yylx.win/"
        "https://gh.llkk.cc/"
        "https://ghproxy.net/"
        "https://github.dpik.top/"
        "https://hub.gitmirror.com/"
        "https://gitproxy.click/"
    )

    local proxy_latency=()
    local total=${#proxies[@]}
    local current=0

    ui_print "yellow" "正在测试代理服务器连通性和延迟..."
    for proxy in "${proxies[@]}"; do
        current=$((current + 1))
        printf "\r${BLUE}进度: %d/%d - 测试 %s${NC}" "$current" "$total" "$proxy"
        latency=$(test_proxy "$proxy")
        proxy_latency+=("$latency:$proxy")

        if (( $(echo "$latency < 999" | bc -l) )); then
            ui_print "green" "\n✓ $proxy 可达 (延迟: ${latency}ms)"
        else
            ui_print "red" "\n✗ $proxy 不可达"
        fi
    done
    echo; echo

    local available_proxies=()
    for item in "${proxy_latency[@]}"; do
        latency=$(echo "$item" | cut -d':' -f1)
        proxy=$(echo "$item" | cut -d':' -f2-)
        if (( $(echo "$latency < 999" | bc -l) )); then
            available_proxies+=("$latency:$proxy")
        fi
    done

    IFS=$'\n' sorted_proxies=($(sort -t: -k1 -n <<< "${available_proxies[*]}"))
    unset IFS

    if [ ${#sorted_proxies[@]} -eq 0 ]; then
        ui_print "red" "没有找到可用代理服务器"
        return 1
    fi

    ui_print "green" "找到 ${#sorted_proxies[@]} 个可用代理（按延迟排序）："
    for i in "${!sorted_proxies[@]}"; do
        latency=$(echo "${sorted_proxies[$i]}" | cut -d':' -f1)
        proxy=$(echo "${sorted_proxies[$i]}" | cut -d':' -f2-)
        ui_print "cyan" "  $((i+1)). $proxy (延迟: ${latency}ms)"
    done
    echo

    AVAILABLE_PROXIES=()
    for item in "${sorted_proxies[@]}"; do
        proxy=$(echo "$item" | cut -d':' -f2-)
        AVAILABLE_PROXIES+=("$proxy")
    done

    return 0
}

# 选择代理
get_proxy_choice() {
    ui_print "yellow" "请选择是否使用下载代理："
    ui_print "white" "1：自动选择最低延迟可用代理（默认）"
    ui_print "white" "2：手动选择可用代理"
    ui_print "white" "3：不使用代理"
    ui_print "white" "4：自定义代理"
    echo

    read_or PROXY_CHOICE "请选择代理选项 (1-4)" "1"

    PROXY=""
    case "$PROXY_CHOICE" in
        1)
            check_bc_command
            if get_available_proxies; then
                PROXY="${AVAILABLE_PROXIES[0]}"
                latency=$(echo "${sorted_proxies[0]}" | cut -d':' -f1)
                ui_print "green" "✓ 自动选择代理：$PROXY (延迟: ${latency}ms)"
            else
                ui_print "yellow" "未找到可用代理，将直连"
            fi
            ;;
        2)
            check_bc_command
            if get_available_proxies; then
                read_or PROXY_INDEX "请选择代理编号 (1-${#AVAILABLE_PROXIES[@]})" "1"
                if [[ "$PROXY_INDEX" =~ ^[0-9]+$ ]] && [ "$PROXY_INDEX" -ge 1 ] && [ "$PROXY_INDEX" -le "${#AVAILABLE_PROXIES[@]}" ]; then
                    PROXY="${AVAILABLE_PROXIES[$((PROXY_INDEX-1))]}"
                    ui_print "green" "✓ 已选择代理：$PROXY"
                else
                    ui_print "yellow" "无效编号，将直连"
                fi
            else
                ui_print "yellow" "未找到可用代理，将直连"
            fi
            ;;
        3)
            ui_print "green" "✓ 不使用代理"
            ;;
        4)
            read_or CUSTOM_PROXY "请输入自定义代理地址(如 https://xxx/)" ""
            if [[ -n "$CUSTOM_PROXY" ]]; then
                check_bc_command
                latency=$(test_proxy "$CUSTOM_PROXY")
                if (( $(compare_numbers "$latency" "<" "999") )); then
                    PROXY="$CUSTOM_PROXY"
                    ui_print "green" "✓ 自定义代理可用：$PROXY"
                else
                    ui_print "yellow" "自定义代理不可达，将直连"
                fi
            else
                ui_print "yellow" "未输入代理地址，将直连"
            fi
            ;;
        *)
            ui_print "yellow" "无效选项，将直连"
            ;;
    esac
}

# 下载release资源（支持代理重试）
download_release_resource() {
    local release_url="$1"
    local download_path="$2"
    local proxy_urls="$3"

    show_progress "下载release资源文件"

    if [[ -z "$proxy_urls" || "$proxy_urls" == " " ]]; then
        ui_print "cyan" "直连下载: $release_url"
        if command -v wget &> /dev/null; then
            wget -O "$download_path" "$release_url" && return 0
        elif command -v curl &> /dev/null; then
            curl -L -o "$download_path" "$release_url" && return 0
        fi
        return 1
    fi

    local proxy_array=()
    if [[ "$proxy_urls" == "("*")" ]]; then
        eval "proxy_array=${proxy_urls}"
    else
        proxy_array=("$proxy_urls")
    fi

    for proxy_url in "${proxy_array[@]}"; do
        local download_url
        if [[ -n "$proxy_url" ]]; then
            download_url="${proxy_url}${release_url}"
        else
            download_url="$release_url"
        fi

        ui_print "cyan" "代理下载: $download_url"

        if command -v wget &> /dev/null; then
            if wget -O "$download_path" "$download_url"; then
                return 0
            fi
        elif command -v curl &> /dev/null; then
            if curl -L -o "$download_path" "$download_url"; then
                return 0
            fi
        else
            ui_print "red" "错误: 未找到wget或curl"
            return 1
        fi

        rm -f "$download_path" 2>/dev/null
        ui_print "yellow" "代理 $proxy_url 下载失败，尝试下一个..."
    done

    ui_print "yellow" "所有代理失败，尝试直连..."
    if command -v wget &> /dev/null; then
        wget -O "$download_path" "$release_url" && return 0
    elif command -v curl &> /dev/null; then
        curl -L -o "$download_path" "$release_url" && return 0
    fi

    return 1
}

# 解压资源
extract_release_resource() {
    local archive_path="$1"
    local extract_dir="$2"

    show_progress "解压release资源文件"
    ensure_dir "$extract_dir" || return 1

    if [[ "$archive_path" == *.tar.gz ]]; then
        tar -xzf "$archive_path" -C "$extract_dir" --strip-components=1 && return 0
    elif [[ "$archive_path" == *.zip ]]; then
        if command -v unzip &> /dev/null; then
            unzip -q "$archive_path" -d "$extract_dir" && return 0
        else
            ui_print "red" "错误: 未找到unzip"
            return 1
        fi
    else
        ui_print "red" "错误: 不支持的压缩格式"
        return 1
    fi
}

# 写入/覆盖日志轮转配置 + cron任务
setup_logrotate_and_cron() {
    # logrotate 配置（按大小轮转）
    cat <<EOF > "/etc/logrotate.d/$PROJECT_NAME"
"$DIR/${PROJECT_NAME}.log" {
    size 20M
    rotate 10
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    dateext
    dateformat -%Y%m%d-%s
}
EOF
    if [[ $? -eq 0 ]]; then
        show_status "创建 logrotate 配置 /etc/logrotate.d/$PROJECT_NAME" "success"
    else
        show_status "创建 logrotate 配置 /etc/logrotate.d/$PROJECT_NAME" "failure"
        return 1
    fi

    # cron 配置：每10分钟检查一次日志轮转
    cat <<EOF > "/etc/cron.d/${PROJECT_NAME}_logrotate"
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/10 * * * * root /usr/sbin/logrotate -s /var/lib/logrotate/status /etc/logrotate.d/$PROJECT_NAME >/dev/null 2>&1
EOF
    chmod 644 "/etc/cron.d/${PROJECT_NAME}_logrotate"

    if [[ $? -eq 0 ]]; then
        show_status "创建定时轮转任务 /etc/cron.d/${PROJECT_NAME}_logrotate" "success"
    else
        show_status "创建定时轮转任务 /etc/cron.d/${PROJECT_NAME}_logrotate" "failure"
        return 1
    fi

    return 0
}

# ---------------- 参数解析（支持项目名或绝对路径） ----------------
DEFAULT_PROJECT_NAME="xiu2"
ACTION="install"
TARGET_INPUT="$DEFAULT_PROJECT_NAME"

if [ $# -eq 0 ]; then
    ACTION="install"
    TARGET_INPUT="$DEFAULT_PROJECT_NAME"
elif [ $# -eq 1 ]; then
    case "$1" in
        install)
            ACTION="install"
            TARGET_INPUT="$DEFAULT_PROJECT_NAME"
            ;;
        update)
            ACTION="update"
            TARGET_INPUT="$DEFAULT_PROJECT_NAME"
            ;;
        *)
            ACTION="install"
            TARGET_INPUT="$1"
            ;;
    esac
else
    case "$1" in
        install|update)
            ACTION="$1"
            TARGET_INPUT="$2"
            ;;
        *)
            ui_print "red" "参数错误: 第一个参数只能是 install 或 update"
            ui_print "yellow" "用法: $0 [install|update] [project_name|/abs/path]"
            ui_print "yellow" "兼容用法: $0 [project_name|/abs/path]"
            exit 127
            ;;
    esac
fi

if [[ "$TARGET_INPUT" == /* ]]; then
    DIR="$TARGET_INPUT"
    PROJECT_NAME="$(basename "$DIR")"
else
    PROJECT_NAME="$TARGET_INPUT"
    DIR="/root/$PROJECT_NAME"
fi

if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME="$DEFAULT_PROJECT_NAME"
fi

ui_print "green" "执行模式: $ACTION"
ui_print "green" "项目名称: $PROJECT_NAME"
ui_print "green" "安装目录: $DIR"

if [[ "$ACTION" == "update" && ! -d "$DIR" ]]; then
    ui_print "yellow" "目录不存在，自动切换到 install：$DIR"
    ACTION="install"
fi

if [[ "$ACTION" == "install" ]]; then
    if [[ -d "$DIR" ]]; then
        ui_print "red" "安装目录已存在，请使用 update 或先删除：$DIR"
        exit 127
    fi
    ensure_dir "$DIR" || { show_status "创建安装主目录 $DIR" "failure"; exit 127; }
    show_status "创建安装主目录 $DIR" "success"
    ensure_dir "$DIR/src/plugins" || { show_status "创建插件目录 $DIR/src/plugins" "failure"; exit 127; }
    show_status "创建插件目录 $DIR/src/plugins" "success"
else
    ui_print "green" "检测到安装目录，执行更新：$DIR"
    ensure_dir "$DIR/src/plugins" || { show_status "创建插件目录 $DIR/src/plugins" "failure"; exit 127; }
fi

if [[ "$ACTION" == "install" ]]; then
    show_progress "更新系统及安装依赖"
    if command -v apt &> /dev/null; then
        apt update && apt upgrade -y && apt install -y screen curl wget git python3 python3-pip python3-venv bc tar unzip
    elif command -v yum &> /dev/null; then
        yum update -y && yum install -y screen curl wget git python3 python3-pip python3-virtualenv bc tar unzip
    elif command -v dnf &> /dev/null; then
        dnf update -y && dnf install -y screen curl wget git python3 python3-pip python3-virtualenv bc tar unzip
    else
        ui_print "red" "不支持的包管理器，请手动安装依赖"
        exit 127
    fi
    [ $? -eq 0 ] && show_status "系统更新及依赖安装" "success" || { show_status "系统更新及依赖安装" "failure"; exit 127; }

    cat <<EOF > "$DIR/pyproject.toml"
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$PROJECT_NAME"
readme = "README.md"
requires-python = ">=3.9, <4.0"
dependencies = [
    "nonebot2[fastapi]>=2.4.4",
    "nonebot2[httpx]>=2.4.4",
    "nonebot2[websockets]>=2.4.4",
    "nonebot2[aiohttp]>=2.4.4",
    "nonebot-adapter-onebot>=2.4.6",
    "nonebot-adapter-qq>=1.6.7"
]

[project.optional-dependencies]
dev = []

[tool.nonebot]
plugin_dirs = ["src/plugins"]
builtin_plugins = []

[tool.nonebot.adapters]
nonebot-adapter-onebot = [
    { name = "OneBot V11", module_name = "nonebot.adapters.onebot.v11" }
]
"@local" = []
nonebot-adapter-qq = [{name = "QQ", module_name = "nonebot.adapters.qq"}]

[tool.nonebot.plugins]
"@local" = []
EOF

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    show_status "设置时区为 Asia/Shanghai" "success"
fi

get_proxy_choice

REPO_OWNER="liyw0205"
REPO_NAME="nonebot_plugin_xiuxian_2_pmv"
RELEASE_TAG="latest"
RELEASE_ASSET="project.tar.gz"

if [[ "$RELEASE_TAG" == "latest" ]]; then
    RELEASE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/$RELEASE_ASSET"
else
    RELEASE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$RELEASE_TAG/$RELEASE_ASSET"
fi

TEMP_DOWNLOAD_PATH="$DIR/${REPO_NAME}_${RELEASE_ASSET}"
TEMP_EXTRACT_DIR="$DIR/temp_extract"

if [[ "$PROXY_CHOICE" == "1" && -n "$PROXY" && -n "${AVAILABLE_PROXIES[*]}" ]]; then
    PROXY_FOR_DOWNLOAD="(${AVAILABLE_PROXIES[*]})"
elif [[ -n "$PROXY" ]]; then
    PROXY_FOR_DOWNLOAD="$PROXY"
else
    PROXY_FOR_DOWNLOAD=""
fi

if download_release_resource "$RELEASE_URL" "$TEMP_DOWNLOAD_PATH" "$PROXY_FOR_DOWNLOAD"; then
    show_status "下载release资源文件" "success"
else
    show_status "下载release资源文件" "failure"
    exit 127
fi

if extract_release_resource "$TEMP_DOWNLOAD_PATH" "$TEMP_EXTRACT_DIR"; then
    show_status "解压release资源文件" "success"
else
    show_status "解压release资源文件" "failure"
    exit 127
fi

show_progress "移动文件到安装目录"

if [[ -d "$TEMP_EXTRACT_DIR/nonebot_plugin_xiuxian_2" ]]; then
    cp -rf "$TEMP_EXTRACT_DIR/nonebot_plugin_xiuxian_2" "$DIR/src/plugins/" || { show_status "移动插件文件" "failure"; exit 127; }
    show_status "移动插件文件" "success"
fi

if [[ -d "$TEMP_EXTRACT_DIR/data" ]]; then
    cp -rf "$TEMP_EXTRACT_DIR/data" "$DIR/" || { show_status "移动data目录" "failure"; exit 127; }
    show_status "移动data目录" "success"
fi

if [[ -f "$TEMP_EXTRACT_DIR/requirements.txt" ]]; then
    mv "$TEMP_EXTRACT_DIR/requirements.txt" "$DIR/" || { show_status "移动requirements.txt" "failure"; exit 127; }
    show_status "移动requirements.txt" "success"
fi

rm -rf "$TEMP_DOWNLOAD_PATH" "$TEMP_EXTRACT_DIR" > /dev/null 2>&1
show_status "清理临时文件" "success"

VENV_PATH="/root/myenv"

if [[ "$ACTION" == "install" ]]; then
    show_progress "创建 Python 虚拟环境"
    python3 -m venv "$VENV_PATH" > /dev/null 2>&1
    [ $? -eq 0 ] && show_status "创建 Python 虚拟环境" "success" || { show_status "创建 Python 虚拟环境" "failure"; exit 127; }

    # 启动脚本
    cat <<EOF > "/bin/${PROJECT_NAME}_start"
#!/bin/bash
export TZ=Asia/Shanghai

# 启动时自动确保 logrotate + cron 存在
if [ ! -f "/etc/logrotate.d/$PROJECT_NAME" ]; then
cat <<'LR_EOF' > "/etc/logrotate.d/$PROJECT_NAME"
"$DIR/${PROJECT_NAME}.log" {
    size 20M
    rotate 10
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    dateext
    dateformat -%Y%m%d-%s
}
LR_EOF
fi

if [ ! -f "/etc/cron.d/${PROJECT_NAME}_logrotate" ]; then
cat <<'CRON_EOF' > "/etc/cron.d/${PROJECT_NAME}_logrotate"
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/10 * * * * root /usr/sbin/logrotate -s /var/lib/logrotate/status /etc/logrotate.d/$PROJECT_NAME >/dev/null 2>&1
CRON_EOF
chmod 644 "/etc/cron.d/${PROJECT_NAME}_logrotate"
fi

source "$VENV_PATH/bin/activate"
cd "$DIR"
nb run --reload
EOF

    source "$VENV_PATH/bin/activate" > /dev/null 2>&1
    [ $? -eq 0 ] && show_status "激活 Python 虚拟环境" "success" || { show_status "激活 Python 虚拟环境" "failure"; exit 127; }

    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple > /dev/null 2>&1
    show_status "设置 pip 镜像源为清华源" "success"

    cd "$DIR" || { show_status "进入安装目录 $DIR" "failure"; exit 127; }
    show_status "进入安装目录 $DIR" "success"

    show_progress "安装 nb-cli"
    pip install nb-cli==1.5.0
    [ $? -eq 0 ] && show_status "安装 nb-cli" "success" || { show_status "安装 nb-cli" "failure"; exit 127; }

    show_progress "安装 nonebot 驱动和 onebot.v11 适配器"
    nb driver install fastapi
    nb driver install httpx
    nb driver install websockets
    nb driver install aiohttp
    nb adapter install onebot.v11
    nb adapter install qq
    [ $? -eq 0 ] && show_status "安装 nonebot 驱动和 onebot.v11/qq 适配器" "success" || show_status "安装 nonebot 驱动和 onebot.v11 适配器" "failure"

    if [[ -f "$DIR/requirements.txt" ]]; then
        show_progress "安装依赖（requirements.txt）"
        pip install -r "$DIR/requirements.txt" > /dev/null 2>&1
        [ $? -eq 0 ] && show_status "安装依赖（requirements.txt）" "success" || { show_status "安装依赖（requirements.txt）" "failure"; exit 127; }
    fi

    show_progress "获取用户配置信息"
    read_or SUPERUSERS "请输入主人QQ号（SUPERUSERS）" "123456"
    read_or NICKNAME "请输入机器人昵称（NICKNAME）" "堂堂"
    read_or PORT "请输入端口号（PORT）" "8080"

    cat <<EOF > "$DIR/.env"
ENVIRONMENT=dev
DRIVER=~fastapi+~httpx+~websockets+~aiohttp
EOF

    cat <<EOF > "$DIR/.env.dev"
LOG_LEVEL=INFO

SUPERUSERS = ["$SUPERUSERS"]
COMMAND_START = [""]
NICKNAME = ["$NICKNAME"]
DEBUG = False
HOST = 0.0.0.0
PORT = $PORT
EOF
    show_status "生成配置信息" "success"

    cat <<EOF > "/bin/$PROJECT_NAME"
formatlog() {
    local LOG_FILE="\$1"
    awk '{
        gsub(/\033\[[0-9;]*m/, "")
        if (/#[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/ || /[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/) {
            print "\n" \$0
        } else {
            print "  " \$0
        }
    }' "\$LOG_FILE" > "\$LOG_FILE.format.log"
}

if [ "\$#" -eq 0 ]; then
    set -- start
fi

case "\$1" in
    start)
        if [ ! -f "/etc/logrotate.d/$PROJECT_NAME" ]; then
cat <<'LR_EOF' > "/etc/logrotate.d/$PROJECT_NAME"
"$DIR/${PROJECT_NAME}.log" {
    size 20M
    rotate 10
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    dateext
    dateformat -%Y%m%d-%s
}
LR_EOF
        fi
        if [ ! -f "/etc/cron.d/${PROJECT_NAME}_logrotate" ]; then
cat <<'CRON_EOF' > "/etc/cron.d/${PROJECT_NAME}_logrotate"
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/10 * * * * root /usr/sbin/logrotate -s /var/lib/logrotate/status /etc/logrotate.d/$PROJECT_NAME >/dev/null 2>&1
CRON_EOF
            chmod 644 "/etc/cron.d/${PROJECT_NAME}_logrotate"
        fi

        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            echo "$PROJECT_NAME 已在后台运行"
        else
            echo "正在后台启动 $PROJECT_NAME..."
            screen -U -dmS "$PROJECT_NAME" -L -Logfile "$DIR/${PROJECT_NAME}.log" bash -c '${PROJECT_NAME}_start'
            echo "已后台启动"
        fi
        ;;
    stop)
        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            screen -X -S "$PROJECT_NAME" quit
            echo "$PROJECT_NAME 已停止"
        else
            echo "$PROJECT_NAME 未在运行"
        fi
        ;;
    status)
        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            screen -U -r "$PROJECT_NAME"
        else
            echo "$PROJECT_NAME 未在运行"
        fi
        ;;
    format)
        if [ -n "\$2" ]; then
            if [ -f "\$2" ]; then
                formatlog "\$2"
                echo "已输出: \$2.format.log"
            else
                echo "错误：日志文件不存在: \$2"
            fi
        else
            LOG_FILE="$DIR/${PROJECT_NAME}.log"
            if [ -f "\$LOG_FILE" ]; then
                formatlog "\$LOG_FILE"
                echo "已输出: \$LOG_FILE.format.log"
            else
                echo "错误：默认日志文件不存在: \$LOG_FILE"
            fi
        fi
        ;;
    *)
        echo "用法: $PROJECT_NAME [start|stop|status|format [log_file]]"
        ;;
esac
EOF

    chmod +x "/bin/${PROJECT_NAME}_start" "/bin/$PROJECT_NAME"
    show_status "创建启动脚本 /bin/${PROJECT_NAME}_start 和 /bin/$PROJECT_NAME" "success"

    # install 完成后写入 logrotate + cron
    setup_logrotate_and_cron || exit 127

else
    # update
    show_progress "更新模式：安装/更新依赖"
    if [[ -f "$VENV_PATH/bin/activate" ]]; then
        # shellcheck disable=SC1090
        source "$VENV_PATH/bin/activate" > /dev/null 2>&1
        if [[ -f "$DIR/requirements.txt" ]]; then
            pip install -r "$DIR/requirements.txt" > /dev/null 2>&1
            [ $? -eq 0 ] && show_status "更新依赖（requirements.txt）" "success" || show_status "更新依赖（requirements.txt）" "failure"
        else
            ui_print "yellow" "未找到 requirements.txt，跳过依赖更新"
        fi
    else
        ui_print "yellow" "未检测到虚拟环境 $VENV_PATH，尝试系统 pip3 更新依赖"
        if [[ -f "$DIR/requirements.txt" ]]; then
            pip3 install -r "$DIR/requirements.txt" > /dev/null 2>&1
            [ $? -eq 0 ] && show_status "更新依赖（requirements.txt）" "success" || show_status "更新依赖（requirements.txt）" "failure"
        else
            ui_print "yellow" "未找到 requirements.txt，跳过依赖更新"
        fi
    fi

    # update 也强制覆盖 logrotate + cron
    setup_logrotate_and_cron || exit 127
fi

IPV4=$(curl -s ifconfig.me 2>/dev/null)
PORT_SHOW=$(grep -E '^PORT *= *' "$DIR/.env.dev" 2>/dev/null | sed -E 's/.*= *//')
[[ -z "$PORT_SHOW" ]] && PORT_SHOW="8080"

ui_print "green" "========================================"
ui_print "green" "✓ ${ACTION} 完成！"
ui_print "green" "项目名称: $PROJECT_NAME"
ui_print "green" "安装目录: $DIR"
ui_print "green" "OneBot V11 协议地址："
ui_print "white" "    ws://${IPV4}:${PORT_SHOW}/onebot/v11/ws"
ui_print "white" "    ws://127.0.0.1:${PORT_SHOW}/onebot/v11/ws"
ui_print "green" "可用命令："
ui_print "white" "    $PROJECT_NAME"
ui_print "white" "    $PROJECT_NAME stop"
ui_print "white" "    $PROJECT_NAME status"
ui_print "white" "    $PROJECT_NAME format [log_file]"
ui_print "green" "========================================"