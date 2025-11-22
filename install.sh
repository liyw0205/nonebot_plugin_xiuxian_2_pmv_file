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
        red) echo -e "${RED}$@${NC}" ;;
        green) echo -e "${GREEN}$@${NC}" ;;
        yellow) echo -e "${YELLOW}$@${NC}" ;;
        blue) echo -e "${BLUE}$@${NC}" ;;
        purple) echo -e "${PURPLE}$@${NC}" ;;
        cyan) echo -e "${CYAN}$@${NC}" ;;
        white) echo -e "${WHITE}$@${NC}" ;;
        *) echo -e " $@" ;;
    esac
}

# 显示操作状态的函数
show_status() {
    local operation=$1
    local status=$2
    if [ "$status" = "success" ]; then
        ui_print "green" "✓ $operation 成功"
    else
        ui_print "red" "✗ $operation 失败"
    fi
}

# 显示正在进行的操作
show_progress() {
    ui_print "blue" "正在 $1..."
}

# 读取用户输入的函数（带默认值）
read_or() {
    local var_name="$1"
    local prompt="$2"
    local default_value="$3"
    
    printf "$prompt (默认: $default_value): "
    read -r input
    if [[ -z "$input" ]]; then
        input="$default_value"
    fi
    eval "$var_name=\"$input\""
}

# 询问用户是否使用代理
get_proxy_choice() {
    ui_print "yellow" "请选择是否使用 Git / 下载代理："
    ui_print "white" "y/Y：使用默认代理（https://github.akams.cn）"
    ui_print "white" "n/N 或 直接回车：不使用代理（默认）"
    ui_print "white" "其他任意内容：自定义代理地址"
    echo

    read_or USE_PROXY "是否使用代理？(y/Y/n/N/自定义代理地址)" ""

    PROXY=""
    case "$USE_PROXY" in
        y|Y|"")
            PROXY="https://github.akams.cn"
            ui_print "green" "✓ 将使用默认代理：$PROXY"
            ;;
        n|N)
            ui_print "green" "✓ 不使用代理"
            ;;
        *)
            PROXY="$USE_PROXY"
            ui_print "green" "✓ 将使用自定义代理：$PROXY"
            ;;
    esac
}

# 检查并创建安装目录
DIR="/root/xiu2"
if [[ -d "$DIR" ]]; then
    ui_print "red" "安装目录已存在，请手动删除：$DIR"
    exit 127
else
    mkdir -p "$DIR" || {
        show_status "创建安装主目录 $DIR" "failure"
        exit 127
    }
    show_status "创建安装主目录 $DIR" "success"

    mkdir -p "$DIR/src/plugins" || {
        show_status "创建插件目录 $DIR/src/plugins" "failure"
        exit 127
    }
    show_status "创建插件目录 $DIR/src/plugins" "success"
fi

# 系统依赖安装
show_progress "更新系统及安装依赖"
if command -v apt &> /dev/null; then
    # Debian/Ubuntu
    apt update && apt upgrade -y && apt install -y screen curl wget git python3 python3-pip python3-venv
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum update -y && yum install -y screen curl wget git python3 python3-pip python3-virtualenv
elif command -v dnf &> /dev/null; then
    # Fedora
    dnf update -y && dnf install -y screen curl wget git python3 python3-pip python3-virtualenv
else
    ui_print "red" "不支持的包管理器，请手动安装必要的依赖。"
    exit 127
fi
if [ $? -eq 0 ]; then
    show_status "系统更新及依赖安装" "success"
else
    show_status "系统更新及依赖安装" "failure"
    exit 127
fi

# 用户输入配置信息
show_progress "获取用户配置信息"
read_or SUPERUSERS "请输入主人QQ号（SUPERUSERS）" ""
read_or NICKNAME "请输入机器人昵称（NICKNAME）" "堂堂"
read_or PORT "请输入端口号（PORT）" "8080"

# 写入配置文件
cat <<EOF> "$DIR/.env"
ENVIRONMENT=dev
DRIVER=~fastapi+~httpx+~websockets+~aiohttp
EOF

cat <<EOF> "$DIR/.env.dev"
LOG_LEVEL=INFO

SUPERUSERS = ["$SUPERUSERS"]
COMMAND_START = [""]
NICKNAME = ["$NICKNAME"]
DEBUG = False
HOST = 0.0.0.0
PORT = $PORT
EOF

cat <<EOF> "$DIR/pyproject.toml"
[project]
name = "xiu2"
version = "0.1.0"
description = "xiu2"
readme = "README.md"
requires-python = ">=3.9, <4.0"
dependencies = [
    "nonebot2[fastapi]>=2.4.4",
    "nonebot2[httpx]>=2.4.4",
    "nonebot2[websockets]>=2.4.4",
    "nonebot2[aiohttp]>=2.4.4",
    "nonebot-adapter-onebot>=2.4.6"
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

[tool.nonebot.plugins]
"@local" = []
EOF

# 设置时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
show_status "设置时区为 Asia/Shanghai (上海)" "success"

# 设置代理
get_proxy_choice

# 克隆 nonebot xiu2插件仓库
ui_print "yellow" "正在克隆 nonebot xiu2插件仓库..."
git clone --depth=1 -b main $PROXY/https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv.git
if [ $? -eq 0 ]; then
    show_status "Git 克隆 nonebot_plugin_xiuxian_2_pmv 仓库" "success"
else
    show_status "Git 克隆 nonebot_plugin_xiuxian_2_pmv 仓库" "failure"
    exit 127
fi

# 移动文件到安装目录
mv /root/nonebot_plugin_xiuxian_2_pmv/nonebot_plugin_xiuxian_2 "$DIR/src/plugins" || {
    show_status "移动 nonebot_plugin_xiuxian_2 到 $DIR/src/plugins" "failure"
    exit 127
}
show_status "移动 nonebot_plugin_xiuxian_2 到 $DIR/src/plugins" "success"

mv /root/nonebot_plugin_xiuxian_2_pmv/data "$DIR" || {
    show_status "移动 data 目录到 $DIR" "failure"
    exit 127
}
show_status "移动 data 目录到 $DIR" "success"

mv /root/nonebot_plugin_xiuxian_2_pmv/requirements.txt "$DIR" || {
    show_status "移动 requirements.txt 到 $DIR" "failure"
    exit 127
}
show_status "移动 requirements.txt 到 $DIR" "success"

# 清理临时克隆的仓库
rm -rf /root/nonebot_plugin_xiuxian_2_pmv > /dev/null 2>&1
show_status "清理临时克隆目录 /root/nonebot_plugin_xiuxian_2_pmv" "success"

# 创建 Python 虚拟环境并安装依赖
show_progress "创建 Python 虚拟环境 myenv"
python3 -m venv myenv > /dev/null 2>&1
if [ $? -eq 0 ]; then
    show_status "创建 Python 虚拟环境 myenv" "success"
else
    show_status "创建 Python 虚拟环境 myenv" "failure"
    exit 127
fi

source /root/myenv/bin/activate > /dev/null 2>&1
if [ $? -ne 0 ]; then
    show_status "激活 Python 虚拟环境" "failure"
    exit 127
fi
show_status "激活 Python 虚拟环境" "success"

pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple > /dev/null 2>&1
show_status "设置 pip 镜像源为清华源" "success"

cd "$DIR" || {
    show_status "进入安装目录 $DIR" "failure"
    exit 127
}
show_status "进入安装目录 $DIR" "success"

show_progress "安装 nb-cli"
pip install nb-cli
if [ $? -eq 0 ]; then
    show_status "安装 nb-cli" "success"
else
    show_status "安装 nb-cli" "failure"
    exit 127
fi

show_progress "安装 nonebot 驱动和 onebot.v11 适配器"
nb driver install fastapi
nb driver install httpx
nb driver install websockets
nb driver install aiohttp
nb adapter install onebot.v11

if [ $? -eq 0 ]; then
    show_status "安装 nonebot 驱动和 onebot.v11 适配器" "success"
else
    show_status "安装 nonebot 驱动和 onebot.v11 适配器" "failure"
fi

show_progress "安装依赖项（来自 requirements.txt）"
pip install -r requirements.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    show_status "安装依赖项（来自 requirements.txt）" "success"
else
    show_status "安装依赖项（来自 requirements.txt）" "failure"
    exit 127
fi

# 创建启动脚本
cat <<EOF> "/bin/xiu2_start"
export TZ=Asia/Shanghai
source /root/myenv/bin/activate
cd $DIR
nb run
EOF

# 创建启动脚本和格式化日志功能
cat <<EOF> "/bin/xiu2"
formatlog() {
LOG_FILE="\$@"
awk '{
                # 移除颜色代码
                gsub(/\033\\[[0-9;]*m/, "")
                # 按时间戳分组（假设格式为 MM-DD HH:MM:SS）
                if (/\#[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/ || /[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/) {
                    print "\n" \$0 ""
                } else {
                    print "  " \$0
                }
            }' "\$LOG_FILE" "\$LOG_FILE.format.log"
}
if [ "\$#" -eq 0 ]; then
    if screen -list | grep -q '\bxiu2\b'; then
        echo "xiu2已在后台运行"
        echo "   您可以查看现有会话："
        echo "       screen -r xiu2"
        echo "   或查看日志："
        echo "       tail -f /root/xiu2.log"
    else
        echo "正在后台启动xiu2..."
        screen -U -dmS xiu2 -L -Logfile /root/xiu2.log bash -c 'xiu2_start'
        echo "已后台启动，通过以下命令查看当前状态："
        echo "       screen -r xiu2"
        echo "   或查看日志："
        echo "       tail -f /root/xiu2.log"
    fi
elif [ "\$#" -eq 1 ]; then
    if [ "\$1" = "stop" ]; then
        if screen -list | grep -q '\bxiu2\b'; then
            echo "正在停止xiu2..."
            screen -X -S xiu2 quit
            echo "xiu2已停止"
        else
            echo "xiu2未在运行"
        fi
    elif [ "\$1" = "status" ]; then
        if screen -list | grep -q '\bxiu2\b'; then
            screen -U -r xiu2
        else
            echo "xiu2未在运行"
        fi        
    elif [ "\$1" = "format" ]; then
        LOG_FILE="/root/xiu2.log"
        if [ -f "\$LOG_FILE" ]; then
            formatlog "\$LOG_FILE"
        else
            echo "错误：日志文件 \$LOG_FILE 不存在"
        fi
    else
        echo "用法: xiu2 [start|stop|format [log_file]]"
        echo "  start     - 启动 xiu2（默认，无需参数）"
        echo "  stop      - 停止 xiu2"
        echo "  format [log_file] - 格式化日志文件（默认: /root/xiu2.log）"
    fi
elif [ "\$#" -eq 2 ] && [ "\$1" = "format" ]; then
    LOG_FILE="\$2"
    if [ -f "\$LOG_FILE" ]; then
        formatlog "\$LOG_FILE"
    else
        echo "错误：日志文件 \$LOG_FILE 不存在"
    fi
else
    echo "用法: xiu2 [start|stop|format [log_file]]"
    echo "  start     - 启动 xiu2（默认，无需参数）"
    echo "  stop      - 停止 xiu2"
    echo "  format [log_file] - 格式化日志文件（默认: /root/xiu2.log）"
fi
EOF

cat <<EOF> "/etc/logrotate.d/xiu2"
/root/xiu2.log {
    daily
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

chmod +x /bin/xiu2_start
chmod +x /bin/xiu2

show_status "创建启动脚本 /bin/xiu2_start 和 /bin/xiu2" "success"

# 安装完成提示
ui_print "green" "========================================"
ui_print "green" "✓ 一键安装完成！"
ui_print "green" "您可以使用以下命令："
ui_print "white" "    xiu2              - 启动 xiu2（默认）"
ui_print "white" "    xiu2 stop         - 停止 xiu2"
ui_print "white" "    xiu2 format-log   - 格式化默认日志文件 /root/xiu2.log"
ui_print "white" "    xiu2 format-log /path/to/logfile - 格式化指定的日志文件"
ui_print "green" "启动后，机器人日志将记录在 /root/xiu2.log"
ui_print "green" "========================================"