import '../domain/models.dart';

class SampleRepository {
  static const courses = <CourseSummary>[
    CourseSummary(id: 's1-fon', title: 'Foundations of Nursing', semester: 1, isSample: true),
    CourseSummary(id: 's1-anatomy', title: 'Anatomy and Physiology', semester: 1, isSample: true),
    CourseSummary(id: 's2-biochem', title: 'Biochemistry', semester: 2, isSample: true),
    CourseSummary(id: 's3-ahn1', title: 'Adult Health Nursing I', semester: 3, isSample: true),
    CourseSummary(id: 's4-ahn2', title: 'Adult Health Nursing II', semester: 4, isSample: true),
    CourseSummary(id: 's5-pediatric', title: 'Pediatric Nursing', semester: 5, isSample: true),
    CourseSummary(id: 's6-mental', title: 'Mental Health Nursing', semester: 6, isSample: true),
    CourseSummary(id: 's7-critical', title: 'Critical Care Nursing', semester: 7, isSample: true),
    CourseSummary(id: 's8-leadership', title: 'Leadership and Management in Nursing', semester: 8, isSample: true),
  ];

  static const lesson = Lesson(
    id: 'lesson-hand-hygiene',
    courseId: 's1-fon',
    title: 'The Five Moments for Hand Hygiene',
    objective: 'Recognize when hand hygiene is required during routine patient care.',
    sections: [
      'Hand hygiene interrupts transmission of microorganisms between patients, staff, and the care environment.',
      'The five moments are: before touching a patient; before a clean or aseptic procedure; after body-fluid exposure risk; after touching a patient; and after touching patient surroundings.',
      'Use local infection-prevention policy to choose between alcohol-based hand rub and soap and water.',
    ],
    summary: 'Perform hand hygiene at the point of care before and after the defined patient-care interactions.',
    references: ['World Health Organization — My 5 Moments for Hand Hygiene'],
    risk: RiskLevel.patientSafety,
    reviewState: ReviewState.ownerReview,
  );

  static const questions = <Mcq>[
    Mcq(
      id: 'mcq-hand-hygiene-1',
      courseId: 's1-fon',
      stem: 'Which action is one of the WHO five moments for hand hygiene?',
      options: ['Before touching a patient', 'Only at the beginning of a shift', 'Only when gloves tear', 'After writing personal notes'],
      correctIndex: 0,
      rationales: [
        'Correct. Hand hygiene is required before touching a patient.',
        'Incorrect. Hand hygiene is linked to care interactions, not only shift boundaries.',
        'Incorrect. Glove use does not replace hand hygiene.',
        'Incorrect. Personal note-taking is not one of the five defined moments.',
      ],
      risk: RiskLevel.patientSafety,
      reviewState: ReviewState.ownerReview,
    ),
  ];
}
