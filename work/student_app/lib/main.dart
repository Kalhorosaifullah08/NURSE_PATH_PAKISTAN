import 'package:flutter/material.dart';

import 'data/sample_repository.dart';
import 'domain/models.dart';
import 'state/app_state.dart';

const _ink = Color(0xff102A43);
const _muted = Color(0xff627D98);
const _mint = Color(0xff4ED7B2);
const _deepMint = Color(0xff188B78);
const _canvas = Color(0xffF4F8F8);
const _line = Color(0xffD9E5E3);

void main() => runApp(const BsnPathApp());

class BsnPathApp extends StatefulWidget {
  const BsnPathApp({super.key});

  @override
  State<BsnPathApp> createState() => _BsnPathAppState();
}

class _BsnPathAppState extends State<BsnPathApp> {
  final state = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NursePath Pakistan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: const ColorScheme.light(
          primary: _deepMint,
          secondary: _mint,
          surface: Colors.white,
          onSurface: _ink,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, height: 1.08, color: _ink, fontWeight: FontWeight.w800, letterSpacing: -1),
          headlineMedium: TextStyle(fontSize: 25, height: 1.15, color: _ink, fontWeight: FontWeight.w800, letterSpacing: -.5),
          titleLarge: TextStyle(fontSize: 19, color: _ink, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 16, color: _ink, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: _ink),
          bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: _muted),
          labelLarge: TextStyle(fontSize: 13, letterSpacing: .2, fontWeight: FontWeight.w700),
        ),
      ),
      home: AppShell(state: state),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.state, super.key});
  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(state: widget.state, openCourses: () => setState(() => tab = 1)),
      CourseLibrary(state: widget.state),
      PracticeHub(state: widget.state),
      ProfilePage(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x220B1B2A), blurRadius: 18, offset: Offset(0, 8))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded, label: 'Today', selected: tab == 0, onTap: () => setState(() => tab = 0)),
              _NavItem(icon: Icons.auto_stories_rounded, label: 'Learn', selected: tab == 1, onTap: () => setState(() => tab = 1)),
              _NavItem(icon: Icons.bolt_rounded, label: 'Practice', selected: tab == 2, onTap: () => setState(() => tab = 2)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: tab == 3, onTap: () => setState(() => tab = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(color: selected ? const Color(0xff25485A) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? _mint : const Color(0xffB8C9D1), size: 21),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xffB8C9D1), fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.state, required this.openCourses, super.key});
  final AppState state;
  final VoidCallback openCourses;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _BrandMark(),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BSN PATH', style: TextStyle(fontWeight: FontWeight.w900, color: _ink, letterSpacing: 1.1)),
          Text('Pakistan', style: TextStyle(color: _deepMint, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
        Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _line)), child: const Icon(Icons.notifications_none_rounded, color: _ink)),
      ]),
      const SizedBox(height: 34),
      const Text('Good evening,', style: TextStyle(fontSize: 16, color: _muted, fontWeight: FontWeight.w600)),
      const Text('Ready for a stronger shift?', style: TextStyle(fontSize: 29, height: 1.15, color: _ink, fontWeight: FontWeight.w800, letterSpacing: -.8)),
      const SizedBox(height: 22),
      _TodayCard(state: state),
      const SizedBox(height: 26),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Your learning pulse', style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: openCourses, child: const Text('View courses')),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(value: '${state.progress.length}', label: 'Activities', icon: Icons.check_circle_outline_rounded, tint: const Color(0xffE0F7F0))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${state.incorrect.length}', label: 'To review', icon: Icons.refresh_rounded, tint: const Color(0xffFFF0DD))),
        const SizedBox(width: 12),
        const Expanded(child: _StatCard(value: '1', label: 'Day streak', icon: Icons.local_fire_department_outlined, tint: Color(0xffFDE5EB))),
      ]),
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Continue learning', style: Theme.of(context).textTheme.titleLarge),
        const Text('Semester 1', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      _ContinueCard(state: state),
      const SizedBox(height: 26),
      Text('Designed for your degree', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      const Text('Every lesson, quiz, flashcard and mock is organised around your BSN semester—not a generic question bank.'),
    ]),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(14)),
    child: const Stack(alignment: Alignment.center, children: [
      Icon(Icons.favorite_rounded, color: _mint, size: 21),
      Positioned(bottom: 7, child: Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
    ]),
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xff133B4E), Color(0xff0D273B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x2E0B1B2A), blurRadius: 18, offset: Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xff246176), borderRadius: BorderRadius.circular(99)), child: const Text('TODAY’S PLAN', style: TextStyle(color: Color(0xffB7F7E5), fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w800))),
        const Spacer(),
        Text('${state.progress.length}/3 done', style: const TextStyle(color: Color(0xffC4D6DE), fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 16),
      const Text('Build clinical confidence\nin 20 minutes.', style: TextStyle(color: Colors.white, fontSize: 24, height: 1.15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text('Foundations of Nursing · Unit 1', style: TextStyle(color: Color(0xffB7C9D2), fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: const LinearProgressIndicator(value: .35, minHeight: 9, color: _mint, backgroundColor: Color(0xff31566A)))),
        const SizedBox(width: 14),
        FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: SampleRepository.lesson, state: state))), icon: const Icon(Icons.play_arrow_rounded, size: 18), label: const Text('Resume'), style: FilledButton.styleFrom(backgroundColor: _mint, foregroundColor: _ink, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13))),
      ]),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, required this.tint});
  final String value;
  final String label;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _ink, size: 17)),
      const SizedBox(height: 13),
      Text(value, style: const TextStyle(fontSize: 21, color: _ink, fontWeight: FontWeight.w800)),
      Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: SampleRepository.lesson, state: state))),
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xffE3F6F1), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.health_and_safety_outlined, color: _deepMint, size: 28)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The Five Moments for Hand Hygiene', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, height: 1.25)),
          SizedBox(height: 5),
          Text('Lesson · 8 min left', style: TextStyle(color: _muted, fontSize: 13)),
        ])),
        const Icon(Icons.arrow_forward_rounded, color: _deepMint),
      ]),
    ),
  );
}

class CourseLibrary extends StatelessWidget {
  const CourseLibrary({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final courses = SampleRepository.courses.where((course) => course.semester == state.selectedSemester).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 12), child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your degree', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)), Text('Course library', style: TextStyle(fontSize: 27, color: _ink, fontWeight: FontWeight.w800))])),
        DropdownButtonHideUnderline(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: _line)), child: DropdownButton<int>(value: state.selectedSemester, items: List.generate(8, (index) => DropdownMenuItem(value: index + 1, child: Text('Sem ${index + 1}'))), onChanged: (value) { if (value != null) state.chooseSemester(value); }))),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Study each course in the order your semester needs.', style: Theme.of(context).textTheme.bodyMedium)),
      const SizedBox(height: 12),
      Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), itemCount: courses.length + 1, itemBuilder: (context, index) {
        if (index == courses.length) return const _SemesterRoadmap();
        final course = courses[index];
        final available = course.id == SampleRepository.lesson.courseId;
        return _CourseTile(course: course, available: available, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseScreen(course: course, state: state))));
      })),
    ]);
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course, required this.available, required this.onTap});
  final CourseSummary course;
  final bool available;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Ink(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)), child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: available ? const Color(0xffE3F6F1) : const Color(0xffEDF2F4), borderRadius: BorderRadius.circular(15)), child: Icon(available ? Icons.menu_book_rounded : Icons.auto_stories_outlined, color: available ? _deepMint : _muted)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(course.title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(available ? '1 lesson · 1 quiz ready' : 'Curriculum mapped · content in preparation', style: const TextStyle(color: _muted, fontSize: 12)),
      ])),
      Icon(available ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded, color: available ? _deepMint : _muted, size: 20),
    ]))),
  );
}

class _SemesterRoadmap extends StatelessWidget {
  const _SemesterRoadmap();
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xffE8F2F1), borderRadius: BorderRadius.circular(20)), child: const Row(children: [
    Icon(Icons.route_rounded, color: _deepMint), SizedBox(width: 12), Expanded(child: Text('Your full 4-year nursing pathway is mapped here. Unlock each semester when you need it.', style: TextStyle(color: _ink, height: 1.4, fontWeight: FontWeight.w600))),
  ]));
}

class CourseScreen extends StatelessWidget {
  const CourseScreen({required this.course, required this.state, super.key});
  final CourseSummary course;
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final available = course.id == SampleRepository.lesson.courseId;
    return Scaffold(
      appBar: AppBar(backgroundColor: _canvas, surfaceTintColor: Colors.transparent, title: const Text('Course overview', style: TextStyle(color: _ink, fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SEMESTER ${course.semester}', style: const TextStyle(color: _mint, letterSpacing: 1.1, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 10), Text(course.title, style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12), Text(available ? 'Start your first study unit today.' : 'This course is mapped and will become available after content review.', style: const TextStyle(color: Color(0xffBBD0D8), height: 1.45)),
        ])),
        const SizedBox(height: 22),
        Text('Study path', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (available) ...[
          _LessonStep(number: '01', title: SampleRepository.lesson.title, detail: 'Lesson · 8 minutes', complete: false, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: SampleRepository.lesson, state: state)))),
          _LessonStep(number: '02', title: 'Check your understanding', detail: 'Quiz · 1 question', complete: false, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionScreen(question: SampleRepository.questions.first, state: state)))),
        ] else const _EmptyCourseState(),
      ]),
    );
  }
}

class _LessonStep extends StatelessWidget {
  const _LessonStep({required this.number, required this.title, required this.detail, required this.complete, required this.onTap});
  final String number;
  final String title;
  final String detail;
  final bool complete;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Ink(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)), child: Row(children: [
    Text(number, style: const TextStyle(color: _deepMint, fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(detail, style: const TextStyle(color: _muted, fontSize: 12))])), const Icon(Icons.arrow_forward_rounded, color: _deepMint),
  ])));
}

class _EmptyCourseState extends StatelessWidget {
  const _EmptyCourseState();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.auto_awesome_outlined, color: _deepMint), SizedBox(height: 12), Text('This course is being prepared', style: TextStyle(fontSize: 17, color: _ink, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('The owner workflow will generate, review and package content before it is released to students.', style: TextStyle(color: _muted, height: 1.45)),
  ]));
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({required this.lesson, required this.state, super.key});
  final Lesson lesson;
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _canvas, surfaceTintColor: Colors.transparent, actions: [IconButton(onPressed: () => state.toggleBookmark(lesson.id), icon: Icon(state.bookmarks.contains(lesson.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _ink))]),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), children: [
      const Text('FOUNDATIONS OF NURSING · UNIT 1', style: TextStyle(color: _deepMint, letterSpacing: .9, fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12), Text(lesson.title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xffE8F5F2), borderRadius: BorderRadius.circular(17)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.flag_outlined, color: _deepMint), const SizedBox(width: 10), Expanded(child: Text(lesson.objective, style: const TextStyle(color: _ink, height: 1.45, fontWeight: FontWeight.w600)))])),
      const SizedBox(height: 26), ...lesson.sections.map((section) => Padding(padding: const EdgeInsets.only(bottom: 19), child: Text(section, style: Theme.of(context).textTheme.bodyLarge))),
      const SizedBox(height: 4), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Key takeaway', style: TextStyle(color: _mint, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(lesson.summary, style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 16, fontWeight: FontWeight.w600))])),
      const SizedBox(height: 22), const Text('Source', style: TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 5), ...lesson.references.map((reference) => Text(reference, style: const TextStyle(color: _muted))),
      const SizedBox(height: 24), FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionScreen(question: SampleRepository.questions.first, state: state))), style: FilledButton.styleFrom(backgroundColor: _deepMint, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Continue to quick check')),
    ]),
  );
}

class PracticeHub extends StatelessWidget {
  const PracticeHub({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 26), children: [
    const Text('Practice smarter', style: TextStyle(fontSize: 27, color: _ink, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6), const Text('Turn your weak areas into your strongest subjects.'), const SizedBox(height: 22),
    _PracticeAction(icon: Icons.bolt_rounded, tint: const Color(0xffFFF1D6), title: 'Daily 10', subtitle: 'A focused free practice set for today', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionScreen(question: SampleRepository.questions.first, state: state)))),
    _PracticeAction(icon: Icons.tune_rounded, tint: const Color(0xffE6F4FF), title: 'Create a quiz', subtitle: 'Choose a course, topic and difficulty', onTap: () {}),
    _PracticeAction(icon: Icons.timer_outlined, tint: const Color(0xffE5F8F2), title: 'Semester mock', subtitle: 'Practice under exam conditions', onTap: () {}),
    _PracticeAction(icon: Icons.replay_rounded, tint: const Color(0xffFDE9EF), title: 'Review mistakes', subtitle: state.incorrect.isEmpty ? 'Nothing to review yet' : '${state.incorrect.length} question waiting for you', onTap: () {}),
    const SizedBox(height: 18), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xffFFF8E9), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.lightbulb_outline_rounded, color: Color(0xffA66700)), SizedBox(width: 12), Expanded(child: Text('Active recall beats rereading. Test yourself after every lesson.', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, height: 1.4)))])),
  ]);
}

class _PracticeAction extends StatelessWidget {
  const _PracticeAction({required this.icon, required this.tint, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Ink(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: _ink)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12))])), const Icon(Icons.arrow_forward_ios_rounded, color: _muted, size: 16)]))));
}

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({required this.question, required this.state, super.key});
  final Mcq question;
  final AppState state;
  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int? selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _canvas, surfaceTintColor: Colors.transparent, title: const Text('Quick check', style: TextStyle(color: _ink, fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Row(children: [Text('QUESTION 1 OF 1', style: TextStyle(color: _deepMint, letterSpacing: .8, fontWeight: FontWeight.w800, fontSize: 11)), Spacer(), Text('Foundation', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 17), Text(widget.question.stem, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 22),
      RadioGroup<int>(groupValue: selected, onChanged: selected == null ? (value) { if (value != null) { setState(() => selected = value); widget.state.recordAnswer(widget.question, value); } } : (_) {}, child: Column(children: [for (var index = 0; index < widget.question.options.length; index++) _QuestionOption(index: index, label: widget.question.options[index], selected: selected, correct: widget.question.correctIndex)])),
      if (selected != null) ...[
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: selected == widget.question.correctIndex ? const Color(0xffE3F7F1) : const Color(0xffFFF1E1), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(selected == widget.question.correctIndex ? 'That’s right.' : 'Almost — review this.', style: TextStyle(color: selected == widget.question.correctIndex ? _deepMint : const Color(0xffB45C00), fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(widget.question.rationales[selected!], style: const TextStyle(color: _ink, height: 1.45))])),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          style: FilledButton.styleFrom(backgroundColor: _deepMint, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Finish activity'),
        ),
      ],
    ]),
  );
}

class _QuestionOption extends StatelessWidget {
  const _QuestionOption({required this.index, required this.label, required this.selected, required this.correct});
  final int index;
  final String label;
  final int? selected;
  final int correct;
  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    final correctAnswer = selected != null && index == correct;
    final wrong = active && selected != correct;
    final color = correctAnswer ? _deepMint : wrong ? const Color(0xffD06A3A) : active ? _ink : _line;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: selected == null ? () => RadioGroup.maybeOf<int>(context)?.onChanged(index) : null, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), decoration: BoxDecoration(color: active || correctAnswer ? color.withValues(alpha: .08) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color, width: active || correctAnswer ? 1.6 : 1)), child: Row(children: [Container(width: 27, height: 27, alignment: Alignment.center, decoration: BoxDecoration(color: active || correctAnswer ? color : const Color(0xffF1F5F5), shape: BoxShape.circle), child: Text(String.fromCharCode(65 + index), style: TextStyle(color: active || correctAnswer ? Colors.white : _muted, fontWeight: FontWeight.w800))), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)))])))),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 26), children: [
    const Text('Your space', style: TextStyle(fontSize: 27, color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(24)), child: const Row(children: [CircleAvatar(radius: 25, backgroundColor: _mint, child: Icon(Icons.person_rounded, color: _ink, size: 28)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your BSN journey starts here', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)), SizedBox(height: 3), Text('Sign in to save your plan across devices', style: TextStyle(color: Color(0xffB8CBD3), fontSize: 13))]))])),
    const SizedBox(height: 20),
    _ProfileRow(icon: Icons.cloud_sync_outlined, title: 'Study progress', detail: '${state.progress.length} activities saved locally'),
    _ProfileRow(icon: Icons.download_done_outlined, title: 'Offline downloads', detail: 'Semester packages will appear here'),
    _ProfileRow(icon: Icons.workspace_premium_outlined, title: 'Your access', detail: state.entitlements.isEmpty ? 'Free learning plan' : 'Semester access active'),
    _ProfileRow(icon: Icons.settings_outlined, title: 'Study preferences', detail: 'Reminders and examination date'),
    _ProfileRow(icon: Icons.privacy_tip_outlined, title: 'Privacy and support', detail: 'Manage your account or report a concern'),
  ]);
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)), child: Row(children: [Icon(icon, color: _deepMint), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: _muted, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: _muted)]));
}
