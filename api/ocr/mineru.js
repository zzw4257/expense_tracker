/**
 * MinerU OCR API - Vercel Serverless Function
 * 
 * 本地部署MinerU:
 * 1. pip install mineru
 * 2. export MINERU_MODEL_SOURCE=modelscope  # 国内用户
 * 3. mineru-models-download
 * 4. mineru-api --host 0.0.0.0 --port 8000
 * 
 * 或使用Docker:
 * docker run --gpus all -p 8000:8000 -p 7860:7860 mineru:latest
 */

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '50mb',
    },
  },
};

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default async function handler(req, res) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.status(200).json({});
    return;
  }

  // Set CORS headers
  Object.entries(corsHeaders).forEach(([key, value]) => {
    res.setHeader(key, value);
  });

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { file, fileName, fullParse, backend } = req.body;

    if (!file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    // MinerU服务端点 - 可通过环境变量配置
    const mineruEndpoint = process.env.MINERU_ENDPOINT || 'http://127.0.0.1:8000';
    
    // 将base64转换为Buffer
    const fileBuffer = Buffer.from(file, 'base64');
    
    // 创建FormData
    const FormData = (await import('form-data')).default;
    const formData = new FormData();
    formData.append('file', fileBuffer, {
      filename: fileName || 'document.pdf',
      contentType: 'application/pdf',
    });
    
    // 解析参数
    formData.append('parse_method', backend || 'pipeline');
    formData.append('return_text', 'true');
    
    if (!fullParse) {
      formData.append('start_page', '0');
      formData.append('end_page', '0');
    }

    // 调用MinerU API
    const response = await fetch(`${mineruEndpoint}/pdf/parse`, {
      method: 'POST',
      body: formData,
      headers: formData.getHeaders(),
    });

    if (!response.ok) {
      // 如果MinerU API不可用，返回错误信息
      return res.status(503).json({ 
        error: 'MinerU service unavailable',
        message: 'Please ensure MinerU is running: mineru-api --host 0.0.0.0 --port 8000',
        setup: {
          install: 'pip install mineru',
          modelSource: 'export MINERU_MODEL_SOURCE=modelscope',
          downloadModels: 'mineru-models-download',
          startApi: 'mineru-api --host 0.0.0.0 --port 8000',
          docker: 'docker run --gpus all -p 8000:8000 mineru:latest',
        }
      });
    }

    const data = await response.json();
    
    // 处理MinerU返回的数据
    let text = '';
    if (data.text) {
      text = data.text;
    } else if (data.content) {
      text = data.content;
    } else if (data.pages && Array.isArray(data.pages)) {
      text = data.pages.map(p => p.text || p.content || '').join('\n');
    }

    return res.status(200).json({
      success: true,
      text,
      pages: data.pages,
      metadata: data.metadata,
    });

  } catch (error) {
    console.error('MinerU OCR error:', error);
    return res.status(500).json({ 
      error: 'OCR processing failed',
      message: error.message,
      hint: 'Ensure MinerU service is running locally',
    });
  }
}
