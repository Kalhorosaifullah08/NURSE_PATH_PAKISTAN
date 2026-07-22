import 'package:flutter/material.dart';

class VisualAidCard extends StatelessWidget {
  const VisualAidCard({
    required this.type,
    required this.title,
    required this.purpose,
    required this.content,
    required this.caption,
    required this.altText,
    super.key,
  });

  final String type;
  final String title;
  final String purpose;
  final List<String> content;
  final String caption;
  final String altText;

  IconData get icon => switch (type) {
    'diagram' => Icons.schema_rounded,
    'flowchart' => Icons.account_tree_rounded,
    'comparison_table' => Icons.table_chart_rounded,
    'timeline' => Icons.timeline_rounded,
    'concept_map' => Icons.hub_rounded,
    'data_chart' => Icons.bar_chart_rounded,
    _ => Icons.image_outlined,
  };

  Color get color => switch (type) {
    'diagram' => const Color(0xff10B981), // Emerald
    'flowchart' => const Color(0xff3B82F6), // Blue
    'comparison_table' => const Color(0xff8B5CF6), // Purple
    'timeline' => const Color(0xffF59E0B), // Amber
    'concept_map' => const Color(0xffEC4899), // Pink
    'data_chart' => const Color(0xff06B6D4), // Cyan
    _ => const Color(0xff64748B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.zoom_in_rounded, size: 18, color: Color(0xff64748B)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0F172A),
                  ),
                ),
                if (purpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    purpose,
                    style: const TextStyle(fontSize: 13, color: Color(0xff64748B)),
                  ),
                ],
                const SizedBox(height: 14),
                // Content Steps / Flowchart Nodes
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xff1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xff64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xff64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
