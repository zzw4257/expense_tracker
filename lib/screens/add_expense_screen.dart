import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => NeonTheme.neonGradient.createShader(bounds),
                  child: Text('NEW EXPENSE', style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.white)),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: NeonTheme.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(controller: _titleController, label: '标题', hint: '报销项目名称', validator: (v) => v?.isEmpty == true ? '请输入标题' : null),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _descController, label: '备注', hint: '可选', maxLines: 3),
                    const SizedBox(height: 24),
                    _buildReceiptSection(),
                    const SizedBox(height: 32),
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
      style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('类别', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((cat) {
            final isSelected = _category == cat;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? NeonTheme.neonPink.withOpacity(0.3) : NeonTheme.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? NeonTheme.neonPink : NeonTheme.neonPink.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 16, color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(cat.label, style: GoogleFonts.pressStart2p(fontSize: 8, color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonTheme.neonPink.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: NeonTheme.neonPink, size: 20),
            const SizedBox(width: 12),
            Text(DateFormat('yyyy-MM-dd').format(_date), style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white)),
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
            Text('凭证', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
            const Spacer(),
            TextButton.icon(onPressed: _addReceipt, icon: const Icon(Icons.add, size: 16), label: Text('添加', style: GoogleFonts.pressStart2p(fontSize: 8))),
          ],
        ),
        const SizedBox(height: 8),
        if (_receipts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeonTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeonTheme.neonPink.withOpacity(0.2)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt, size: 32, color: NeonTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text('点击添加发票或支付凭证', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...List.generate(_receipts.length, (index) {
            final receipt = _receipts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeonTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: receipt.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow),
              ),
              child: Row(
                children: [
                  Icon(receipt.type == 'invoice' ? Icons.receipt_long : Icons.payment, color: receipt.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(receipt.type == 'invoice' ? '发票' : '支付凭证', style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white)),
                        if (receipt.taxNumber != null) Text('税号: ${receipt.taxNumber}', style: GoogleFonts.pressStart2p(fontSize: 6, color: NeonTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: (receipt.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(receipt.isValid ? '已验证' : '待验证', style: GoogleFonts.pressStart2p(fontSize: 6, color: receipt.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow)),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 16, color: NeonTheme.textSecondary), onPressed: () => setState(() => _receipts.removeAt(index))),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _addReceipt() {
    showDialog(
      context: context,
      builder: (context) => AddReceiptDialog(
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

class AddReceiptDialog extends StatefulWidget {
  final Function(Receipt) onAdd;
  final bool Function(String) validateTaxNumber;

  const AddReceiptDialog({super.key, required this.onAdd, required this.validateTaxNumber});

  @override
  State<AddReceiptDialog> createState() => _AddReceiptDialogState();
}

class _AddReceiptDialogState extends State<AddReceiptDialog> {
  String _type = 'invoice';
  final _taxController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NeonTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: NeonTheme.neonPink.withOpacity(0.5))),
      title: Text('添加凭证', style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类型', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [_buildTypeChip('invoice', '发票'), const SizedBox(width: 8), _buildTypeChip('payment', '支付凭证')]),
          if (_type == 'invoice') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _taxController,
              style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
              decoration: InputDecoration(
                labelText: '税号',
                hintText: '如: 12100000470095016Q',
                suffixIcon: IconButton(
                  icon: Icon(_isValid ? Icons.check_circle : Icons.help_outline, color: _isValid ? NeonTheme.neonGreen : NeonTheme.textSecondary),
                  onPressed: () {
                    final valid = widget.validateTaxNumber(_taxController.text);
                    setState(() => _isValid = valid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(valid ? '税号格式正确' : '税号格式无效', style: GoogleFonts.pressStart2p(fontSize: 8)),
                        backgroundColor: valid ? NeonTheme.neonGreen : Colors.red,
                      ),
                    );
                  },
                ),
              ),
              onChanged: (v) {
                if (_isValid) setState(() => _isValid = false);
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary))),
        NeonButton(
          label: '添加',
          onPressed: () {
            final receipt = Receipt(id: const Uuid().v4(), type: _type, taxNumber: _type == 'invoice' ? _taxController.text : null, uploadedAt: DateTime.now(), isValid: _isValid);
            widget.onAdd(receipt);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeonTheme.neonPink.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary),
        ),
        child: Text(label, style: GoogleFonts.pressStart2p(fontSize: 8, color: isSelected ? NeonTheme.neonPink : NeonTheme.textSecondary)),
      ),
    );
  }
}
