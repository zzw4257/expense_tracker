#!/bin/bash
# MinerU OCR服务启动脚本

set -e

echo "=== Expense Tracker - MinerU OCR Service ==="

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not installed"
    exit 1
fi

# 检查GPU
if command -v nvidia-smi &> /dev/null; then
    echo "GPU detected, starting with GPU support..."
    docker compose up -d mineru
else
    echo "No GPU detected, starting CPU-only mode..."
    docker compose --profile cpu-only up -d mineru-cpu
fi

echo ""
echo "Services started!"
echo "- API: http://localhost:8000"
echo "- API Docs: http://localhost:8000/docs"
echo "- WebUI: http://localhost:7860"
echo ""
echo "Check logs: docker compose logs -f"
