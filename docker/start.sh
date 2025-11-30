#!/bin/bash
# OCR服务启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Expense Tracker - OCR Service ==="

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not installed"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 创建uploads目录
mkdir -p uploads

# 构建并启动OCR服务
echo "Building OCR service..."
docker compose build ocr

echo "Starting OCR service..."
docker compose up -d ocr

# 等待服务启动
echo "Waiting for service to start..."
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo ""
        echo "=== OCR Service Started ==="
        echo "- API: http://localhost:8000"
        echo "- API Docs: http://localhost:8000/docs"
        echo "- Health: http://localhost:8000/health"
        echo ""
        echo "Test command:"
        echo "  curl -X POST http://localhost:8000/image/parse -F 'file=@test.jpg'"
        echo ""
        echo "View logs: docker compose logs -f ocr"
        exit 0
    fi
    sleep 1
    echo -n "."
done

echo ""
echo "Warning: Service may not be ready yet"
echo "Check logs: docker compose logs ocr"
