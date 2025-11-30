import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_widgets.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddExpenseDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: NeonTheme.bgCard,
          indicatorColor: NeonTheme.neonPink.withOpacity(0.3),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Records')),
            NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Analytics')),
            NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
          ],
        ),
        const VerticalDivider(width: 1, color: NeonTheme.neonPink),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildNarrowLayout() => _buildContent();

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const ExpenseListScreen();
      case 1:
        return const AnalyticsScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const ExpenseListScreen();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: NeonTheme.bgCard,
        border: Border(top: BorderSide(color: NeonTheme.neonPink.withOpacity(0.3))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: NeonTheme.neonPink,
        unselectedItemColor: NeonTheme.textSecondary,
        selectedLabelStyle: NeonTheme.labelStyle(size: 11),
        unselectedLabelStyle: NeonTheme.labelStyle(size: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseSheet(),
    );
  }
}

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: NeonTheme.neonPink));
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => NeonTheme.neonGradient.createShader(bounds),
                      child: Text('EXPENSE TRACKER', style: NeonTheme.titleStyle(size: 22)),
                    ),
                    const SizedBox(height: 8),
                    Text('报销管理系统', style: NeonTheme.labelStyle(size: 14)),
                    const SizedBox(height: 24),
                    _buildStatsRow(provider),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: provider.expenses.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = provider.expenses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExpenseListItem(
                              expense: expense,
                              onTap: () => _showExpenseDetail(context, expense),
                              onDelete: () => provider.deleteExpense(expense.id),
                            ),
                          );
                        },
                        childCount: provider.expenses.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.receipt_long, size: 64, color: NeonTheme.neonPink.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('NO RECORDS', style: NeonTheme.titleStyle(size: 16, color: NeonTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('点击 + 添加报销记录', style: NeonTheme.labelStyle(size: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ExpenseProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: '总金额',
                value: '¥${provider.totalAmount.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: NeonTheme.neonPink,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: StatCard(
                title: '待审核',
                value: '¥${provider.pendingAmount.toStringAsFixed(0)}',
                icon: Icons.pending_actions,
                color: NeonTheme.neonYellow,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: StatCard(
                title: '已通过',
                value: '¥${provider.approvedAmount.toStringAsFixed(0)}',
                icon: Icons.check_circle,
                color: NeonTheme.neonGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseDetail(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseDetailSheet(expense: expense),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: NeonCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeonTheme.neonPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(expense.category.icon, color: NeonTheme.neonPink, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: NeonTheme.bodyStyle(size: 14, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(expense.category.label, style: NeonTheme.labelStyle(size: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: expense.status.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(expense.status.label, style: NeonTheme.labelStyle(size: 10, color: expense.status.color)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('¥${expense.amount.toStringAsFixed(2)}', style: NeonTheme.bodyStyle(size: 15, color: NeonTheme.neonGreen, weight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('MM/dd').format(expense.date), style: NeonTheme.labelStyle(size: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailSheet({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: NeonTheme.neonPink.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                        child: Icon(expense.category.icon, color: NeonTheme.neonPink, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.title, style: NeonTheme.bodyStyle(size: 16, weight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: expense.status.color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(expense.status.label, style: NeonTheme.labelStyle(size: 11, color: expense.status.color)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDetailRow('金额', '¥${expense.amount.toStringAsFixed(2)}', NeonTheme.neonGreen),
                  _buildDetailRow('类别', expense.category.label, NeonTheme.neonCyan),
                  _buildDetailRow('日期', DateFormat('yyyy-MM-dd').format(expense.date), NeonTheme.neonYellow),
                  if (expense.description != null) _buildDetailRow('备注', expense.description!, NeonTheme.textSecondary),
                  const SizedBox(height: 24),
                  Text('凭证 (${expense.receipts.length})', style: NeonTheme.bodyStyle(size: 14, color: NeonTheme.textSecondary)),
                  const SizedBox(height: 12),
                  if (expense.receipts.isEmpty)
                    Text('无凭证', style: NeonTheme.labelStyle(size: 12, color: NeonTheme.textSecondary.withOpacity(0.5)))
                  else
                    ...expense.receipts.map((r) => _buildReceiptItem(r)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: NeonButton(
                          label: 'DELETE',
                          icon: Icons.delete,
                          color: Colors.red,
                          onPressed: () {
                            context.read<ExpenseProvider>().deleteExpense(expense.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: NeonTheme.labelStyle(size: 13))),
          Expanded(child: Text(value, style: NeonTheme.bodyStyle(size: 14, color: valueColor))),
        ],
      ),
    );
  }

  Widget _buildReceiptItem(Receipt r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeonTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: r.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow),
      ),
      child: Row(
        children: [
          Icon(r.type == 'invoice' ? Icons.receipt_long : Icons.payment, color: r.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.type == 'invoice' ? '发票' : '支付凭证', style: NeonTheme.bodyStyle(size: 13)),
                if (r.taxNumber != null) Text(r.taxNumber!, style: NeonTheme.labelStyle(size: 11)),
              ],
            ),
          ),
          Text(r.isValid ? '已验证' : '待验证', style: NeonTheme.labelStyle(size: 11, color: r.isValid ? NeonTheme.neonGreen : NeonTheme.neonYellow)),
        ],
      ),
    );
  }
}
