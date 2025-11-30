import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/settings.dart';

class ClusterService {
  final double similarityThreshold;

  ClusterService({this.similarityThreshold = 0.7});

  // 分析费用记录，生成聚类建议
  List<ClusterSuggestion> analyzeClusters(List<Expense> expenses) {
    if (expenses.length < 2) return [];

    final suggestions = <ClusterSuggestion>[];
    final processed = <String>{};

    for (int i = 0; i < expenses.length; i++) {
      if (processed.contains(expenses[i].id)) continue;

      final cluster = <Expense>[expenses[i]];
      
      for (int j = i + 1; j < expenses.length; j++) {
        if (processed.contains(expenses[j].id)) continue;

        final similarity = _calculateSimilarity(expenses[i], expenses[j]);
        if (similarity >= similarityThreshold) {
          cluster.add(expenses[j]);
        }
      }

      if (cluster.length >= 2) {
        // 标记已处理
        for (final e in cluster) {
          processed.add(e.id);
        }

        // 生成建议
        final reason = _generateReason(cluster);
        final avgSimilarity = _calculateAverageSimilarity(cluster);

        suggestions.add(ClusterSuggestion(
          id: const Uuid().v4(),
          expenseIds: cluster.map((e) => e.id).toList(),
          reason: reason,
          similarity: avgSimilarity,
          createdAt: DateTime.now(),
        ));
      }
    }

    return suggestions;
  }

  // 计算两个费用记录的相似度
  double _calculateSimilarity(Expense a, Expense b) {
    double score = 0.0;
    int factors = 0;

    // 1. 金额相似度 (权重: 0.3)
    final amountDiff = (a.amount - b.amount).abs();
    final maxAmount = max(a.amount, b.amount);
    if (maxAmount > 0) {
      final amountSimilarity = 1 - (amountDiff / maxAmount);
      score += amountSimilarity * 0.3;
      factors++;
    }

    // 2. 时间相似度 (权重: 0.25)
    final daysDiff = a.date.difference(b.date).inDays.abs();
    final timeSimilarity = max(0.0, 1 - (daysDiff / 30)); // 30天内
    score += timeSimilarity * 0.25;
    factors++;

    // 3. 类别相似度 (权重: 0.25)
    if (a.category == b.category) {
      score += 0.25;
    }
    factors++;

    // 4. 标题相似度 (权重: 0.2)
    final titleSimilarity = _calculateStringSimilarity(a.title, b.title);
    score += titleSimilarity * 0.2;
    factors++;

    return score;
  }

  // 计算字符串相似度 (Jaccard)
  double _calculateStringSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    final setA = a.toLowerCase().split('').toSet();
    final setB = b.toLowerCase().split('').toSet();

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;

    return union > 0 ? intersection / union : 0.0;
  }

  // 计算聚类平均相似度
  double _calculateAverageSimilarity(List<Expense> cluster) {
    if (cluster.length < 2) return 0.0;

    double totalSimilarity = 0.0;
    int pairs = 0;

    for (int i = 0; i < cluster.length; i++) {
      for (int j = i + 1; j < cluster.length; j++) {
        totalSimilarity += _calculateSimilarity(cluster[i], cluster[j]);
        pairs++;
      }
    }

    return pairs > 0 ? totalSimilarity / pairs : 0.0;
  }

  // 生成聚类原因描述
  String _generateReason(List<Expense> cluster) {
    final reasons = <String>[];

    // 检查金额相似
    final amounts = cluster.map((e) => e.amount).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final amountVariance = amounts.map((a) => (a - avgAmount).abs()).reduce((a, b) => a + b) / amounts.length;
    if (amountVariance / avgAmount < 0.2) {
      reasons.add('金额相近 (约¥${avgAmount.toStringAsFixed(0)})');
    }

    // 检查时间相近
    final dates = cluster.map((e) => e.date).toList();
    dates.sort();
    final daySpan = dates.last.difference(dates.first).inDays;
    if (daySpan <= 7) {
      reasons.add('时间相近 (${daySpan}天内)');
    }

    // 检查类别相同
    final categories = cluster.map((e) => e.category).toSet();
    if (categories.length == 1) {
      reasons.add('同类别 (${categories.first.label})');
    }

    // 检查标题相似
    final titles = cluster.map((e) => e.title).toList();
    final commonWords = _findCommonWords(titles);
    if (commonWords.isNotEmpty) {
      reasons.add('标题相似');
    }

    return reasons.isEmpty ? '可能相关的记录' : reasons.join('、');
  }

  // 查找共同词汇
  List<String> _findCommonWords(List<String> titles) {
    if (titles.isEmpty) return [];

    final wordSets = titles.map((t) => t.toLowerCase().split(RegExp(r'\s+')).toSet()).toList();
    var common = wordSets.first;

    for (int i = 1; i < wordSets.length; i++) {
      common = common.intersection(wordSets[i]);
    }

    return common.where((w) => w.length > 1).toList();
  }
}
