#!/bin/bash

# ==========================================
# Author: TechShare-白
# Date:   2026年4月
# Description: Inspire FTP Hand 检品程序
# ==========================================

set -e

echo "[0] 正在检查系统组件..."
# 检查是否安装了创建虚拟环境所需的 python3-venv
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    echo "[信息] 未找到创建虚拟环境所需的 'python3-venv'。"
    echo "[执行] 正在安装系统组件（可能需要输入密码）..."
    sudo apt update && sudo apt install -y python3-venv
else
    echo "[OK] python3-venv 已安装。"
fi

# --- 阶段 1: 环境构建 (仅在目录不存在时执行) ---
TARGET_DIR="$HOME/inspire_kenpin"
WS_DIR="$TARGET_DIR/inspire_hand_ws"

if [ ! -d "$TARGET_DIR" ]; then
    echo "[信息] 正在创建目标根目录..."
    mkdir -p "$TARGET_DIR"
fi
cd "$TARGET_DIR"

if [ ! -d "$WS_DIR" ]; then
    echo "[1/5] 正在克隆代码仓库..."
    git clone https://github.com/NaCl-1374/inspire_hand_ws.git
    cd "$WS_DIR"

    echo "[2/5] 正在创建全新的虚拟环境..."
    python3 -m venv .venv
    source .venv/bin/activate

    echo "[3/5] 正在更新 pip..."
    python3 -m pip install --upgrade pip

    echo "[4/5] 正在更新 Git 子模块..."
    git submodule init
    git submodule update

    echo "[5/5] 正在安装各类 SDK..."
    python3 -m pip install -e unitree_sdk2_python
    python3 -m pip install -e inspire_hand_sdk

    echo "[完成] 环境构建已顺利结束。"
fi

# --- 阶段 2: 执行检品流程 ---
echo ""
echo "------------------------------------------"
echo "    开始执行检品流程"
echo "------------------------------------------"

cd "$WS_DIR"
source .venv/bin/activate || { echo "虚拟环境激活失败"; exit 1; }

echo "[执行] 正在启动可视化驱动 (Vision_driver)..."
python3 inspire_hand_sdk/example/Vision_driver_double.py &
DRIVER_PID=$!

sleep 2
echo ""
echo ">>> 第一步：压力检测"
echo ">>> 请按压 inspire_frp 的手指和手掌，观察窗口中的数值变化。"
echo ">>> 确认无误后，按 [回车键] 自动开始电机检测。"
read -p ""


echo "[执行] 正在启动电机检测 (dds_publish)..."
python3 inspire_hand_sdk/example/dds_publish.py &
PUBLISH_PID=$!

echo ""
echo ">>> 第二步：电机检测"
echo ">>> 电机检测程序正在运行，请观察手掌动作。"
echo ">>> 检测完成后，按 [回车键] 将关闭所有窗口并结束程序。"
read -p ""


echo "[清理] 正在关闭所有相关进程..."
kill $DRIVER_PID $PUBLISH_PID 2>/dev/null || true
pkill -9 -f "Vision_driver_double.py" || true
pkill -9 -f "dds_publish.py" || true

echo "=========================================="
echo "    检品已完成。辛苦了！"
echo "=========================================="