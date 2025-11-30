import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_widgets.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  final List<Receipt> _receipts = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: NeonTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: NeonTheme.neonPink.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => NeonTheme.neonGradient.createShader(bounds),
                  child: Text('NEW EXPENSE', style: NeonTheme.titleStyle(size: 20)),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: NeonTheme.textSecondary, size: 28), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(controller: _titleController, label: '标题', hint: '报销项目名称', validator: (v) => v?.isEmpty == true ? '请输入标题' : null),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _amountController,
                      label: '金额 (¥)',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty == true) return '请输入金额';
                        if (double.tryParse(v!) == null) return '请输入有效金额';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildDatePicker(),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _descController, label: '备注', hint: '可选', maxLines: 3),
                    const SizedBox(height: 28),
                    _buildReceiptSection(),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: NeonButton(label: 'SUBMIT', icon: Icons.check, isLoading: _isSubmitting, onPressed: _submit),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: NeonTheme.bodyStyle(size: 15),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('类别', style: NeonTheme.labelStyle(size: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ExpenseCategory.values.map((cat) {
            final isSelected = _category == cat;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? NeonTheme.neonPink.withOpacity(0.3) : NeonTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? NeonTheme.neonPink : NeonTheme.neonPink.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 18, color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(cat.label, style: NeonTheme.bodyStyle(size: 13, color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: NeonTheme.theme.copyWith(colorScheme: const ColorScheme.dark(primary: NeonTheme.neonPink, surface: NeonTheme.bgCard)),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonTheme.neonPink.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: NeonTheme.neonPink, size: 22),
            const SizedBox(width: 14),
            Text(DateFormat('yyyy-MM-dd').format(_date), style: NeonTheme.bodyStyle(size: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('凭证', style: NeonTheme.labelStyle(size: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addReceipt,
              icon: const Icon(Icons.add, size: 18),
              label: Text('添加', style: NeonTheme.bodyStyle(size: 13, color: NeonTheme.neonCyan)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_receipts.isEmpty)
          GestureDetector(
            onTap: _addReceipt,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: NeonTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeonTheme.neonPink.withOpacity(0.2)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: NeonTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text('点击上传凭证文件', style: NeonTheme.labelStyle(size: 13)),
                    const SizedBox(height: 6),
                    Text('支持图片、PDF、文档等格式', style: NeonTheme.labelStyle(size: 11, color: NeonTheme.textSecondary.withOpacity(0.6))),
                  ],
                ),
              ),
            ),
          )
        else
          ...List.generate(_receipts.length, (index) => _buildReceiptItem(_receipts[index], index)),
      ],
    );
  }

  Widget _buildReceiptItem(Receipt receipt, int index) {
    final statusColor = receipt.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NeonTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(receipt.documentType.icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.documentType.label, style: NeonTheme.bodyStyle(size: 14)),
                const SizedBox(height: 4),
                if (receipt.fileName != null)
                  Text(receipt.fileName!, style: NeonTheme.labelStyle(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis)
                else if (receipt.taxNumber != null)
                  Text('税号: ${receipt.taxNumber}', style: NeonTheme.labelStyle(size: 11)),
                if (receipt.parseStatus != ParseStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          receipt.parseStatus == ParseStatus.completed ? Icons.check_circle : 
                          receipt.parseStatus == ParseStatus.parsing ? Icons.hourglass_empty : Icons.error,
                          size: 12,
                          color: receipt.parseStatus == ParseStatus.completed ? NeonTheme.neonGreen : NeonTheme.neonYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(receipt.parseStatus.label, style: NeonTheme.labelStyle(size: 10)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(receipt.isValid ? '已验证' : '待验证', style: NeonTheme.labelStyle(size: 10, color: statusColor)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: NeonTheme.textSecondary),
            onPressed: () => setState(() => _receipts.removeAt(index)),
          ),
        ],
      ),
    );
  }

  void _addReceipt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReceiptSheet(
        onAdd: (receipt) => setState(() => _receipts.add(receipt)),
        validateTaxNumber: context.read<ExpenseProvider>().validateTaxNumber,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final expense = Expense(
      id: const Uuid().v4(),
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _date,
      category: _category,
      description: _descController.text.isEmpty ? null : _descController.text,
      receipts: _receipts,
    );

    await context.read<ExpenseProvider>().addExpense(expense);
    if (mounted) Navigator.pop(context);
  }
}

// 新的凭证添加Sheet
class AddReceiptSheet extends StatefulWidget {
  final Function(Receipt) onAdd;
  final bool Function(String) validateTaxNumber;

  const AddReceiptSheet({super.key, required this.onAdd, required this.validateTaxNumber});

  @override
  State<AddReceiptSheet> createState() => _AddReceiptSheetState();
}

class _AddReceiptSheetState extends State<AddReceiptSheet> {
  DocumentType _documentType = DocumentType.invoice;
  final _taxController = TextEditingController();
  bool _isValid = false;
  String? _fileName;
  String? _filePath;
  int? _fileSize;
  FileFormat _fileFormat = FileFormat.image;
  bool _isUploading = false;

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: NeonTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: NeonTheme.neonPink.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('添加凭证', style: NeonTheme.titleStyle(size: 18)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: NeonTheme.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('凭证类型', style: NeonTheme.labelStyle(size: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: DocumentType.values.map((type) => _buildTypeChip(type)).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('上传文件', style: NeonTheme.labelStyle(size: 14)),
                  const SizedBox(height: 12),
                  _buildFileUploadArea(),
                  if (_documentType == DocumentType.invoice) ...[
                    const SizedBox(height: 24),
                    Text('税号验证 (可选)', style: NeonTheme.labelStyle(size: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxController,
                      style: NeonTheme.bodyStyle(size: 14),
                      decoration: InputDecoration(
                        hintText: '如: 12100000470095016Q',
                        suffixIcon: IconButton(
                          icon: Icon(_isValid ? Icons.check_circle : Icons.verified_outlined, color: _isValid ? NeonTheme.neonGreen : NeonTheme.textSecondary),
                          onPressed: _validateTax,
                        ),
                      ),
                      onChanged: (v) {
                        if (_isValid) setState(() => _isValid = false);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      label: '确认添加',
                      icon: Icons.add,
                      isLoading: _isUploading,
                      onPressed: _addReceipt,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(DocumentType type) {
    final isSelected = _documentType == type;
    return GestureDetector(
      onTap: () => setState(() => _documentType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NeonTheme.neonCyan.withOpacity(0.2) : NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? NeonTheme.neonCyan : NeonTheme.neonPink.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 18, color: isSelected ? NeonTheme.neonCyan : NeonTheme.textSecondary),
            const SizedBox(width: 8),
            Text(type.label, style: NeonTheme.bodyStyle(size: 13, color: isSelected ? NeonTheme.neonCyan : NeonTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadArea() {
    if (_fileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonTheme.neonGreen.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(_fileFormat.icon, color: NeonTheme.neonGreen, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fileName!, style: NeonTheme.bodyStyle(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_fileSize != null)
                    Text('${(_fileSize! / 1024).toStringAsFixed(1)} KB', style: NeonTheme.labelStyle(size: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: NeonTheme.textSecondary),
              onPressed: () => setState(() {
                _fileName = null;
                _filePath = null;
                _fileSize = null;
              }),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonTheme.neonPink.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: NeonTheme.neonPink.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('点击选择文件', style: NeonTheme.bodyStyle(size: 14, color: NeonTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(
              '支持: ${_documentType.allowedExtensions.join(", ")}',
              style: NeonTheme.labelStyle(size: 11, color: NeonTheme.textSecondary.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _documentType.allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          _filePath = file.path;
          _fileSize = file.size;
          _fileFormat = FileFormat.fromExtension(file.extension ?? '');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件选择失败: $e', style: NeonTheme.bodyStyle(size: 12)), backgroundColor: Colors.red),
      );
    }
  }

  void _validateTax() {
    final valid = widget.validateTaxNumber(_taxController.text);
    setState(() => _isValid = valid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(valid ? '税号格式正确' : '税号格式无效', style: NeonTheme.bodyStyle(size: 12)),
        backgroundColor: valid ? NeonTheme.neonGreen : Colors.red,
      ),
    );
  }

  void _addReceipt() {
    final receipt = Receipt(
      id: const Uuid().v4(),
      documentType: _documentType,
      fileFormat: _fileFormat,
      fileName: _fileName,
      filePath: _filePath,
      fileSize: _fileSize,
      taxNumber: _documentType == DocumentType.invoice && _taxController.text.isNotEmpty ? _taxController.text : null,
      uploadedAt: DateTime.now(),
      isValid: _isValid,
    );
    widget.onAdd(receipt);
    Navigator.pop(context);
  }
}
