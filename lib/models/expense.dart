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

class Receipt {
  final String id;
  final String type;
  final String? taxNumber;
  final String? imagePath;
  final DateTime uploadedAt;
  final bool isValid;

  Receipt({
    required this.id,
    required this.type,
    this.taxNumber,
    this.imagePath,
    required this.uploadedAt,
    this.isValid = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'taxNumber': taxNumber,
        'imagePath': imagePath,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isValid': isValid,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'],
        type: json['type'],
        taxNumber: json['taxNumber'],
        imagePath: json['imagePath'],
        uploadedAt: DateTime.parse(json['uploadedAt']),
        isValid: json['isValid'] ?? false,
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
