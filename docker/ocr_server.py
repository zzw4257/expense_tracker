"""
OCR服务 - 基于PaddleOCR
支持图片和PDF解析
"""
import os
import io
import base64
import tempfile
from typing import Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from paddleocr import PaddleOCR
from PIL import Image

app = FastAPI(title="OCR Service", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 初始化OCR（延迟加载）
ocr_engine = None

def get_ocr():
    global ocr_engine
    if ocr_engine is None:
        ocr_engine = PaddleOCR(
            use_textline_orientation=True,
            lang='ch',
        )
    return ocr_engine

# 发票关键词
INVOICE_KEYWORDS = [
    '发票', '税号', '纳税人识别号', '开票日期', '价税合计', '金额', '税额',
    '购买方', '销售方', '发票代码', '发票号码', '校验码', '机器编号',
    '增值税', '普通发票', '专用发票', '电子发票', '收款人', '复核',
    'invoice', 'tax', 'amount', 'total', 'receipt', 'vat',
]

class ParseResponse(BaseModel):
    success: bool
    text: str
    is_invoice: bool
    confidence: float
    matched_keywords: list[str]
    error: Optional[str] = None

@app.get("/health")
async def health():
    return {"status": "ok", "service": "ocr"}

@app.post("/pdf/parse", response_model=ParseResponse)
async def parse_pdf(
    file: UploadFile = File(...),
    start_page: int = Form(0),
    end_page: int = Form(-1),
):
    """解析PDF文件"""
    try:
        content = await file.read()
        
        # 检查文件类型
        filename = file.filename.lower() if file.filename else ""
        
        if filename.endswith('.pdf'):
            text = await parse_pdf_content(content, start_page, end_page)
        elif filename.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.webp')):
            text = await parse_image_content(content)
        else:
            # 尝试作为图片处理
            text = await parse_image_content(content)
        
        # 检测是否为发票
        is_invoice, matched, confidence = check_invoice(text)
        
        return ParseResponse(
            success=True,
            text=text,
            is_invoice=is_invoice,
            confidence=confidence,
            matched_keywords=matched,
        )
    except Exception as e:
        return ParseResponse(
            success=False,
            text="",
            is_invoice=False,
            confidence=0.0,
            matched_keywords=[],
            error=str(e),
        )

@app.post("/image/parse", response_model=ParseResponse)
async def parse_image(file: UploadFile = File(...)):
    """解析图片文件"""
    try:
        content = await file.read()
        text = await parse_image_content(content)
        is_invoice, matched, confidence = check_invoice(text)
        
        return ParseResponse(
            success=True,
            text=text,
            is_invoice=is_invoice,
            confidence=confidence,
            matched_keywords=matched,
        )
    except Exception as e:
        return ParseResponse(
            success=False,
            text="",
            is_invoice=False,
            confidence=0.0,
            matched_keywords=[],
            error=str(e),
        )

@app.post("/base64/parse", response_model=ParseResponse)
async def parse_base64(
    file: str = Form(...),
    fileName: str = Form("document"),
):
    """解析Base64编码的文件"""
    try:
        content = base64.b64decode(file)
        
        if fileName.lower().endswith('.pdf'):
            text = await parse_pdf_content(content)
        else:
            text = await parse_image_content(content)
        
        is_invoice, matched, confidence = check_invoice(text)
        
        return ParseResponse(
            success=True,
            text=text,
            is_invoice=is_invoice,
            confidence=confidence,
            matched_keywords=matched,
        )
    except Exception as e:
        return ParseResponse(
            success=False,
            text="",
            is_invoice=False,
            confidence=0.0,
            matched_keywords=[],
            error=str(e),
        )

async def parse_pdf_content(content: bytes, start_page: int = 0, end_page: int = -1) -> str:
    """解析PDF内容"""
    try:
        from pdf2image import convert_from_bytes
        
        # 转换PDF为图片
        images = convert_from_bytes(
            content,
            first_page=start_page + 1 if start_page >= 0 else 1,
            last_page=end_page + 1 if end_page >= 0 else None,
            dpi=200,
        )
        
        all_text = []
        ocr = get_ocr()
        
        for i, img in enumerate(images):
            # 保存到临时文件
            with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as f:
                img.save(f, format='PNG')
                temp_path = f.name
            
            try:
                # OCR识别
                result = ocr.predict(temp_path)
                
                # PaddleOCR返回字典格式，包含rec_texts
                if result:
                    if isinstance(result, dict) and 'rec_texts' in result:
                        texts = result['rec_texts']
                        if texts:
                            page_text = '\n'.join(texts)
                            all_text.append(f"--- Page {i+1} ---\n{page_text}")
                    elif isinstance(result, list):
                        for item in result:
                            if isinstance(item, dict) and 'rec_texts' in item:
                                texts = item['rec_texts']
                                if texts:
                                    page_text = '\n'.join(texts)
                                    all_text.append(f"--- Page {i+1} ---\n{page_text}")
            finally:
                os.unlink(temp_path)
        
        return '\n\n'.join(all_text)
    except ImportError:
        raise HTTPException(status_code=500, detail="pdf2image not installed")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF parse error: {str(e)}")

async def parse_image_content(content: bytes) -> str:
    """解析图片内容"""
    try:
        ocr = get_ocr()
        
        # 保存到临时文件
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as f:
            f.write(content)
            temp_path = f.name
        
        try:
            result = ocr.predict(temp_path)
            
            # PaddleOCR返回字典格式，包含rec_texts
            if result:
                if isinstance(result, dict) and 'rec_texts' in result:
                    return '\n'.join(result['rec_texts'])
                elif isinstance(result, list):
                    for item in result:
                        if isinstance(item, dict) and 'rec_texts' in item:
                            return '\n'.join(item['rec_texts'])
            return ""
        finally:
            os.unlink(temp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image parse error: {str(e)}")

def check_invoice(text: str) -> tuple[bool, list[str], float]:
    """检测是否为发票"""
    if not text:
        return False, [], 0.0
    
    lower_text = text.lower()
    matched = []
    
    for keyword in INVOICE_KEYWORDS:
        if keyword.lower() in lower_text:
            matched.append(keyword)
    
    # 至少匹配2个关键词才认为是发票
    is_invoice = len(matched) >= 2
    confidence = min(len(matched) / 10.0, 1.0)
    
    return is_invoice, matched, confidence

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
