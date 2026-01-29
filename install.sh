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

# 测试代理可用性和延迟的函数
test_proxy() {
    local proxy_url="$1"
    local target_host="github.com"
    
    # 从代理URL中提取主机名用于ping测试
    local proxy_host=$(echo "$proxy_url" | sed -E 's|^https?://([^/:]+).*|\1|')
    
    # 检查ping命令是否可用
    if ! command -v ping &> /dev/null; then
        ui_print "yellow" "警告: ping命令不可用，跳过网络连通性测试"
        return 0
    fi
    
    local ping_time
    
    # 如果不能直接ping通，尝试ping代理服务器本身
    if ping -c 1 -W 3 "$proxy_host" &> /dev/null; then
        # 计算ping延迟
        ping_time=$(ping -c 1 -W 3 "$proxy_host" | grep 'time=' | sed -E 's/.*time=([0-9.]+).*/\1/')
        
        # 如果没有获取到时间，给一个默认值
        if [[ -z "$ping_time" ]]; then
            ping_time="999"
        fi
        
        echo "$ping_time"
        return 0
    else
        echo "9999"
        return 1
    fi
}

# 获取可用代理列表并按延迟排序
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
    
    echo
    echo
    
    # 过滤出可用的代理并按延迟排序
    local available_proxies=()
    for item in "${proxy_latency[@]}"; do
        latency=$(echo "$item" | cut -d':' -f1)
        proxy=$(echo "$item" | cut -d':' -f2-)
        if (( $(echo "$latency < 999" | bc -l) )); then
            available_proxies+=("$latency:$proxy")
        fi
    done
    
    # 按延迟排序
    IFS=$'\n' sorted_proxies=($(sort -t: -k1 -n <<< "${available_proxies[*]}"))
    unset IFS
    
    if [ ${#sorted_proxies[@]} -eq 0 ]; then
        ui_print "red" "没有找到可用的代理服务器！"
        ui_print "yellow" "建议选择'不使用代理'或'自定义代理'"
        return 1
    else
        ui_print "green" "找到 ${#sorted_proxies[@]} 个可用代理服务器（按延迟排序）："
        for i in "${!sorted_proxies[@]}"; do
            latency=$(echo "${sorted_proxies[$i]}" | cut -d':' -f1)
            proxy=$(echo "${sorted_proxies[$i]}" | cut -d':' -f2-)
            ui_print "cyan" "  $((i+1)). $proxy (延迟: ${latency}ms)"
        done
        echo
        
        # 提取排序后的代理地址
        AVAILABLE_PROXIES=()
        for item in "${sorted_proxies[@]}"; do
            proxy=$(echo "$item" | cut -d':' -f2-)
            AVAILABLE_PROXIES+=("$proxy")
        done
        return 0
    fi
}

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

# 数值比较函数（兼容没有bc的情况）
compare_numbers() {
    local num1=$1
    local operator=$2
    local num2=$3
    
    if command -v bc &> /dev/null; then
        echo "$num1 $operator $num2" | bc -l
    else
        # 使用awk进行比较
        awk "BEGIN {print ($num1 $operator $num2)}"
    fi
}

# 询问用户是否使用代理
get_proxy_choice() {
    ui_print "yellow" "请选择是否使用 Git / 下载代理："
    ui_print "white" "1：自动选择延迟最低的可用代理（默认）"
    ui_print "white" "2：从可用代理中选择特定代理"
    ui_print "white" "3：不使用代理"
    ui_print "white" "4：自定义代理地址"
    echo

    read_or PROXY_CHOICE "请选择代理选项 (1-4)" "1"

    PROXY=""
    case "$PROXY_CHOICE" in
        1)
            check_bc_command
            if get_available_proxies; then
                # 选择延迟最低的代理
                PROXY="${AVAILABLE_PROXIES[0]}"
                latency=$(echo "${sorted_proxies[0]}" | cut -d':' -f1)
                ui_print "green" "✓ 自动选择最低延迟代理：$PROXY (延迟: ${latency}ms)"
            else
                ui_print "yellow" "未找到可用代理，将不使用代理"
            fi
            ;;
        2)
            check_bc_command
            if get_available_proxies; then
                echo
                read_or PROXY_INDEX "请选择代理编号 (1-${#AVAILABLE_PROXIES[@]})" "1"
                if [[ "$PROXY_INDEX" =~ ^[0-9]+$ ]] && [ "$PROXY_INDEX" -ge 1 ] && [ "$PROXY_INDEX" -le ${#AVAILABLE_PROXIES[@]} ]; then
                    PROXY="${AVAILABLE_PROXIES[$((PROXY_INDEX-1))]}"
                    # 显示选中代理的延迟
                    for item in "${sorted_proxies[@]}"; do
                        proxy_addr=$(echo "$item" | cut -d':' -f2-)
                        if [[ "$proxy_addr" == "$PROXY" ]]; then
                            latency=$(echo "$item" | cut -d':' -f1)
                            ui_print "green" "✓ 已选择代理：$PROXY (延迟: ${latency}ms)"
                            break
                        fi
                    done
                else
                    ui_print "red" "无效选择，将不使用代理"
                fi
            else
                ui_print "yellow" "未找到可用代理，将不使用代理"
                ui_print "cyan" "提示: 在Termux/proot环境中，GitHub可能可以直接访问"
            fi
            ;;
        3)
            ui_print "green" "✓ 不使用代理"
            ;;
        4)
            read_or CUSTOM_PROXY "请输入自定义代理地址" ""
            if [[ -n "$CUSTOM_PROXY" ]]; then
                # 测试自定义代理
                ui_print "blue" "正在测试自定义代理..."
                check_bc_command
                latency=$(test_proxy "$CUSTOM_PROXY")
                if (( $(compare_numbers "$latency" "<" "999") )); then
                    PROXY="$CUSTOM_PROXY"
                    ui_print "green" "✓ 自定义代理可用：$PROXY (延迟: ${latency}ms)"
                else
                    ui_print "red" "✗ 自定义代理不可用，将不使用代理"
                fi
            else
                ui_print "yellow" "未输入代理地址，将不使用代理"
            fi
            ;;
        *)
            ui_print "yellow" "无效选择，将不使用代理"
            ;;
    esac
}

# 下载release资源文件（支持代理重试）
download_release_resource() {
    local release_url="$1"
    local download_path="$2"
    local proxy_urls=("$3")  # 改为数组，支持多个代理重试
    
    show_progress "下载release资源文件"
    
    # 如果没有指定代理，则直接尝试下载
    if [[ -z "$proxy_urls" || "$proxy_urls" == " " ]]; then
        ui_print "cyan" "尝试直接下载: $release_url"
        
        if command -v wget &> /dev/null; then
            if wget -O "$download_path" "$release_url"; then
                show_status "下载release资源文件" "success"
                return 0
            fi
        elif command -v curl &> /dev/null; then
            if curl -L -o "$download_path" "$release_url"; then
                show_status "下载release资源文件" "success"
                return 0
            fi
        fi
        
        show_status "下载release资源文件" "failure"
        return 1
    fi
    
    # 如果有多个代理可用，转换为数组
    if [[ "$proxy_urls" != "("*")" ]]; then
        # 单个代理的情况
        local proxy_array=("$proxy_urls")
    else
        # 多个代理的情况（代理重试）
        eval "local proxy_array=${proxy_urls}"
    fi
    
    local success=false
    
    # 尝试所有可用的代理
    for proxy_url in "${proxy_array[@]}"; do
        # 构建下载URL
        if [[ -n "$proxy_url" ]]; then
            download_url="${proxy_url}${release_url}"
        else
            download_url="$release_url"
        fi
        
        ui_print "cyan" "尝试代理下载: $download_url"
        
        # 使用wget或curl下载文件
        if command -v wget &> /dev/null; then
            if wget -O "$download_path" "$download_url"; then
                show_status "下载release资源文件" "success"
                success=true
                break
            else
                ui_print "yellow" "代理 $proxy_url 下载失败，尝试下一个代理..."
                # 删除可能的部分下载文件
                rm -f "$download_path" 2>/dev/null
            fi
        elif command -v curl &> /dev/null; then
            if curl -L -o "$download_path" "$download_url"; then
                show_status "下载release资源文件" "success"
                success=true
                break
            else
                ui_print "yellow" "代理 $proxy_url 下载失败，尝试下一个代理..."
                # 删除可能的部分下载文件
                rm -f "$download_path" 2>/dev/null
            fi
        else
            ui_print "red" "错误: 未找到wget或curl命令"
            return 1
        fi
    done
    
    if $success; then
        return 0
    fi
    
    # 如果所有代理都失败，尝试直接下载
    ui_print "yellow" "所有代理下载失败，尝试直接下载..."
    ui_print "cyan" "直接下载URL: $release_url"
    
    if command -v wget &> /dev/null; then
        if wget -O "$download_path" "$release_url"; then
            show_status "下载release资源文件" "success"
            return 0
        fi
    elif command -v curl &> /dev/null; then
        if curl -L -o "$download_path" "$release_url"; then
            show_status "下载release资源文件" "success"
            return 0
        fi
    fi
    
    show_status "下载release资源文件" "failure"
    return 1
}

# 解压release资源文件
extract_release_resource() {
    local archive_path="$1"
    local extract_dir="$2"
    
    show_progress "解压release资源文件"
    
    # 创建解压目录
    mkdir -p "$extract_dir"
    
    # 根据文件类型解压
    if [[ "$archive_path" == *.tar.gz ]]; then
        if tar -xzf "$archive_path" -C "$extract_dir" --strip-components=1; then
            show_status "解压release资源文件" "success"
            return 0
        fi
    elif [[ "$archive_path" == *.zip ]]; then
        if command -v unzip &> /dev/null; then
            if unzip -q "$archive_path" -d "$extract_dir" && \
               find "$extract_dir" -mindepth 1 -maxdepth 1 -type d -exec mv {}/* "$extract_dir" \; 2>/dev/null && \
               find "$extract_dir" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null; then
                show_status "解压release资源文件" "success"
                return 0
            fi
        else
            ui_print "red" "错误: 未找到unzip命令"
            return 1
        fi
    else
        ui_print "red" "错误: 不支持的压缩格式"
        return 1
    fi
    
    show_status "解压release资源文件" "failure"
    return 1
}

# 解析命令行参数
PROJECT_NAME="xiu2"  # 默认项目名称

# 检查是否传入了项目名称参数
if [ $# -gt 0 ]; then
    PROJECT_NAME="$1"
    ui_print "green" "使用自定义项目名称: $PROJECT_NAME"
else
    ui_print "yellow" "使用默认项目名称: $PROJECT_NAME"
fi

# 检查并创建安装目录
DIR="/root/$PROJECT_NAME"
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
    apt update && apt upgrade -y && apt install -y screen curl wget git python3 python3-pip python3-venv bc tar unzip
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum update -y && yum install -y screen curl wget git python3 python3-pip python3-virtualenv bc tar unzip
elif command -v dnf &> /dev/null; then
    # Fedora
    dnf update -y && dnf install -y screen curl wget git python3 python3-pip python3-virtualenv bc tar unzip
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

cat <<EOF> "$DIR/pyproject.toml"
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

# Release资源下载配置
REPO_OWNER="liyw0205"
REPO_NAME="nonebot_plugin_xiuxian_2_pmv"
RELEASE_TAG="latest"  # 可以使用特定版本标签如 "v1.0.0"
RELEASE_ASSET="project.tar.gz"  # release资源文件名

# 构建release下载URL
if [[ "$RELEASE_TAG" == "latest" ]]; then
    RELEASE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/$RELEASE_ASSET"
else
    RELEASE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$RELEASE_TAG/$RELEASE_ASSET"
fi

TEMP_DOWNLOAD_PATH="$DIR/${REPO_NAME}_${RELEASE_ASSET}"
TEMP_EXTRACT_DIR="$DIR/temp_extract"

# 根据代理选择决定使用单个代理还是所有可用代理
if [[ "$PROXY_CHOICE" == "1" && -n "$PROXY" && -n "${AVAILABLE_PROXIES[*]}" ]]; then
    # 自动选择模式：使用所有可用代理进行重试
    PROXY_FOR_DOWNLOAD="(${AVAILABLE_PROXIES[*]})"
    ui_print "green" "✓ 将按顺序尝试所有可用代理（${#AVAILABLE_PROXIES[@]}个）"
elif [[ -n "$PROXY" ]]; then
    # 单个代理模式
    PROXY_FOR_DOWNLOAD="$PROXY"
else
    # 无代理模式
    PROXY_FOR_DOWNLOAD=""
fi

# 下载release资源文件（支持代理重试）
if ! download_release_resource "$RELEASE_URL" "$TEMP_DOWNLOAD_PATH" "$PROXY_FOR_DOWNLOAD"; then
    ui_print "red" "所有下载方式均失败，请检查网络连接"
    exit 127
fi

# 解压release资源文件
if ! extract_release_resource "$TEMP_DOWNLOAD_PATH" "$TEMP_EXTRACT_DIR"; then
    ui_print "red" "解压失败，请检查文件完整性"
    exit 127
fi

# 移动文件到正确位置
show_progress "移动文件到安装目录"

# 检查解压后的目录结构并移动文件
if [[ -d "$TEMP_EXTRACT_DIR/nonebot_plugin_xiuxian_2" ]]; then
    # 标准release结构
    mv "$TEMP_EXTRACT_DIR/nonebot_plugin_xiuxian_2" "$DIR/src/plugins/" || {
        show_status "移动插件文件" "failure"
        exit 127
    }
    show_status "移动插件文件" "success"
    
    if [[ -d "$TEMP_EXTRACT_DIR/data" ]]; then
        mv "$TEMP_EXTRACT_DIR/data" "$DIR/" || {
            show_status "移动data目录" "failure"
            exit 127
        }
        show_status "移动data目录" "success"
    fi
    
    if [[ -f "$TEMP_EXTRACT_DIR/requirements.txt" ]]; then
        mv "$TEMP_EXTRACT_DIR/requirements.txt" "$DIR/" || {
            show_status "移动requirements.txt" "failure"
            exit 127
        }
        show_status "移动requirements.txt" "success"
    fi
fi

# 清理临时文件
rm -rf "$TEMP_DOWNLOAD_PATH" "$TEMP_EXTRACT_DIR" > /dev/null 2>&1
show_status "清理临时文件" "success"

# 创建 Python 虚拟环境并安装依赖
show_progress "创建 Python 虚拟环境 myenv"
python3 -m venv "$PWD"/myenv > /dev/null 2>&1
if [ $? -eq 0 ]; then
    show_status "创建 Python 虚拟环境 myenv" "success"
else
    show_status "创建 Python 虚拟环境 myenv" "failure"
    exit 127
fi


# 创建启动脚本
cat <<EOF> "/bin/${PROJECT_NAME}_start"
export TZ=Asia/Shanghai
source "$PWD"/myenv/bin/activate
cd $DIR
nb run --reload
EOF

source "$PWD"/myenv/bin/activate > /dev/null 2>&1
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
pip install nb-cli==1.5.0
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

# 用户输入配置信息
show_progress "获取用户配置信息"
read_or SUPERUSERS "请输入主人QQ号（SUPERUSERS）" "123456"
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

show_status "生成配置信息" "success"

# 创建启动脚本和格式化日志功能
cat <<EOF> "/bin/$PROJECT_NAME"
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
    echo "用法: $PROJECT_NAME [start|stop|status|format [log_file]]"
    echo "  start     - 启动 $PROJECT_NAME"
    echo "  stop      - 停止 $PROJECT_NAME"
    echo "  status     - 查看 $PROJECT_NAME"
        echo "  format [log_file] - 格式化日志文件（默认: "$DIR"/${PROJECT_NAME}.log）"
elif [ "\$#" -eq 1 ]; then
    if [ "\$1" = "start" ]; then
        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            echo "$PROJECT_NAME已在后台运行"
            echo "   您可以查看现有会话："
            echo "       screen -r $PROJECT_NAME"
            echo "   或查看日志："
            echo "       tail -f "$DIR"/${PROJECT_NAME}.log"
        else
            echo "正在后台启动$PROJECT_NAME..."
            screen -U -dmS $PROJECT_NAME -L -Logfile "$DIR"/${PROJECT_NAME}.log bash -c '${PROJECT_NAME}_start'
            echo "已后台启动，通过以下命令查看当前状态："
            echo "       screen -r $PROJECT_NAME"
            echo "   或查看日志："
            echo "       tail -f "$DIR"/${PROJECT_NAME}.log"
        fi
    elif [ "\$1" = "stop" ]; then
        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            echo "正在停止$PROJECT_NAME..."
            screen -X -S $PROJECT_NAME quit
            echo "$PROJECT_NAME已停止"
        else
            echo "$PROJECT_NAME未在运行"
        fi
    elif [ "\$1" = "status" ]; then
        if screen -list | grep -q "\b$PROJECT_NAME\b"; then
            screen -U -r $PROJECT_NAME
        else
            echo "$PROJECT_NAME未在运行"
        fi        
    elif [ "\$1" = "format" ]; then
        LOG_FILE="$DIR/${PROJECT_NAME}.log"
        if [ -f "\$LOG_FILE" ]; then
            formatlog "\$LOG_FILE"
        else
            echo "错误：日志文件 \$LOG_FILE 不存在"
        fi
    else
        echo "用法: $PROJECT_NAME [start|stop|status|format [log_file]]"
        echo "  start     - 启动 $PROJECT_NAME"
        echo "  stop      - 停止 $PROJECT_NAME"
        echo "  format [log_file] - 格式化日志文件（默认: "$DIR"/${PROJECT_NAME}.log）"
    fi
elif [ "\$#" -eq 2 ] && [ "\$1" = "format" ]; then
    LOG_FILE="\$2"
    if [ -f "\$LOG_FILE" ]; then
        formatlog "\$LOG_FILE"
    else
        echo "错误：日志文件 \$LOG_FILE 不存在"
    fi
else
    echo "用法: $PROJECT_NAME [start|stop|status|format [log_file]]"
    echo "  start     - 启动 $PROJECT_NAME"
    echo "  stop      - 停止 $PROJECT_NAME"
    echo "  status     - 查看 $PROJECT_NAME"
    echo "  format [log_file] - 格式化日志文件（默认: "$DIR"/${PROJECT_NAME}.log）"
fi
EOF

cat <<EOF> "/etc/logrotate.d/$PROJECT_NAME"
"$DIR"/${PROJECT_NAME}.log {
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

chmod +x /bin/${PROJECT_NAME}_start
chmod +x /bin/$PROJECT_NAME

show_status "创建启动脚本 /bin/${PROJECT_NAME}_start 和 /bin/$PROJECT_NAME" "success"

# 获取公网IPv4地址
IPV4=$(curl -s ifconfig.me 2> /dev/null)

# 安装完成提示
ui_print "green" "========================================"
ui_print "green" "✓ 一键安装完成！"
ui_print "green" "项目名称: $PROJECT_NAME"
ui_print "green" "安装目录: $DIR"
ui_print "green" "OneBot V11 协议地址"
ui_print "white" "    ws://${IPV4}:${PORT}/onebot/v11/ws"
ui_print "white" "    ws://127.0.0.1:${PORT}/onebot/v11/ws"
ui_print "green" "您可以使用以下命令："
ui_print "white" "    $PROJECT_NAME              - 启动 $PROJECT_NAME（默认）"
ui_print "white" "    $PROJECT_NAME stop         - 停止 $PROJECT_NAME"
ui_print "white" "    $PROJECT_NAME status       - 查看 $PROJECT_NAME"
ui_print "white" "    $PROJECT_NAME format      - 格式化默认日志文件 "$DIR"/${PROJECT_NAME}.log"
ui_print "white" "    $PROJECT_NAME format /path/to/logfile - 格式化指定的日志文件"
ui_print "green" "启动后，机器人日志将记录在 "$DIR"/${PROJECT_NAME}.log"
ui_print "green" "========================================"
