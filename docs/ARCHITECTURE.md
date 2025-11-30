# Expense Tracker 技术架构文档

## 系统概览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           用户设备 (Web/Mobile)                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Flutter 应用 (跨平台)                         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │   │
│  │  │ 首页     │  │ 添加报销 │  │ 数据分析 │  │ 设置     │        │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              服务层                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │  OCR 服务       │  │  AI 服务        │  │  Vercel API     │         │
│  │  (PaddleOCR)    │  │  (GPT/Gemini)   │  │  (Serverless)   │         │
│  │  localhost:8000 │  │  外部API        │  │  /api/*         │         │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 核心模块

### 1. 前端 (Flutter)

```
lib/
├── main.dart                 # 应用入口
├── models/
│   ├── expense.dart          # 报销记录模型
│   └── settings.dart         # 应用设置模型
├── providers/
│   └── expense_provider.dart # 状态管理
├── screens/
│   ├── home_screen.dart      # 首页：报销列表
│   ├── add_expense_screen.dart # 添加/编辑报销
│   ├── analytics_screen.dart # 数据分析
│   └── settings_screen.dart  # 设置页面
├── services/
│   ├── ocr_service.dart      # OCR服务客户端
│   ├── ai_service.dart       # AI服务客户端
│   └── cluster_service.dart  # 聚类服务
├── theme/
│   └── neon_theme.dart       # 主题配置
└── widgets/
    └── neon_widgets.dart     # 自定义组件
```

### 2. OCR服务 (PaddleOCR)

```
docker/
├── ocr_server.py             # FastAPI服务
├── Dockerfile.ocr            # Docker镜像
├── docker-compose.yml        # 容器编排
└── start.sh                  # 启动脚本
```

### 3. 后端API (Vercel Serverless)

```
api/
├── expenses.js               # 报销CRUD
├── validate-tax.js           # 税号验证
└── ocr/
    └── mineru.js             # MinerU代理
```

---

## OCR处理流程

### 用户视角

```
1. 用户点击"上传凭证"
       │
       ▼
2. 选择文件 (PDF/图片)
       │
       ▼
3. 显示"解析中..."
       │
       ▼
4. 自动识别文档类型
   ├── 发票 → 显示绿色标签
   ├── 收据 → 显示蓝色标签
   └── 其他 → 显示黄色标签
       │
       ▼
5. 显示解析结果摘要
       │
       ▼
6. 用户确认/编辑信息
       │
       ▼
7. 保存报销记录
```

### 服务器视角

```
┌─────────────────────────────────────────────────────────────────────┐
│                        OCR处理流程                                   │
└─────────────────────────────────────────────────────────────────────┘

1. 接收请求
   POST /pdf/parse
   Content-Type: multipart/form-data
   Body: file=<PDF/Image>

2. 文件类型判断
   ┌─────────────────┐
   │ 检查文件扩展名  │
   └────────┬────────┘
            │
   ┌────────┴────────┐
   │                 │
   ▼                 ▼
 PDF              图片
   │                 │
   ▼                 ▼
┌─────────┐    ┌─────────┐
│pdf2image│    │ 直接    │
│转换为PNG│    │ 处理    │
└────┬────┘    └────┬────┘
     │              │
     └──────┬───────┘
            ▼
3. PaddleOCR识别
   ┌─────────────────────────────────────┐
   │ PaddleOCR.predict(image_path)       │
   │                                     │
   │ 模型链:                             │
   │ ├── PP-LCNet_x1_0_doc_ori (文档方向)│
   │ ├── UVDoc (文档增强)                │
   │ ├── PP-OCRv5_server_det (文字检测)  │
   │ └── PP-OCRv5_server_rec (文字识别)  │
   └────────────────┬────────────────────┘
                    │
                    ▼
4. 结果解析
   {
     "rec_texts": ["Invoice", "Amount", ...],
     "rec_scores": [0.99, 0.98, ...],
     "rec_boxes": [[x1,y1,x2,y2], ...]
   }
            │
            ▼
5. 发票检测
   ┌─────────────────────────────────────┐
   │ 关键词匹配:                         │
   │ 中文: 发票, 税号, 金额, 税额...     │
   │ 英文: invoice, tax, amount, total...│
   │                                     │
   │ 规则: 匹配 ≥2 个关键词 → 是发票     │
   └────────────────┬────────────────────┘
                    │
                    ▼
6. 返回结果
   {
     "success": true,
     "text": "识别的全部文字",
     "is_invoice": true,
     "confidence": 0.4,
     "matched_keywords": ["invoice", "amount", "total"]
   }
```

### OCR服务API

| 端点 | 方法 | 描述 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/pdf/parse` | POST | 解析PDF文件 |
| `/image/parse` | POST | 解析图片文件 |
| `/base64/parse` | POST | 解析Base64编码文件 |
| `/docs` | GET | Swagger API文档 |

---

## AI摘要流程

### 用户视角

```
1. 上传凭证完成后
       │
       ▼
2. 后台自动调用AI分析
       │
       ▼
3. 生成摘要信息:
   ├── 金额提取
   ├── 日期识别
   ├── 商家名称
   └── 费用类别建议
       │
       ▼
4. 自动填充表单字段
```

### 服务器视角

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AI摘要流程                                    │
└─────────────────────────────────────────────────────────────────────┘

1. 接收OCR文本
       │
       ▼
2. 选择AI提供商
   ┌─────────────────────────────────────┐
   │ 根据settings.aiProvider选择:       │
   │ ├── OpenAI (gpt-5.1)               │
   │ ├── Gemini (gemini-2.5-flash)      │
   │ └── Ollama (本地模型)              │
   └────────────────┬────────────────────┘
                    │
                    ▼
3. 构建Prompt
   ┌─────────────────────────────────────┐
   │ System: 你是发票分析助手...         │
   │ User: 请分析以下发票内容:           │
   │       {ocr_text}                    │
   │       提取: 金额、日期、商家、类别   │
   └────────────────┬────────────────────┘
                    │
                    ▼
4. 调用API
   ├── OpenAI: POST https://api.openai.com/v1/chat/completions
   ├── Gemini: POST https://generativelanguage.googleapis.com/...
   └── Ollama: POST http://localhost:11434/api/generate
                    │
                    ▼
5. 解析响应
   {
     "amount": 21.10,
     "currency": "USD",
     "date": "2025-08-07",
     "vendor": "OpenRouter, Inc",
     "category": "软件服务",
     "summary": "OpenRouter API充值"
   }
```

---

## 自动聚类流程

### 用户视角

```
1. 系统检测到相似记录
       │
       ▼
2. 弹出合并建议:
   "发现3条相似记录，是否合并？"
   ├── 记录A: 滴滴出行 ¥25.00
   ├── 记录B: 滴滴出行 ¥28.00
   └── 记录C: 滴滴出行 ¥22.00
       │
       ▼
3. 用户选择:
   ├── 合并 → 创建汇总记录
   └── 忽略 → 保持独立
```

### 服务器视角

```
┌─────────────────────────────────────────────────────────────────────┐
│                        聚类算法                                      │
└─────────────────────────────────────────────────────────────────────┘

1. 特征提取
   ┌─────────────────────────────────────┐
   │ 每条记录提取:                       │
   │ ├── 金额 (归一化)                   │
   │ ├── 时间 (转换为时间戳)             │
   │ ├── 类别 (one-hot编码)              │
   │ └── 商家 (文本相似度)               │
   └────────────────┬────────────────────┘
                    │
                    ▼
2. 相似度计算
   ┌─────────────────────────────────────┐
   │ 综合相似度 = w1*金额相似度          │
   │            + w2*时间相似度          │
   │            + w3*类别相似度          │
   │            + w4*商家相似度          │
   │                                     │
   │ 权重: w1=0.3, w2=0.2, w3=0.2, w4=0.3│
   └────────────────┬────────────────────┘
                    │
                    ▼
3. 聚类分组
   ┌─────────────────────────────────────┐
   │ 阈值: similarity > 0.7              │
   │                                     │
   │ 使用贪心算法分组:                   │
   │ for each record:                    │
   │   找到最相似的已有组                │
   │   if 相似度 > 阈值:                 │
   │     加入该组                        │
   │   else:                             │
   │     创建新组                        │
   └────────────────┬────────────────────┘
                    │
                    ▼
4. 生成建议
   {
     "clusters": [
       {
         "id": "cluster_1",
         "records": ["exp_1", "exp_2", "exp_3"],
         "similarity": 0.85,
         "suggested_merge": true
       }
     ]
   }
```

---

## 数据流

### 完整报销流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                        完整数据流                                    │
└─────────────────────────────────────────────────────────────────────┘

用户操作                    前端处理                    后端服务
────────                    ────────                    ────────

1. 点击添加报销
        │
        ▼
2. 选择凭证文件 ──────────► FilePicker选择文件
                                    │
                                    ▼
3.                          读取文件字节 ─────────────► OCR服务
                                                        /pdf/parse
                                    │                       │
                                    │                       ▼
                                    │               PaddleOCR识别
                                    │                       │
                                    ◄───────────────────────┘
                                    │
                                    ▼
4.                          解析OCR结果
                            判断文档类型
                                    │
                                    ▼
5.                          调用AI服务 ───────────────► AI API
                            (可选)                    GPT/Gemini
                                    │                       │
                                    ◄───────────────────────┘
                                    │
                                    ▼
6. 查看自动填充 ◄────────── 填充表单字段
   的表单信息
        │
        ▼
7. 编辑/确认信息
        │
        ▼
8. 点击保存 ─────────────► 验证数据
                                    │
                                    ▼
                          调用API保存 ─────────────► Vercel API
                                                    /api/expenses
                                    │                       │
                                    ◄───────────────────────┘
                                    │
                                    ▼
9. 显示成功 ◄────────────── 更新本地状态
                                    │
                                    ▼
10.                         触发聚类检测
                            (后台异步)
                                    │
                                    ▼
11. 收到合并建议 ◄───────── 显示合并对话框
    (如果有)
```

---

## 部署架构

### 本地开发

```
┌─────────────────────────────────────────────────────────────────────┐
│                        本地开发环境                                  │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Flutter Web    │     │   OCR Server     │     │   Conda Env      │
│   localhost:8080 │────►│   localhost:8000 │────►│   expense_ocr    │
│                  │     │   (FastAPI)      │     │   Python 3.10    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │   PaddleOCR      │
                         │   模型文件       │
                         │   ~/.paddlex/    │
                         └──────────────────┘
```

### 生产部署

```
┌─────────────────────────────────────────────────────────────────────┐
│                        生产环境                                      │
└─────────────────────────────────────────────────────────────────────┘

                         ┌──────────────────┐
                         │   CDN/Vercel     │
                         │   静态资源托管   │
                         └────────┬─────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Flutter Web    │     │   Vercel API     │     │   OCR Service    │
│   (静态文件)     │     │   (Serverless)   │     │   (Docker/K8s)   │
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                  │                         │
                                  ▼                         ▼
                         ┌──────────────────┐     ┌──────────────────┐
                         │   数据库         │     │   GPU服务器      │
                         │   (可选)         │     │   (可选MinerU)   │
                         └──────────────────┘     └──────────────────┘
```

### Docker部署

```bash
# 启动OCR服务
cd docker
docker compose up -d ocr

# 或使用GPU版MinerU
docker compose --profile gpu up -d mineru
```

---

## 配置说明

### 环境变量

在项目根目录创建 `.env` 文件：

```bash
# AI服务 (必选其一)
GEMINI_API_KEY=your_gemini_api_key  # 推荐，默认使用

# 可选
OPENAI_API_KEY=your_openai_api_key
OLLAMA_ENDPOINT=http://localhost:11434
```

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `GEMINI_API_KEY` | **Gemini API密钥 (推荐)** | - |
| `OPENAI_API_KEY` | OpenAI API密钥 | - |
| `OLLAMA_ENDPOINT` | Ollama服务地址 | `http://localhost:11434` |
| `MINERU_MODEL_SOURCE` | 模型下载源 | `modelscope` |
| `OCR_ENDPOINT` | OCR服务地址 | `http://localhost:8000` |

### 应用设置 (settings.dart)

```dart
class AppSettings {
  // OCR设置
  OcrProvider ocrProvider;        // minerU / tesseract / paddleOcr
  bool autoParseOnUpload;         // 上传后自动解析
  String? minerUEndpoint;         // MinerU服务地址
  MinerUBackend minerUBackend;    // pipeline / vlm-transformers
  MinerUModelSource minerUModelSource; // modelscope / huggingface

  // AI设置
  AiProvider aiProvider;          // openai / gemini / ollama
  bool autoSummarize;             // 自动生成摘要
  String? openaiApiKey;
  String? geminiApiKey;
  String? ollamaEndpoint;
  String? ollamaModel;

  // 聚类设置
  bool enableAutoClustering;      // 启用自动聚类
  double clusterSimilarityThreshold; // 相似度阈值 (0.0-1.0)
}
```

---

## 快速启动

### 一键启动 (推荐)

```bash
# 安装依赖
flutter pub get

# 创建conda环境并安装OCR依赖
conda create -n expense_ocr python=3.10 -y
conda activate expense_ocr
pip install paddlepaddle paddleocr fastapi uvicorn python-multipart pdf2image Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple

# 启动OCR服务
python docker/ocr_server.py &

# 启动Flutter应用
flutter run -d chrome --web-port=8080
```

### 验证服务

```bash
# 检查OCR服务
curl http://localhost:8000/health
# {"status":"ok","service":"ocr"}

# 测试PDF解析
curl -X POST http://localhost:8000/pdf/parse -F "file=@test_files/Invoice-DJ7EWSNC-0001.pdf"

# 访问Flutter应用
open http://localhost:8080
```

---

## 性能指标

| 操作 | 耗时 | 说明 |
|------|------|------|
| PDF解析 (单页) | 2-5秒 | 首次加载模型较慢 |
| 图片OCR | 1-3秒 | 取决于图片大小 |
| AI摘要 | 1-3秒 | 取决于API响应 |
| 聚类计算 | <100ms | 本地计算 |

---

## 错误处理

### OCR服务错误码

| 状态码 | 描述 | 处理方式 |
|--------|------|----------|
| 200 | 成功 | 正常处理 |
| 400 | 请求参数错误 | 检查文件格式 |
| 500 | 服务器内部错误 | 查看日志 |
| 503 | 服务不可用 | 重启OCR服务 |

### 常见问题

1. **OCR服务无响应**
   ```bash
   # 检查服务状态
   curl http://localhost:8000/health
   
   # 重启服务
   pkill -f ocr_server
   python docker/ocr_server.py &
   ```

2. **PDF解析失败**
   ```bash
   # 确保安装了poppler
   brew install poppler  # macOS
   apt install poppler-utils  # Linux
   ```

3. **模型下载失败**
   ```bash
   # 使用国内源
   export MINERU_MODEL_SOURCE=modelscope
   ```
