import 'package:flutter/material.dart';

class ReadinessPredictorCard extends StatelessWidget {
  const ReadinessPredictorCard({
    required this.completedCount,
    required this.incorrectCount,
    required this.totalQuestionBank,
    super.key,
  });

  final int completedCount;
  final int incorrectCount;
  final int totalQuestionBank;

  double get accuracy {
    if (completedCount == 0) return 0.0;
    final correct = completedCount - incorrectCount;
    return (correct / completedCount).clamp(0.0, 1.0);
  }

  double get coverage {
    if (totalQuestionBank == 0) return 0.0;
    return (completedCount / totalQuestionBank).clamp(0.0, 1.0);
  }

  double get passProbability {
    if (completedCount < 5) return 0.0;
    // Readiness formula: 70% weight on accuracy, 30% weight on question bank coverage
    final score = (accuracy * 0.70) + (coverage * 0.30);
    return (score * 100).clamp(0.0, 99.0);
  }

  String get readinessLabel {
    final score = passProbability;
    if (score >= 85) return 'High Pass Probability';
    if (score >= 70) return 'Moderate Readiness';
    if (score >= 50) return 'Needs Active Recall Review';
    return 'Early Study Phase';
  }

  Color get readinessColor {
    final score = passProbability;
    if (score >= 85) return const Color(0xff10B981); // Emerald
    if (score >= 70) return const Color(0xffF59E0B); // Amber
    if (score >= 50) return const Color(0xff3B82F6); // Blue
    return const Color(0xff64748B); // Slate
  }

  @override
  Widget build(BuildContext context) {
    final prob = passProbability;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: readinessColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics_rounded, color: readinessColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Readiness & Score Predictor',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    Text(
                      'Calculated 100% offline via spaced recall algorithm',
                      style: TextStyle(fontSize: 11, color: Color(0xff64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prob > 0 ? '${prob.toStringAsFixed(0)}%' : '--',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: readinessColor,
                    ),
                  ),
                  Text(
                    readinessLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: readinessColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(accuracy * 100).toStringAsFixed(0)}% Accuracy',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount of $totalQuestionBank Items',
                    style: const TextStyle(fontSize: 12, color: Color(0xff64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prob / 100.0,
              minHeight: 8,
              backgroundColor: const Color(0xffF1F5F9),
              color: readinessColor,
            ),
          ),
        ],
      ),
    );
  }
}
