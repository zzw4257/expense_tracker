import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => NeonTheme.neonGradient.createShader(bounds),
                child: Text('ANALYTICS', style: GoogleFonts.pressStart2p(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text('数据分析', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
              const SizedBox(height: 24),
              _buildSummaryCards(provider),
              const SizedBox(height: 24),
              _buildCategoryChart(provider),
              const SizedBox(height: 24),
              _buildMonthlyChart(provider),
              const SizedBox(height: 24),
              _buildCategoryBreakdown(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(ExpenseProvider provider) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: '总记录',
            value: '${provider.expenses.length}',
            icon: Icons.receipt,
            color: NeonTheme.neonPink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: '平均金额',
            value: provider.expenses.isEmpty ? '¥0' : '¥${(provider.totalAmount / provider.expenses.length).toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: NeonTheme.neonCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(ExpenseProvider provider) {
    final breakdown = provider.categoryBreakdown;
    if (breakdown.isEmpty) {
      return NeonCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text('暂无数据', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
          ),
        ),
      );
    }

    final colors = [
      NeonTheme.neonPink,
      NeonTheme.neonCyan,
      NeonTheme.neonGreen,
      NeonTheme.neonYellow,
      NeonTheme.neonOrange,
      Colors.purple,
    ];

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类别分布', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: breakdown.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage = (data.value / provider.totalAmount * 100);
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: data.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(ExpenseProvider provider) {
    final breakdown = provider.monthlyBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final sortedKeys = breakdown.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('月度趋势', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: breakdown.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '¥${rod.toY.toStringAsFixed(0)}',
                        GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= recentKeys.length) return const SizedBox.shrink();
                        final month = recentKeys[value.toInt()].split('-')[1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(month, style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.textSecondary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: recentKeys.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: breakdown[entry.value]!,
                        gradient: NeonTheme.neonGradient,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider) {
    final breakdown = provider.categoryBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final sortedEntries = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类别明细', style: GoogleFonts.pressStart2p(fontSize: 10, color: NeonTheme.textSecondary)),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final percentage = entry.value / provider.totalAmount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(entry.key.icon, size: 16, color: NeonTheme.neonPink),
                      const SizedBox(width: 8),
                      Text(entry.key.label, style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white)),
                      const Spacer(),
                      Text('¥${entry.value.toStringAsFixed(0)}', style: GoogleFonts.pressStart2p(fontSize: 8, color: NeonTheme.neonGreen)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: NeonTheme.bgCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(NeonTheme.neonPink),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
