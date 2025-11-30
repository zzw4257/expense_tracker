import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/settings.dart';

class AiService {
  final AppSettings settings;

  AiService(this.settings);

  // 检查文本是否包含发票关键词
  static bool isLikelyInvoice(String text) {
    final lowerText = text.toLowerCase();
    int matchCount = 0;
    for (final keyword in AppSettings.invoiceKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        matchCount++;
        if (matchCount >= 2) return true; // 至少匹配2个关键词
      }
    }
    return false;
  }

  // 调用AI进行摘要
  Future<String?> summarize(String text) async {
    if (!settings.hasValidAiConfig) return null;

    try {
      switch (settings.aiProvider) {
        case AiProvider.openai:
          return await _summarizeWithOpenAI(text);
        case AiProvider.gemini:
          return await _summarizeWithGemini(text);
        case AiProvider.ollama:
          return await _summarizeWithOllama(text);
      }
    } catch (e) {
      print('AI summarize error: $e');
      return null;
    }
  }

  Future<String?> _summarizeWithOpenAI(String text) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.openaiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-5.1',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的财务助手。请分析以下发票/凭证内容，提取关键信息（金额、日期、商家、商品/服务描述），并用简洁的中文总结。'
          },
          {'role': 'user', 'content': text}
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    return null;
  }

  Future<String?> _summarizeWithGemini(String text) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${settings.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '你是一个专业的财务助手。请分析以下发票/凭证内容，提取关键信息（金额、日期、商家、商品/服务描述），并用简洁的中文总结。\n\n$text'
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 500,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    return null;
  }

  Future<String?> _summarizeWithOllama(String text) async {
    final endpoint = settings.ollamaEndpoint ?? 'http://localhost:11434';
    final model = settings.ollamaModel ?? 'llama3';

    final response = await http.post(
      Uri.parse('$endpoint/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': '你是一个专业的财务助手。请分析以下发票/凭证内容，提取关键信息（金额、日期、商家、商品/服务描述），并用简洁的中文总结。\n\n$text',
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    }
    return null;
  }

  // 提取结构化数据
  Future<Map<String, dynamic>?> extractStructuredData(String text) async {
    if (!settings.hasValidAiConfig) return null;

    final prompt = '''
请从以下发票/凭证文本中提取结构化信息，以JSON格式返回：
{
  "amount": 金额数字,
  "date": "日期 YYYY-MM-DD格式",
  "vendor": "商家/销售方名称",
  "buyer": "购买方名称",
  "taxNumber": "税号",
  "items": ["商品/服务项目列表"],
  "invoiceNumber": "发票号码",
  "invoiceType": "发票类型"
}

文本内容：
$text

只返回JSON，不要其他内容。
''';

    try {
      String? response;
      switch (settings.aiProvider) {
        case AiProvider.openai:
          response = await _callOpenAI(prompt);
          break;
        case AiProvider.gemini:
          response = await _callGemini(prompt);
          break;
        case AiProvider.ollama:
          response = await _callOllama(prompt);
          break;
      }

      if (response != null) {
        // 尝试解析JSON
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
    } catch (e) {
      print('Extract structured data error: $e');
    }
    return null;
  }

  Future<String?> _callOpenAI(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.openaiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-5.1',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    return null;
  }

  Future<String?> _callGemini(String prompt) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${settings.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    return null;
  }

  Future<String?> _callOllama(String prompt) async {
    final endpoint = settings.ollamaEndpoint ?? 'http://localhost:11434';
    final model = settings.ollamaModel ?? 'llama3';

    final response = await http.post(
      Uri.parse('$endpoint/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    }
    return null;
  }
}
