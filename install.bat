@echo off
mode con cols=80 lines=25
chcp 65001 >nul

setlocal EnableDelayedExpansion
set "LINE========================================="

title xiuxian
set "PORT=8080"
set "DIR=C:\nb"
mkdir "%DIR%" 2>nul

:zhuye
cls
color 3f
echo %LINE%
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do set IP=%%a
echo WLAN/IP 地址: %IP:~1%
echo 项目地址：https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv
echo OneBot V11 协议地址：
echo     ws://127.0.0.1:%PORT%/onebot/v11/ws
echo %LINE%
echo A.启动  B.安装  C.重装  D.更新
echo %LINE%

set choice=
set /p choice=请输入对应字母后回车:
cls
if /i "%choice%"=="A" (
    color 07
    cd /d "%DIR%"
    call myenv\Scripts\activate
    cd /d "%DIR%\xiu2"
    nb run --reload
    goto zhuye
)

if /i "%choice%"=="B" (
    goto install
)

if /i "%choice%"=="C" (
    goto uninstall
)

if /i "%choice%"=="D" (
    goto update
)

echo 输入错误，请重新选择！
echo %LINE%
echo 请按任意键继续...
pause > nul
goto zhuye

:install
goto check

:check
cls
echo %LINE%
echo 正在检测 Python 环境...
echo %LINE%

set "PYTHON_INSTALLED="
set "PYTHON_MAJOR="
set "PYTHON_MINOR="

for /f "tokens=1,2" %%i in ('python -c "import sys; print(sys.version_info.major, sys.version_info.minor)" 2^>nul') do (
    set "PYTHON_MAJOR=%%i"
    set "PYTHON_MINOR=%%j"
    set "PYTHON_INSTALLED=true"
)
if "%PYTHON_INSTALLED%"=="true" goto install_project

echo 未检测到 Python。将尝试安装 Python 3.11.0。
set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe"
set "PYTHON_INSTALLER_PATH=%DIR%\python-3.11.0-amd64.exe"

if exist "%cd%\python-3.11.0-amd64.exe" (
    echo 当前路径存在 python-3.11.0-amd64.exe ... 已移动到 %DIR%\python-3.11.0-amd64.exe
    move "%cd%\python-3.11.0-amd64.exe" "%DIR%\python-3.11.0-amd64.exe"
)

if not exist "%PYTHON_INSTALLER_PATH%" (
    echo 下载地址: %PYTHON_INSTALLER_URL%
    echo 正在下载 Python 3.11.0 安装包...
    powershell -Command "Invoke-WebRequest -Uri '%PYTHON_INSTALLER_URL%' -OutFile '%PYTHON_INSTALLER_PATH%' -UseBasicParsing"
)
echo 正在安装 Python 3.11.0 (静默安装，请稍候)...
echo 这可能需要几分钟，请耐心等待，期间可能没有提示。
start /wait "" "%PYTHON_INSTALLER_PATH%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
echo %LINE%
echo 请按任意键退出，重新打开脚本来加载环境...
pause > nul
start "" "%~dpnx0"
exit

:install_project
cls
echo %LINE%
echo          开始安装 Xiu2 项目
echo %LINE%

rmdir /s /q "%DIR%\tmp" 2>nul
mkdir "%DIR%\tmp" 2>nul

echo. 请选择下载代理方式
echo. 1.使用代理：https://gh.llkk.cc/
echo. 2.使用代理：https://github.dpik.top/
echo. 3.使用代理：https://git.yylx.win/
echo. 4.使用代理：https://ghfile.geekertao.top/
echo. 按任意键不使用代理 可能速度慢或失败
echo %LINE%
set /p proxy_choice=请输入序号选择代理:

set "proxy="
if /i "%proxy_choice%"=="1" set "proxy=https://gh.llkk.cc/"
if /i "%proxy_choice%"=="2" set "proxy=https://github.dpik.top/"
if /i "%proxy_choice%"=="3" set "proxy=https://git.yylx.win/"
if /i "%proxy_choice%"=="4" set "proxy=https://ghfile.geekertao.top/"

set "download_url=https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/releases/latest/download/project.tar.gz"

if exist "%cd%\project.tar.gz" (
    echo 当前路径存在 project.tar.gz ... 已移动到 %DIR%\project.tar.gz
    move "%cd%\project.tar.gz" "%DIR%\project.tar.gz"
)

echo [1/7] 检测 project.tar.gz ...
if not exist "%DIR%\project.tar.gz" (
    echo [1/7] 正在下载 project.tar.gz ...
    echo 下载地址: %proxy%%download_url%
    powershell -Command "Invoke-WebRequest -Uri '%proxy%%download_url%' -OutFile '%DIR%\project.tar.gz' -UseBasicParsing"
    if errorlevel 1 (
        echo 下载失败！请检查网络或代理。
        echo %LINE%
        echo 请按任意键继续...
        pause > nul
        exit /b 1
    )
)

echo [2/7] 创建项目结构和 pyproject.toml ...
mkdir "%DIR%\xiu2\src\plugins" 2>nul
mkdir "%DIR%\xiu2\data" 2>nul

(
echo [project]
echo name = "xiu2"
echo version = "0.1.0"
echo description = "xiu2"
echo readme = "README.md"
echo requires-python = ">=3.9, ^<4.0"
echo dependencies = [
echo     "nonebot2[fastapi]>=2.4.4",
echo     "nonebot2[httpx]>=2.4.4",
echo     "nonebot2[websockets]>=2.4.4",
echo     "nonebot2[aiohttp]>=2.4.4",
echo     "nonebot-adapter-onebot>=2.4.6"
echo ]
echo.
echo [project.optional-dependencies]
echo dev = []
echo.
echo [tool.nonebot]
echo plugin_dirs = ["src/plugins"]
echo builtin_plugins = []
echo.
echo [tool.nonebot.adapters]
echo nonebot-adapter-onebot = [
echo     { name = "OneBot V11", module_name = "nonebot.adapters.onebot.v11" }
echo ]
echo "@local" = []
echo.
echo [tool.nonebot.plugins]
echo "@local" = []
) > "%DIR%\xiu2\pyproject.toml"

echo [3/7] 解压 project.tar.gz ...
python -c "import tarfile; tf = tarfile.open(r'%DIR%\project.tar.gz', 'r:gz'); tf.extractall(r'%DIR%\tmp'); tf.close(); print('解压完成')" || (
    echo Python 解压失败！
    echo 请检查文件/重新下载/删除 %DIR%\project.tar.gz
    echo %LINE%
    echo 请按任意键继续...
    pause > nul
    exit /b 1
)
move "%DIR%\tmp\data\xiuxian" "%DIR%\xiu2\data"
move "%DIR%\tmp\nonebot_plugin_xiuxian_2" "%DIR%\xiu2\src\plugins"

echo [4/7] 创建虚拟环境 ...
python -m venv "%DIR%\myenv"

echo [5/7] 安装依赖（使用清华镜像）...
cd /d "%DIR%"
call myenv\Scripts\activate

python -m pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
python -m pip install --upgrade pip
pip install nb-cli==1.5.0

cd /d "%DIR%\xiu2"
pip install wget
pip install numpy
pip install ujson
pip install Pillow
pip install wcwidth
pip install pathlib
pip install asyncio
pip install aiohttp
pip install pydantic
pip install aiofiles
pip install flask
pip install requests
pip install nonebot_plugin_apscheduler

nb driver install fastapi
nb driver install httpx
nb driver install websockets
nb adapter install onebot.v11

echo [6/7] 创建配置文件 ...
(
echo ENVIRONMENT=dev
echo DRIVER=~fastapi+~httpx+~websockets+~aiohttp
) > "%DIR%\xiu2\.env"

(
echo LOG_LEVEL=INFO
echo.
echo SUPERUSERS = ["123456"]
echo COMMAND_START = [""]
echo NICKNAME = ["堂堂"]
echo DEBUG = False
echo HOST = 0.0.0.0
echo PORT = %PORT%
) > "%DIR%\xiu2\.env.dev"

echo [7/7] 获取本机IP并显示启动信息 ...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do set IPV4=%%a
set IPV4=%IPV4:~1%

(
echo color 07
echo cd /d %DIR%
echo call myenv\Scripts\activate
echo cd /d %DIR%\xiu2
echo nb run --reload
) > "%DIR%\启动修仙.bat"

echo.
echo %LINE%
echo 安装完成！
echo 项目名称: xiu2
echo 安装目录: %DIR%\xiu2
echo.
echo OneBot V11 协议地址：
echo     ws://%IPV4%:%PORT%/onebot/v11/ws
echo     ws://127.0.0.1:%PORT%/onebot/v11/ws
echo %LINE%

rmdir /s /q "%DIR%\tmp" 2>nul
call "%DIR%\启动修仙.bat"
echo 已尝试启动修仙
echo 注意：当前是默认配置，如需修改配置：%DIR%\xiu2\.env.dev
echo %LINE%
echo 请按任意键继续...
pause > nul
goto zhuye

:update
cls
echo %LINE%
echo            开始更新 Xiu2 项目
echo %LINE%

:: 若项目不存在，则自动进入安装
if not exist "%DIR%\xiu2" (
    echo 未检测到项目目录：%DIR%\xiu2
    echo 将自动进入安装流程...
    timeout /t 2 >nul
    goto install
)

:: 准备临时目录
rmdir /s /q "%DIR%\tmp" 2>nul
mkdir "%DIR%\tmp" 2>nul

echo. 请选择下载代理方式
echo. 1.使用代理：https://gh.llkk.cc/
echo. 2.使用代理：https://github.dpik.top/
echo. 3.使用代理：https://git.yylx.win/
echo. 4.使用代理：https://ghfile.geekertao.top/
echo. 按任意键不使用代理 可能速度慢或失败
echo %LINE%
set /p proxy_choice=请输入序号选择代理:

set "proxy="
if /i "%proxy_choice%"=="1" set "proxy=https://gh.llkk.cc/"
if /i "%proxy_choice%"=="2" set "proxy=https://github.dpik.top/"
if /i "%proxy_choice%"=="3" set "proxy=https://git.yylx.win/"
if /i "%proxy_choice%"=="4" set "proxy=https://ghfile.geekertao.top/"

set "download_url=https://github.com/liyw0205/nonebot_plugin_xiuxian_2_pmv/releases/latest/download/project.tar.gz"

:: 更新时强制重新下载最新包
if exist "%DIR%\project.tar.gz" del /f /q "%DIR%\project.tar.gz" >nul 2>nul

echo [1/5] 下载最新 project.tar.gz ...
echo 下载地址: %proxy%%download_url%
powershell -Command "Invoke-WebRequest -Uri '%proxy%%download_url%' -OutFile '%DIR%\project.tar.gz' -UseBasicParsing"
if errorlevel 1 (
    echo 下载失败！请检查网络或代理。
    echo %LINE%
    echo 请按任意键继续...
    pause > nul
    goto zhuye
)

echo [2/5] 解压更新包 ...
python -c "import tarfile; tf = tarfile.open(r'%DIR%\project.tar.gz', 'r:gz'); tf.extractall(r'%DIR%\tmp'); tf.close(); print('解压完成')" || (
    echo Python 解压失败！
    echo %LINE%
    echo 请按任意键继续...
    pause > nul
    goto zhuye
)

echo [3/5] 覆盖插件与数据 ...
:: 仅替换插件和数据，保留用户配置与虚拟环境
rmdir /s /q "%DIR%\xiu2\src\plugins\nonebot_plugin_xiuxian_2" 2>nul
rmdir /s /q "%DIR%\xiu2\data\xiuxian" 2>nul

move "%DIR%\tmp\nonebot_plugin_xiuxian_2" "%DIR%\xiu2\src\plugins\" >nul
move "%DIR%\tmp\data\xiuxian" "%DIR%\xiu2\data\" >nul

echo [4/5] 更新依赖（按需）...
cd /d "%DIR%"
if exist "%DIR%\myenv\Scripts\activate" (
    call myenv\Scripts\activate
    cd /d "%DIR%\xiu2"
    pip install -U nonebot_plugin_apscheduler >nul 2>nul
)

echo [5/5] 清理临时文件 ...
rmdir /s /q "%DIR%\tmp" 2>nul

echo.
echo %LINE%
echo 更新完成！
echo 如更新后无法启动，可尝试执行“C.重装”。
echo %LINE%
echo 请按任意键继续...
pause >nul
goto zhuye

:uninstall
echo %LINE%
echo A.确认重装（这会删除数据）  B.取消
echo %LINE%

set choice=
set /p choice=请输入对应字母后回车:
cls
if /i "%choice%"=="A" (
    rmdir /s /q "%DIR%\tmp" 2>nul
    rmdir /s /q "%DIR%\myenv" 2>nul
    rmdir /s /q "%DIR%\xiu2" 2>nul
    goto install
)
goto zhuye