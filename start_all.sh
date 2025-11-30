#!/bin/bash
# 一键启动所有服务

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Expense Tracker - 启动所有服务 ==="

# 检查conda
if ! command -v conda &> /dev/null; then
    echo "Error: conda not found"
    exit 1
fi

# 初始化conda
CONDA_BASE=$(conda info --base)
source "$CONDA_BASE/etc/profile.d/conda.sh"

# 检查expense_ocr环境
if ! conda env list | grep -q "expense_ocr"; then
    echo "Creating conda environment..."
    conda create -n expense_ocr python=3.10 -y
    conda activate expense_ocr
    pip install paddlepaddle paddleocr fastapi uvicorn python-multipart pdf2image Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple
else
    conda activate expense_ocr
fi

# 停止已有服务
echo "Stopping existing services..."
pkill -f "uvicorn ocr_server" 2>/dev/null || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
sleep 1

# 启动OCR服务
echo "Starting OCR service on port 8000..."
cd docker
nohup python ocr_server.py > ../logs/ocr.log 2>&1 &
OCR_PID=$!
cd ..

# 等待OCR服务启动
echo -n "Waiting for OCR service"
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo " OK"
        break
    fi
    echo -n "."
    sleep 1
done

# 检查OCR服务
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo " FAILED"
    echo "OCR service failed to start. Check logs/ocr.log"
    exit 1
fi

# 启动Flutter Web
echo "Starting Flutter Web on port 8080..."
mkdir -p logs
nohup flutter run -d chrome --web-port=8080 > logs/flutter.log 2>&1 &
FLUTTER_PID=$!

echo ""
echo "=== Services Started ==="
echo "- OCR API: http://localhost:8000"
echo "- OCR Docs: http://localhost:8000/docs"
echo "- Flutter Web: http://localhost:8080"
echo ""
echo "Logs:"
echo "- OCR: logs/ocr.log"
echo "- Flutter: logs/flutter.log"
echo ""
echo "Stop all: pkill -f 'uvicorn ocr_server'; pkill -f 'flutter run'"
