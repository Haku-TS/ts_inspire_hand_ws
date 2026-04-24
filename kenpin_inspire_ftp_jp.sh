#!/bin/bash

# ==========================================
# Author: TechShare-白 
# Date:   2026年4月
# Description: Inspire FTP Hand 検品用プログラム
# ==========================================

set -e

echo "[0] 系统组件检查中..."
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    echo "[情報] 仮想環境の作成に必要な 'python3-venv' が見つかりません。"
    echo "[実行] システムコンポーネントをインストールします（パスワードが必要な場合があります）..."
    sudo apt update && sudo apt install -y python3-venv
else
    echo "[OK] python3-venv は既にインストールされています。"
fi

# --- フェーズ 1: 環境構築 (存在しない場合のみ実行) ---
TARGET_DIR="$HOME/inspire_kenpin"
WS_DIR="$TARGET_DIR/ts_inspire_hand_ws"

if [ ! -d "$TARGET_DIR" ]; then
    echo "[情報] フォルダ構築を開始します..."
    mkdir -p "$TARGET_DIR"
fi
cd "$TARGET_DIR"

if [ ! -d "$WS_DIR" ]; then
    echo "[1/5] リポジトリをクローン中..."
    git clone https://github.com/Haku-TS/ts_inspire_hand_ws.git
    cd "$WS_DIR"

    echo "[2/5] 仮想環境を新規作成中..."
    python3 -m venv .venv
    source .venv/bin/activate

    echo "[3/5] pip を更新中..."
    python3 -m pip install --upgrade pip

    echo "[4/5] Git サブモジュールを更新中..."
    git submodule init
    git submodule update

    echo "[5/5] 各種 SDK のインストール中..."
    python3 -m pip install -e unitree_sdk2_python
    python3 -m pip install -e inspire_hand_sdk

    echo "[完了] 環境構築が正常に終了しました。"
fi

# --- フェーズ 2: 検品実行 ---
echo ""
echo "------------------------------------------"
echo "   検品プロセス を実行します"
echo "------------------------------------------"

cd "$WS_DIR"
source .venv/bin/activate || { echo "虚拟环境激活失败"; exit 1; }

echo "[実行] Vision_driver.py を起動しています..."
python3 inspire_hand_sdk/example/Vision_driver_double.py &
DRIVER_PID=$!

sleep 2
echo ""
echo ">>> 開始圧力検出：inspire_frpの手指と手掌を押し、ウィンドウの表示を確認してください。"
echo ">>> 確認完了後、[Enter] キーを押すと自動的にモータ検出を開始します。"
read -p ""


echo "[実行]  モータ検出（dds_publish.py）を実行します..."
python3 inspire_hand_sdk/example/dds_publish.py&
PUBLISH_PID=$!

echo ""
echo ">>> モータ検出プログラムが実行中です。"
echo ">>> [Enter] キーを押すと、全てのウィンドウを閉じてプログラムを終了します。"
read -p ""


echo "[終了] プロセスを終了しています..."
kill $DRIVER_PID $PUBLISH_PID 2>/dev/null || true
pkill -9 -f "Vision_driver_double.py" || true
pkill -9 -f "dds_publish.py" || true

echo "=========================================="
echo "   検品が完了しました。お疲れ様でした。"
echo "=========================================="