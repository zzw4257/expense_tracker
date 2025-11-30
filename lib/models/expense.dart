import 'package:flutter/material.dart';

enum ExpenseCategory {
  travel('差旅', Icons.flight_takeoff),
  meal('餐饮', Icons.restaurant),
  office('办公', Icons.business_center),
  transport('交通', Icons.directions_car),
  accommodation('住宿', Icons.hotel),
  other('其他', Icons.category);

  final String label;
  final IconData icon;
  const ExpenseCategory(this.label, this.icon);
}

enum ExpenseStatus {
  pending('待审核', Color(0xFFFFD700)),
  approved('已通过', Color(0xFF00FF88)),
  rejected('已拒绝', Color(0xFFFF4444));

  final String label;
  final Color color;
  const ExpenseStatus(this.label, this.color);
}

// 凭证类型
enum DocumentType {
  invoice('发票', Icons.receipt_long, ['pdf', 'jpg', 'png', 'jpeg']),
  paymentProof('支付凭证', Icons.payment, ['jpg', 'png', 'jpeg', 'pdf']),
  contract('合同', Icons.description, ['pdf', 'docx', 'doc']),
  receipt('收据', Icons.receipt, ['jpg', 'png', 'jpeg', 'pdf']),
  other('其他', Icons.attach_file, ['pdf', 'jpg', 'png', 'jpeg', 'docx', 'txt', 'md', 'html']);

  final String label;
  final IconData icon;
  final List<String> allowedExtensions;
  const DocumentType(this.label, this.icon, this.allowedExtensions);
}

// 文件格式
enum FileFormat {
  image('图片', Icons.image),
  pdf('PDF', Icons.picture_as_pdf),
  document('文档', Icons.article),
  text('文本', Icons.text_snippet);

  final String label;
  final IconData icon;
  const FileFormat(this.label, this.icon);

  static FileFormat fromExtension(String ext) {
    final lower = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(lower)) return FileFormat.image;
    if (lower == 'pdf') return FileFormat.pdf;
    if (['doc', 'docx', 'html'].contains(lower)) return FileFormat.document;
    return FileFormat.text;
  }
}

// OCR/AI解析状态
enum ParseStatus {
  pending('待解析'),
  parsing('解析中'),
  completed('已完成'),
  failed('解析失败');

  final String label;
  const ParseStatus(this.label);
}

class Receipt {
  final String id;
  final DocumentType documentType;
  final FileFormat fileFormat;
  final String? fileName;
  final String? filePath;
  final String? fileUrl;
  final int? fileSize;
  final String? taxNumber;
  final String? extractedText;
  final String? aiSummary;
  final Map<String, dynamic>? parsedData;
  final ParseStatus parseStatus;
  final DateTime uploadedAt;
  final bool isValid;

  Receipt({
    required this.id,
    required this.documentType,
    required this.fileFormat,
    this.fileName,
    this.filePath,
    this.fileUrl,
    this.fileSize,
    this.taxNumber,
    this.extractedText,
    this.aiSummary,
    this.parsedData,
    this.parseStatus = ParseStatus.pending,
    required this.uploadedAt,
    this.isValid = false,
  });

  // 兼容旧数据
  String get type => documentType.name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentType': documentType.name,
        'fileFormat': fileFormat.name,
        'fileName': fileName,
        'filePath': filePath,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'taxNumber': taxNumber,
        'extractedText': extractedText,
        'aiSummary': aiSummary,
        'parsedData': parsedData,
        'parseStatus': parseStatus.name,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isValid': isValid,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    // 兼容旧数据格式
    DocumentType docType;
    if (json['documentType'] != null) {
      docType = DocumentType.values.firstWhere(
        (e) => e.name == json['documentType'],
        orElse: () => DocumentType.other,
      );
    } else {
      // 旧格式兼容
      final oldType = json['type'] as String?;
      docType = oldType == 'invoice' ? DocumentType.invoice : DocumentType.paymentProof;
    }

    FileFormat format;
    if (json['fileFormat'] != null) {
      format = FileFormat.values.firstWhere(
        (e) => e.name == json['fileFormat'],
        orElse: () => FileFormat.image,
      );
    } else {
      format = FileFormat.image;
    }

    return Receipt(
      id: json['id'],
      documentType: docType,
      fileFormat: format,
      fileName: json['fileName'],
      filePath: json['filePath'] ?? json['imagePath'],
      fileUrl: json['fileUrl'],
      fileSize: json['fileSize'],
      taxNumber: json['taxNumber'],
      extractedText: json['extractedText'],
      aiSummary: json['aiSummary'],
      parsedData: json['parsedData'],
      parseStatus: json['parseStatus'] != null
          ? ParseStatus.values.firstWhere(
              (e) => e.name == json['parseStatus'],
              orElse: () => ParseStatus.pending,
            )
          : ParseStatus.pending,
      uploadedAt: DateTime.parse(json['uploadedAt']),
      isValid: json['isValid'] ?? false,
    );
  }

  Receipt copyWith({
    DocumentType? documentType,
    FileFormat? fileFormat,
    String? fileName,
    String? filePath,
    String? fileUrl,
    int? fileSize,
    String? taxNumber,
    String? extractedText,
    String? aiSummary,
    Map<String, dynamic>? parsedData,
    ParseStatus? parseStatus,
    bool? isValid,
  }) =>
      Receipt(
        id: id,
        documentType: documentType ?? this.documentType,
        fileFormat: fileFormat ?? this.fileFormat,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        fileUrl: fileUrl ?? this.fileUrl,
        fileSize: fileSize ?? this.fileSize,
        taxNumber: taxNumber ?? this.taxNumber,
        extractedText: extractedText ?? this.extractedText,
        aiSummary: aiSummary ?? this.aiSummary,
        parsedData: parsedData ?? this.parsedData,
        parseStatus: parseStatus ?? this.parseStatus,
        uploadedAt: uploadedAt,
        isValid: isValid ?? this.isValid,
      );
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final ExpenseStatus status;
  final String? description;
  final List<Receipt> receipts;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.status = ExpenseStatus.pending,
    this.description,
    this.receipts = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category.name,
        'status': status.name,
        'description': description,
        'receipts': receipts.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        status: ExpenseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ExpenseStatus.pending,
        ),
        description: json['description'],
        receipts: (json['receipts'] as List?)
                ?.map((r) => Receipt.fromJson(r))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Expense copyWith({
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    ExpenseStatus? status,
    String? description,
    List<Receipt>? receipts,
  }) =>
      Expense(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        category: category ?? this.category,
        status: status ?? this.status,
        description: description ?? this.description,
        receipts: receipts ?? this.receipts,
        createdAt: createdAt,
      );
}
