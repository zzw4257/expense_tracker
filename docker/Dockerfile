# MinerU OCR Service Dockerfile
# 基于官方vLLM镜像，支持GPU加速

FROM vllm/vllm-openai:v0.10.2

LABEL maintainer="expense-tracker"
LABEL description="MinerU OCR Service for Expense Tracker"

# 设置环境变量
ENV MINERU_MODEL_SOURCE=modelscope
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装MinerU
RUN pip install --no-cache-dir mineru

# 下载模型（构建时下载，加快启动速度）
RUN mineru-models-download || true

# 创建工作目录
WORKDIR /app

# 暴露端口
EXPOSE 8000 7860

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 默认启动API服务
CMD ["mineru-api", "--host", "0.0.0.0", "--port", "8000"]
