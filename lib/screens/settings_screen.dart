import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/expense_provider.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => NeonTheme.neonGradient.createShader(bounds),
            child: Text('SETTINGS', style: GoogleFonts.pressStart2p(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text('设置', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
          const SizedBox(height: 24),
          _buildExportSection(context),
          const SizedBox(height: 16),
          _buildDataSection(context),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download, color: NeonTheme.neonCyan),
              const SizedBox(width: 12),
              Text('导出数据', style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  label: 'CSV',
                  icon: Icons.table_chart,
                  color: NeonTheme.neonGreen,
                  onPressed: () => _exportCsv(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton(
                  label: 'JSON',
                  icon: Icons.code,
                  color: NeonTheme.neonCyan,
                  onPressed: () => _exportJson(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: NeonTheme.neonYellow),
              const SizedBox(width: 12),
              Text('数据管理', style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ExpenseProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildInfoRow('记录数', '${provider.expenses.length}'),
                  _buildInfoRow('总金额', '¥${provider.totalAmount.toStringAsFixed(2)}'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'CLEAR ALL',
              icon: Icons.delete_forever,
              color: Colors.red,
              onPressed: () => _showClearDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: NeonTheme.neonPink),
              const SizedBox(width: 12),
              Text('关于', style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('版本', 'v1.0.0'),
          _buildInfoRow('开发者', 'Expense Tracker'),
          const SizedBox(height: 8),
          Text(
            '报销管理应用，支持记录、凭证管理、数据分析和导出功能。',
            style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
          Text(value, style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white)),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final csv = provider.exportToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV已复制到剪贴板', style: GoogleFonts.pressStart2p(fontSize: 8)),
        backgroundColor: NeonTheme.neonGreen,
      ),
    );
  }

  void _exportJson(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses') ?? '[]';
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('JSON已复制到剪贴板', style: GoogleFonts.pressStart2p(fontSize: 8)),
        backgroundColor: NeonTheme.neonCyan,
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeonTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        title: Text('确认清除', style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.white)),
        content: Text('此操作将删除所有报销记录，无法恢复。', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
          ),
          NeonButton(
            label: '确认',
            color: Colors.red,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('expenses');
              if (context.mounted) {
                context.read<ExpenseProvider>().loadExpenses();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
