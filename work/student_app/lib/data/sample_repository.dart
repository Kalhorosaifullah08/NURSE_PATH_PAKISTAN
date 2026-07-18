import '../domain/models.dart';

class SampleRepository {
  static const semesterOneCredits = 17;

  static const courseCredits = <String, String>{
    's1-fon': '3 credits • 2 theory + 1 skills lab',
    's1-anatomy': '3 credits • 2.5 theory + 0.5 lab',
    's1-microbiology': '2 credits • 1.5 theory + 0.5 lab',
    's1-biochemistry': '2 credits • 1.5 theory + 0.5 lab',
    's1-english': '3 theory credits',
    's1-ict': '2 credits • 1 theory + 1 lab',
    's1-pakistan': '2 theory credits',
  };

  static const courseOutcomes = <String, List<String>>{
    's1-fon': [
      'Explain the development, professional role and scope of nursing in Pakistan.',
      'Use health models, patient needs and the nursing process to prioritize care.',
      'Demonstrate safe fundamental nursing procedures and therapeutic communication.',
      'Include cultural, spiritual and bio-psychosocial factors in nursing decisions.',
    ],
    's1-anatomy': [
      'Connect the structure and function of the integumentary, musculoskeletal, circulatory and digestive systems.',
      'Explain how homeostasis maintains normal body function.',
      'Apply anatomy and physiology concepts to nursing observations and care.',
    ],
    's1-microbiology': [
      'Classify common disease-causing microorganisms.',
      'Compare methods used to detect, control and destroy microbes.',
      'Apply infection-control practices in hospital and community settings.',
      'Perform basic microbiology laboratory procedures safely.',
    ],
    's1-biochemistry': [
      'Differentiate proteins, carbohydrates, lipids, enzymes and hormones.',
      'Explain their roles in metabolism and normal physiology.',
      'Relate core biochemical processes to nursing care.',
      'Interpret basic biochemical test reports in clinical context.',
    ],
    's1-english': [
      'Communicate clearly in academic and clinical settings.',
      'Build accurate sentences, paragraphs and professional messages.',
      'Read, summarize and reference information responsibly.',
    ],
    's1-ict': [
      'Use computers, internet research and cloud tools responsibly.',
      'Create clear documents, spreadsheets and presentations.',
      'Apply digital safety and information-literacy principles to study and healthcare.',
    ],
    's1-pakistan': [
      'Explain the ideological foundations of Pakistan.',
      'Recognize the structure, rights and responsibilities described by the Constitution.',
      'Relate citizenship and constitutional principles to professional conduct.',
    ],
  };

  static const courseSources = <String, String>{
    's1-fon': 'HEC BSN 2024 • Open RN Nursing Fundamentals',
    's1-anatomy': 'HEC BSN 2024 • OpenStax Anatomy & Physiology 2e',
    's1-microbiology': 'HEC BSN 2024 • OpenStax Microbiology',
    's1-biochemistry': 'HEC BSN 2024 • OpenStax Biology 2e',
    's1-english': 'HEC Undergraduate Policy • OpenStax Writing Guide',
    's1-ict': 'HEC Undergraduate Policy • OpenStax Workplace Software Skills',
    's1-pakistan': 'HEC Undergraduate Policy • Constitution of Pakistan',
  };

  static const courses = <CourseSummary>[
    CourseSummary(
      id: 's1-fon',
      title: 'Fundamentals of Nursing I',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-anatomy',
      title: 'Anatomy & Physiology I',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-microbiology',
      title: 'Microbiology',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-biochemistry',
      title: 'Biochemistry',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-english',
      title: 'Functional English',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-ict',
      title: 'Information & Communication Technology',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's1-pakistan',
      title: 'Ideology & Constitution of Pakistan',
      semester: 1,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-fon',
      title: 'Fundamentals of Nursing II',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-anatomy',
      title: 'Anatomy & Physiology II',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-quantitative',
      title: 'Quantitative Reasoning I',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-nutrition',
      title: 'Applied Nutrition',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-theory',
      title: 'Theoretical Basis of Nursing',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's2-ethics',
      title: 'Islamic Studies / Ethics',
      semester: 2,
      isSample: true,
    ),
    CourseSummary(
      id: 's3-ahn1',
      title: 'Adult Health Nursing I',
      semester: 3,
      isSample: true,
    ),
    CourseSummary(
      id: 's4-ahn2',
      title: 'Adult Health Nursing II',
      semester: 4,
      isSample: true,
    ),
    CourseSummary(
      id: 's5-pediatric',
      title: 'Pediatric Nursing',
      semester: 5,
      isSample: true,
    ),
    CourseSummary(
      id: 's6-mental',
      title: 'Mental Health Nursing',
      semester: 6,
      isSample: true,
    ),
    CourseSummary(
      id: 's7-critical',
      title: 'Critical Care Nursing',
      semester: 7,
      isSample: true,
    ),
    CourseSummary(
      id: 's8-leadership',
      title: 'Leadership and Management in Nursing',
      semester: 8,
      isSample: true,
    ),
  ];

  static const lesson = Lesson(
    id: 'lesson-hand-hygiene',
    courseId: 's1-fon',
    title: 'The Five Moments for Hand Hygiene',
    objective:
        'Recognize when hand hygiene is required during routine patient care.',
    sections: [
      'Hand hygiene interrupts transmission of microorganisms between patients, staff, and the care environment.',
      'The five moments are: before touching a patient; before a clean or aseptic procedure; after body-fluid exposure risk; after touching a patient; and after touching patient surroundings.',
      'Use local infection-prevention policy to choose between alcohol-based hand rub and soap and water.',
    ],
    summary:
        'Perform hand hygiene at the point of care before and after the defined patient-care interactions.',
    references: ['World Health Organization — My 5 Moments for Hand Hygiene'],
    risk: RiskLevel.patientSafety,
    reviewState: ReviewState.ownerReview,
  );

  static const questions = <Mcq>[
    Mcq(
      id: 'mcq-hand-hygiene-1',
      courseId: 's1-fon',
      stem: 'Which action is one of the WHO five moments for hand hygiene?',
      options: [
        'Before touching a patient',
        'Only at the beginning of a shift',
        'Only when gloves tear',
        'After writing personal notes',
      ],
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
