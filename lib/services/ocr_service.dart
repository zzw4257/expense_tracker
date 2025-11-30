import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/settings.dart';

class OcrResult {
  final String text;
  final bool isInvoice;
  final double confidence;
  final List<String> matchedKeywords;

  OcrResult({
    required this.text,
    required this.isInvoice,
    this.confidence = 0.0,
    this.matchedKeywords = const [],
  });
}

class OcrService {
  final AppSettings settings;

  OcrService(this.settings);

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
      print('OCR error: $e');
      return OcrResult(text: '', isInvoice: false);
    }
  }

  Future<OcrResult> _parseWithMinerU(Uint8List fileBytes, String fileName, bool fullParse) async {
    final endpoint = settings.minerUEndpoint ?? 'https://api.mineru.net/v1';
    final apiKey = settings.minerUApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('MinerU API key not configured');
    }

    // 先解析第一页
    final request = http.MultipartRequest('POST', Uri.parse('$endpoint/parse'));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    request.fields['pages'] = fullParse ? 'all' : '1';
    request.fields['output_format'] = 'text';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['text'] ?? '';
      final isInvoice = _checkIsInvoice(text);
      final matchedKeywords = _getMatchedKeywords(text);

      // 如果是发票且需要完整解析，继续解析
      if (isInvoice && !fullParse) {
        return await _parseWithMinerU(fileBytes, fileName, true);
      }

      return OcrResult(
        text: text,
        isInvoice: isInvoice,
        confidence: data['confidence'] ?? 0.0,
        matchedKeywords: matchedKeywords,
      );
    }

    throw Exception('MinerU API error: ${response.statusCode}');
  }

  Future<OcrResult> _parseWithTesseract(Uint8List fileBytes, String fileName) async {
    // 调用后端Tesseract API
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
    // 调用后端PaddleOCR API
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
}
