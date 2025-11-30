#!/bin/bash
# MinerU OCR服务安装脚本
# 支持 macOS / Linux

set -e

echo "=== MinerU OCR 安装脚本 ==="

# 检查Python版本
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python版本: $PYTHON_VERSION"

# 创建虚拟环境
VENV_DIR="$HOME/.mineru_venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "创建虚拟环境..."
    python3 -m venv "$VENV_DIR"
fi

# 激活虚拟环境
source "$VENV_DIR/bin/activate"

# 升级pip
pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple

# 安装MinerU（使用清华源）
echo "安装MinerU..."
pip install magic-pdf[full] -i https://pypi.tuna.tsinghua.edu.cn/simple

# 设置模型源为ModelScope（国内）
export MINERU_MODEL_SOURCE=modelscope

# 下载模型
echo "下载模型（可能需要较长时间）..."
mineru-models-download || echo "模型下载失败，请手动运行: mineru-models-download"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "启动API服务:"
echo "  source $VENV_DIR/bin/activate"
echo "  mineru-api --host 0.0.0.0 --port 8000"
echo ""
echo "启动WebUI:"
echo "  source $VENV_DIR/bin/activate"
echo "  mineru-gradio --server-name 0.0.0.0 --server-port 7860"
