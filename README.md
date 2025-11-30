# Expense Tracker 报销管理系统

跨平台报销管理应用，支持 Web、Android、iOS。

## 功能

- **报销记录管理** - 创建、编辑、删除报销记录
- **智能凭证解析** - 自动OCR识别发票内容（MinerU）
- **AI摘要** - 支持GPT-5.1/Gemini/Ollama自动分析
- **税号验证** - 统一社会信用代码校验
- **自动聚类** - 相似记录合并建议
- **数据分析** - 类别分布、月度趋势图表
- **数据导出** - CSV/JSON格式导出

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter 3.x |
| 状态管理 | Provider |
| OCR | MinerU (Docker) |
| AI | OpenAI / Gemini / Ollama |
| 后端 | Vercel Serverless |
| 部署 | Docker + Vercel |

## 快速开始

### 1. 启动OCR服务（Docker）

```bash
cd docker
./start.sh
```

或手动启动：
```bash
# GPU版本
docker compose up -d mineru

# CPU版本
docker compose --profile cpu-only up -d mineru-cpu
```

服务地址：
- API: http://localhost:8000
- API文档: http://localhost:8000/docs
- WebUI: http://localhost:7860

### 2. 运行Flutter应用

```bash
flutter pub get
flutter run -d chrome
```

## 构建

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 项目结构

```
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── expense.dart      # 报销/凭证模型
│   │   └── settings.dart     # 应用设置
│   ├── providers/
│   ├── screens/
│   ├── services/
│   │   ├── ai_service.dart   # AI摘要服务
│   │   ├── ocr_service.dart  # OCR解析服务
│   │   └── cluster_service.dart
│   ├── theme/
│   └── widgets/
├── api/                      # Vercel Serverless
│   ├── expenses.js
│   ├── validate-tax.js
│   └── ocr/mineru.js
└── docker/                   # Docker配置
    ├── Dockerfile
    ├── docker-compose.yml
    └── start.sh
```

## MinerU配置

环境变量：
```bash
# 国内用户（推荐）
export MINERU_MODEL_SOURCE=modelscope

# 海外用户
export MINERU_MODEL_SOURCE=huggingface
```

本地安装：
```bash
pip install mineru
mineru-models-download
mineru-api --host 0.0.0.0 --port 8000
```

## UI风格

Neon渐变 + 深色背景 + JetBrains Mono字体
