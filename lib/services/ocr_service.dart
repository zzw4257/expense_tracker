import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/settings.dart';

class OcrResult {
  final String text;
  final bool isInvoice;
  final double confidence;
  final List<String> matchedKeywords;
  final Map<String, dynamic>? rawData;

  OcrResult({
    required this.text,
    required this.isInvoice,
    this.confidence = 0.0,
    this.matchedKeywords = const [],
    this.rawData,
  });
}

/// MinerU配置
class MinerUConfig {
  final String endpoint;
  final String? apiKey;
  final String backend; // pipeline, vlm-transformers, vlm-http-client
  final String modelSource; // huggingface, modelscope, local
  final bool useVllm;
  final int? port;

  MinerUConfig({
    this.endpoint = 'http://127.0.0.1:8000',
    this.apiKey,
    this.backend = 'pipeline',
    this.modelSource = 'modelscope', // 国内默认用modelscope
    this.useVllm = false,
    this.port,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'apiKey': apiKey,
    'backend': backend,
    'modelSource': modelSource,
    'useVllm': useVllm,
    'port': port,
  };

  factory MinerUConfig.fromJson(Map<String, dynamic> json) => MinerUConfig(
    endpoint: json['endpoint'] ?? 'http://127.0.0.1:8000',
    apiKey: json['apiKey'],
    backend: json['backend'] ?? 'pipeline',
    modelSource: json['modelSource'] ?? 'modelscope',
    useVllm: json['useVllm'] ?? false,
    port: json['port'],
  );
}

class OcrService {
  final AppSettings settings;
  MinerUConfig? minerUConfig;

  OcrService(this.settings, {this.minerUConfig});

  // 解析文档（先解析第一页判断是否为发票）
  Future<OcrResult> parseDocument({
    required Uint8List fileBytes,
    required String fileName,
    bool fullParse = false,
  }) async {
    try {
      switch (settings.ocrProvider) {
        case OcrProvider.minerU:
          return await _parseWithMinerU(fileBytes, fileName, fullParse);
        case OcrProvider.tesseract:
          return await _parseWithTesseract(fileBytes, fileName);
        case OcrProvider.paddleOcr:
          return await _parseWithPaddleOcr(fileBytes, fileName);
      }
    } catch (e) {
      // 生产环境应使用日志系统
      return OcrResult(text: '', isInvoice: false);
    }
  }

  /// MinerU解析 - 支持本地部署和API两种方式
  /// 
  /// 本地部署方式:
  /// 1. 安装: pip install mineru
  /// 2. 下载模型: mineru-models-download
  /// 3. 启动API服务: mineru-api --host 0.0.0.0 --port 8000
  /// 4. 或启动WebUI: mineru-gradio --server-name 0.0.0.0 --server-port 7860
  /// 
  /// 环境变量:
  /// - MINERU_MODEL_SOURCE=modelscope (国内用户)
  /// - MINERU_MODEL_SOURCE=huggingface (海外用户)
  /// - MINERU_MODEL_SOURCE=local (使用本地模型)
  Future<OcrResult> _parseWithMinerU(Uint8List fileBytes, String fileName, bool fullParse) async {
    final config = minerUConfig ?? MinerUConfig();
    final endpoint = settings.minerUEndpoint ?? config.endpoint;

    // MinerU FastAPI 接口
    // 文档: http://127.0.0.1:8000/docs
    final uri = Uri.parse('$endpoint/pdf/parse');
    
    final request = http.MultipartRequest('POST', uri);
    
    // 添加API Key（如果配置了）
    if (settings.minerUApiKey?.isNotEmpty == true) {
      request.headers['Authorization'] = 'Bearer ${settings.minerUApiKey}';
    }
    
    // 添加文件
    request.files.add(http.MultipartFile.fromBytes(
      'file', 
      fileBytes, 
      filename: fileName,
    ));
    
    // 解析参数
    request.fields['parse_method'] = config.backend; // pipeline/vlm-transformers
    request.fields['return_text'] = 'true';
    
    // 如果只解析第一页（用于发票检测）
    if (!fullParse) {
      request.fields['start_page'] = '0';
      request.fields['end_page'] = '0';
    }

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // PDF解析可能较慢
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // MinerU返回格式处理
        String text = '';
        if (data is Map) {
          // 标准API返回
          text = data['text'] ?? data['content'] ?? '';
          if (data['pages'] is List) {
            text = (data['pages'] as List)
                .map((p) => p['text'] ?? p['content'] ?? '')
                .join('\n');
          }
        } else if (data is String) {
          text = data;
        }

        final isInvoice = _checkIsInvoice(text);
        final matchedKeywords = _getMatchedKeywords(text);

        // 如果检测到是发票且只解析了第一页，继续完整解析
        if (isInvoice && !fullParse) {
          return await _parseWithMinerU(fileBytes, fileName, true);
        }

        return OcrResult(
          text: text,
          isInvoice: isInvoice,
          confidence: _calculateConfidence(matchedKeywords),
          matchedKeywords: matchedKeywords,
          rawData: data is Map ? Map<String, dynamic>.from(data) : null,
        );
      }

      throw Exception('MinerU API error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      // 如果本地API失败，尝试使用命令行方式（通过后端代理）
      return await _parseWithMinerUViaBackend(fileBytes, fileName, fullParse);
    }
  }

  /// 通过后端代理调用MinerU命令行
  Future<OcrResult> _parseWithMinerUViaBackend(Uint8List fileBytes, String fileName, bool fullParse) async {
    final response = await http.post(
      Uri.parse('/api/ocr/mineru'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file': base64Encode(fileBytes),
        'fileName': fileName,
        'fullParse': fullParse,
        'backend': minerUConfig?.backend ?? 'pipeline',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['text'] ?? '';
      final isInvoice = _checkIsInvoice(text);
      
      if (isInvoice && !fullParse) {
        return await _parseWithMinerUViaBackend(fileBytes, fileName, true);
      }
      
      return OcrResult(
        text: text,
        isInvoice: isInvoice,
        matchedKeywords: _getMatchedKeywords(text),
        rawData: data,
      );
    }

    return OcrResult(text: '', isInvoice: false);
  }

  Future<OcrResult> _parseWithTesseract(Uint8List fileBytes, String fileName) async {
    final response = await http.post(
      Uri.parse('/api/ocr/tesseract'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file': base64Encode(fileBytes),
        'fileName': fileName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['text'] ?? '';
      return OcrResult(
        text: text,
        isInvoice: _checkIsInvoice(text),
        matchedKeywords: _getMatchedKeywords(text),
      );
    }

    return OcrResult(text: '', isInvoice: false);
  }

  Future<OcrResult> _parseWithPaddleOcr(Uint8List fileBytes, String fileName) async {
    final response = await http.post(
      Uri.parse('/api/ocr/paddle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file': base64Encode(fileBytes),
        'fileName': fileName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['text'] ?? '';
      return OcrResult(
        text: text,
        isInvoice: _checkIsInvoice(text),
        matchedKeywords: _getMatchedKeywords(text),
      );
    }

    return OcrResult(text: '', isInvoice: false);
  }

  bool _checkIsInvoice(String text) {
    final lowerText = text.toLowerCase();
    int matchCount = 0;
    for (final keyword in AppSettings.invoiceKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        matchCount++;
        if (matchCount >= 2) return true;
      }
    }
    return false;
  }

  List<String> _getMatchedKeywords(String text) {
    final lowerText = text.toLowerCase();
    return AppSettings.invoiceKeywords
        .where((k) => lowerText.contains(k.toLowerCase()))
        .toList();
  }

  double _calculateConfidence(List<String> matchedKeywords) {
    if (matchedKeywords.isEmpty) return 0.0;
    // 基于匹配关键词数量计算置信度
    final maxKeywords = 10;
    return (matchedKeywords.length / maxKeywords).clamp(0.0, 1.0);
  }
}
