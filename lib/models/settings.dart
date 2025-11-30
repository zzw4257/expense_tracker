// 应用设置模型

enum OcrProvider {
  minerU('MinerU', '高精度文档解析'),
  tesseract('Tesseract', '本地OCR引擎'),
  paddleOcr('PaddleOCR', '百度开源OCR');

  final String label;
  final String description;
  const OcrProvider(this.label, this.description);
}

enum AiProvider {
  openai('OpenAI', 'gpt-5.1'),
  gemini('Gemini', 'gemini-2.5-flash'),
  ollama('Ollama', '本地模型');

  final String label;
  final String model;
  const AiProvider(this.label, this.model);
}

// MinerU后端类型
enum MinerUBackend {
  pipeline('Pipeline', '默认后端，适合大多数场景'),
  vlmTransformers('VLM-Transformers', '视觉语言模型，更精准'),
  vlmHttpClient('VLM-HTTP-Client', '远程VLM服务');

  final String label;
  final String description;
  const MinerUBackend(this.label, this.description);
}

// MinerU模型源
enum MinerUModelSource {
  modelscope('ModelScope', '国内用户推荐'),
  huggingface('HuggingFace', '海外用户'),
  local('Local', '本地模型');

  final String label;
  final String description;
  const MinerUModelSource(this.label, this.description);
}

class AppSettings {
  // OCR设置
  final OcrProvider ocrProvider;
  final bool autoParseOnUpload;
  final String? minerUApiKey;
  final String? minerUEndpoint;
  final MinerUBackend minerUBackend;
  final MinerUModelSource minerUModelSource;
  final bool minerUUseVllm;

  // AI设置
  final AiProvider aiProvider;
  final bool autoSummarize;
  final String? openaiApiKey;
  final String? geminiApiKey;
  final String? ollamaEndpoint;
  final String? ollamaModel;

  // 聚类设置
  final bool enableAutoClustering;
  final double clusterSimilarityThreshold;

  // 发票关键词（用于验证是否为发票）
  static const List<String> invoiceKeywords = [
    // 中文关键词
    '发票', '税号', '纳税人识别号', '开票日期', '价税合计', '金额', '税额',
    '购买方', '销售方', '发票代码', '发票号码', '校验码', '机器编号',
    '增值税', '普通发票', '专用发票', '电子发票', '收款人', '复核',
    // 英文关键词
    'invoice', 'tax', 'amount', 'total', 'date', 'receipt',
    'vat', 'payment', 'bill', 'vendor', 'buyer', 'seller',
  ];

  AppSettings({
    this.ocrProvider = OcrProvider.minerU,
    this.autoParseOnUpload = true,
    this.minerUApiKey,
    this.minerUEndpoint,
    this.minerUBackend = MinerUBackend.pipeline,
    this.minerUModelSource = MinerUModelSource.modelscope,
    this.minerUUseVllm = false,
    this.aiProvider = AiProvider.gemini,
    this.autoSummarize = true,
    this.openaiApiKey,
    this.geminiApiKey,
    this.ollamaEndpoint,
    this.ollamaModel,
    this.enableAutoClustering = true,
    this.clusterSimilarityThreshold = 0.7,
  });

  bool get hasValidAiConfig {
    switch (aiProvider) {
      case AiProvider.openai:
        return openaiApiKey?.isNotEmpty == true;
      case AiProvider.gemini:
        return geminiApiKey?.isNotEmpty == true;
      case AiProvider.ollama:
        return ollamaEndpoint?.isNotEmpty == true;
    }
  }

  /// MinerU启动命令提示
  String get minerUStartCommand {
    final backend = minerUBackend == MinerUBackend.pipeline 
        ? '' 
        : ' -b ${minerUBackend.name.replaceAll('vlm', 'vlm-').toLowerCase()}';
    return 'mineru-api --host 0.0.0.0 --port 8000$backend';
  }

  /// MinerU环境变量
  String get minerUEnvCommand {
    return 'export MINERU_MODEL_SOURCE=${minerUModelSource.name.toLowerCase()}';
  }

  Map<String, dynamic> toJson() => {
        'ocrProvider': ocrProvider.name,
        'autoParseOnUpload': autoParseOnUpload,
        'minerUApiKey': minerUApiKey,
        'minerUEndpoint': minerUEndpoint,
        'minerUBackend': minerUBackend.name,
        'minerUModelSource': minerUModelSource.name,
        'minerUUseVllm': minerUUseVllm,
        'aiProvider': aiProvider.name,
        'autoSummarize': autoSummarize,
        'openaiApiKey': openaiApiKey,
        'geminiApiKey': geminiApiKey,
        'ollamaEndpoint': ollamaEndpoint,
        'ollamaModel': ollamaModel,
        'enableAutoClustering': enableAutoClustering,
        'clusterSimilarityThreshold': clusterSimilarityThreshold,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        ocrProvider: OcrProvider.values.firstWhere(
          (e) => e.name == json['ocrProvider'],
          orElse: () => OcrProvider.minerU,
        ),
        autoParseOnUpload: json['autoParseOnUpload'] ?? true,
        minerUApiKey: json['minerUApiKey'],
        minerUEndpoint: json['minerUEndpoint'],
        minerUBackend: MinerUBackend.values.firstWhere(
          (e) => e.name == json['minerUBackend'],
          orElse: () => MinerUBackend.pipeline,
        ),
        minerUModelSource: MinerUModelSource.values.firstWhere(
          (e) => e.name == json['minerUModelSource'],
          orElse: () => MinerUModelSource.modelscope,
        ),
        minerUUseVllm: json['minerUUseVllm'] ?? false,
        aiProvider: AiProvider.values.firstWhere(
          (e) => e.name == json['aiProvider'],
          orElse: () => AiProvider.gemini,
        ),
        autoSummarize: json['autoSummarize'] ?? true,
        openaiApiKey: json['openaiApiKey'],
        geminiApiKey: json['geminiApiKey'],
        ollamaEndpoint: json['ollamaEndpoint'],
        ollamaModel: json['ollamaModel'],
        enableAutoClustering: json['enableAutoClustering'] ?? true,
        clusterSimilarityThreshold: json['clusterSimilarityThreshold'] ?? 0.7,
      );

  AppSettings copyWith({
    OcrProvider? ocrProvider,
    bool? autoParseOnUpload,
    String? minerUApiKey,
    String? minerUEndpoint,
    MinerUBackend? minerUBackend,
    MinerUModelSource? minerUModelSource,
    bool? minerUUseVllm,
    AiProvider? aiProvider,
    bool? autoSummarize,
    String? openaiApiKey,
    String? geminiApiKey,
    String? ollamaEndpoint,
    String? ollamaModel,
    bool? enableAutoClustering,
    double? clusterSimilarityThreshold,
  }) =>
      AppSettings(
        ocrProvider: ocrProvider ?? this.ocrProvider,
        autoParseOnUpload: autoParseOnUpload ?? this.autoParseOnUpload,
        minerUApiKey: minerUApiKey ?? this.minerUApiKey,
        minerUEndpoint: minerUEndpoint ?? this.minerUEndpoint,
        minerUBackend: minerUBackend ?? this.minerUBackend,
        minerUModelSource: minerUModelSource ?? this.minerUModelSource,
        minerUUseVllm: minerUUseVllm ?? this.minerUUseVllm,
        aiProvider: aiProvider ?? this.aiProvider,
        autoSummarize: autoSummarize ?? this.autoSummarize,
        openaiApiKey: openaiApiKey ?? this.openaiApiKey,
        geminiApiKey: geminiApiKey ?? this.geminiApiKey,
        ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
        ollamaModel: ollamaModel ?? this.ollamaModel,
        enableAutoClustering: enableAutoClustering ?? this.enableAutoClustering,
        clusterSimilarityThreshold: clusterSimilarityThreshold ?? this.clusterSimilarityThreshold,
      );
}

// 聚类建议
class ClusterSuggestion {
  final String id;
  final List<String> expenseIds;
  final String reason;
  final double similarity;
  final DateTime createdAt;
  final bool isAccepted;

  ClusterSuggestion({
    required this.id,
    required this.expenseIds,
    required this.reason,
    required this.similarity,
    required this.createdAt,
    this.isAccepted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'expenseIds': expenseIds,
        'reason': reason,
        'similarity': similarity,
        'createdAt': createdAt.toIso8601String(),
        'isAccepted': isAccepted,
      };

  factory ClusterSuggestion.fromJson(Map<String, dynamic> json) => ClusterSuggestion(
        id: json['id'],
        expenseIds: List<String>.from(json['expenseIds']),
        reason: json['reason'],
        similarity: json['similarity'],
        createdAt: DateTime.parse(json['createdAt']),
        isAccepted: json['isAccepted'] ?? false,
      );
}
