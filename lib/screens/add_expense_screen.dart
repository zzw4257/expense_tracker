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
            const Icon(Icons.attachment, size: 18, color: NeonTheme.neonCyan),
            const SizedBox(width: 8),
            Text('凭证', style: NeonTheme.labelStyle(size: 14)),
            if (_receipts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: NeonTheme.neonCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_receipts.length}', style: NeonTheme.labelStyle(size: 11, color: NeonTheme.neonCyan)),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: _addReceipt,
              icon: const Icon(Icons.add, size: 16),
              label: Text('上传', style: NeonTheme.bodyStyle(size: 12, color: NeonTheme.neonCyan)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_receipts.isEmpty)
          GestureDetector(
            onTap: _addReceipt,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: NeonTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeonTheme.neonPink.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 20, color: NeonTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Text('添加发票或凭证', style: NeonTheme.labelStyle(size: 13)),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_receipts.length, (index) => _buildReceiptChip(_receipts[index], index)),
          ),
      ],
    );
  }

  Widget _buildReceiptChip(Receipt receipt, int index) {
    final color = receipt.parseStatus == ParseStatus.completed 
        ? NeonTheme.neonGreen 
        : receipt.parseStatus == ParseStatus.parsing 
            ? NeonTheme.neonCyan 
            : NeonTheme.neonYellow;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: NeonTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(receipt.fileFormat.icon, size: 16, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              receipt.fileName ?? receipt.documentType.label,
              style: NeonTheme.labelStyle(size: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => setState(() => _receipts.removeAt(index)),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: NeonTheme.textSecondary),
            ),
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

// 简化的凭证上传组件 - 自动解析
class AddReceiptSheet extends StatefulWidget {
  final Function(Receipt) onAdd;
  final bool Function(String) validateTaxNumber;

  const AddReceiptSheet({super.key, required this.onAdd, required this.validateTaxNumber});

  @override
  State<AddReceiptSheet> createState() => _AddReceiptSheetState();
}

class _AddReceiptSheetState extends State<AddReceiptSheet> {
  String? _fileName;
  String? _filePath;
  int? _fileSize;
  FileFormat _fileFormat = FileFormat.image;
  bool _isUploading = false;
  String? _parseStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: NeonTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NeonTheme.neonPink.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: NeonTheme.neonCyan, size: 20),
                const SizedBox(width: 8),
                Text('上传凭证', style: NeonTheme.titleStyle(size: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: NeonTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 提示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '支持发票、收据、合同等，自动识别解析',
              style: NeonTheme.labelStyle(size: 12, color: NeonTheme.textSecondary.withOpacity(0.7)),
            ),
          ),
          const SizedBox(height: 20),
          // 上传区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildUploadArea(),
            ),
          ),
          // 底部按钮
          if (_fileName != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: NeonButton(
                  label: _isUploading ? '解析中...' : '确认上传',
                  icon: _isUploading ? Icons.hourglass_empty : Icons.check,
                  isLoading: _isUploading,
                  onPressed: _isUploading ? () {} : _uploadAndParse,
                ),
              ),
            ),
          if (_fileName == null) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    if (_fileName != null) {
      return _buildFilePreview();
    }
    return _buildDropZone();
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        decoration: BoxDecoration(
          color: NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeonTheme.neonPink.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NeonTheme.neonPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: NeonTheme.neonPink.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text('点击选择文件', style: NeonTheme.bodyStyle(size: 15)),
              const SizedBox(height: 8),
              Text(
                '图片 / PDF / 文档',
                style: NeonTheme.labelStyle(size: 12, color: NeonTheme.textSecondary.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonTheme.neonGreen.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 文件图标
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeonTheme.neonGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_fileFormat.icon, size: 36, color: NeonTheme.neonGreen),
          ),
          const SizedBox(height: 16),
          // 文件名
          Text(
            _fileName!,
            style: NeonTheme.bodyStyle(size: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 文件大小
          if (_fileSize != null)
            Text(
              _formatFileSize(_fileSize!),
              style: NeonTheme.labelStyle(size: 12),
            ),
          // 解析状态
          if (_parseStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NeonTheme.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NeonTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_parseStatus!, style: NeonTheme.labelStyle(size: 11, color: NeonTheme.neonCyan)),
                ],
              ),
            ),
          ],
          const Spacer(),
          // 重新选择
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text('重新选择', style: NeonTheme.labelStyle(size: 12)),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          _filePath = file.path;
          _fileSize = file.size;
          _fileFormat = FileFormat.fromExtension(file.extension ?? '');
          _parseStatus = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择失败', style: NeonTheme.bodyStyle(size: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndParse() async {
    if (_fileName == null) return;

    setState(() {
      _isUploading = true;
      _parseStatus = '准备解析...';
    });

    // 模拟解析过程（实际会调用OCR服务）
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _parseStatus = '识别文档类型...');
    
    await Future.delayed(const Duration(milliseconds: 300));

    // 根据文件名/格式自动判断类型
    DocumentType docType = _guessDocumentType(_fileName!);

    final receipt = Receipt(
      id: const Uuid().v4(),
      documentType: docType,
      fileFormat: _fileFormat,
      fileName: _fileName,
      filePath: _filePath,
      fileSize: _fileSize,
      parseStatus: ParseStatus.pending, // 标记待解析，后台异步处理
      uploadedAt: DateTime.now(),
      isValid: false,
    );

    widget.onAdd(receipt);
    if (mounted) Navigator.pop(context);
  }

  DocumentType _guessDocumentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('发票') || lower.contains('invoice') || lower.contains('fapiao')) {
      return DocumentType.invoice;
    }
    if (lower.contains('收据') || lower.contains('receipt')) {
      return DocumentType.receipt;
    }
    if (lower.contains('合同') || lower.contains('contract')) {
      return DocumentType.contract;
    }
    if (lower.contains('付款') || lower.contains('支付') || lower.contains('payment')) {
      return DocumentType.paymentProof;
    }
    // 默认按发票处理，OCR会进一步识别
    return DocumentType.invoice;
  }
}
