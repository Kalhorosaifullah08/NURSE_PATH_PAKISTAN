enum RiskLevel { general, academic, clinical, pharmacology, calculation, emergency, patientSafety }

enum ReviewState { draft, automatedReview, ownerReview, approved, rejected, published }

class CourseSummary {
  const CourseSummary({required this.id, required this.title, required this.semester, required this.isSample});
  final String id;
  final String title;
  final int semester;
  final bool isSample;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.objective,
    required this.sections,
    required this.summary,
    required this.references,
    required this.risk,
    required this.reviewState,
  });
  final String id;
  final String courseId;
  final String title;
  final String objective;
  final List<String> sections;
  final String summary;
  final List<String> references;
  final RiskLevel risk;
  final ReviewState reviewState;
}

class Mcq {
  const Mcq({
    required this.id,
    required this.courseId,
    required this.stem,
    required this.options,
    required this.correctIndex,
    required this.rationales,
    required this.risk,
    required this.reviewState,
  });
  final String id;
  final String courseId;
  final String stem;
  final List<String> options;
  final int correctIndex;
  final List<String> rationales;
  final RiskLevel risk;
  final ReviewState reviewState;
}

class ProgressEvent {
  const ProgressEvent({required this.id, required this.itemId, required this.kind, required this.occurredAt, required this.score});
  final String id;
  final String itemId;
  final String kind;
  final DateTime occurredAt;
  final double score;
}

class Entitlement {
  const Entitlement({required this.semester, required this.active, required this.source});
  final int semester;
  final bool active;
  final String source;
}
