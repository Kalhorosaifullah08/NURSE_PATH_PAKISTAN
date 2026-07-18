import 'package:flutter/material.dart';

import 'data/sample_repository.dart';
import 'domain/models.dart';
import 'state/app_state.dart';

const navy = Color(0xff0C3044);
const navy2 = Color(0xff164A5F);
const teal = Color(0xff159A83);
const mint = Color(0xff62DCC1);
const canvas = Color(0xffF4F8F7);
const ink = Color(0xff122B3A);
const muted = Color(0xff637985);
const line = Color(0xffDCE8E5);
const warm = Color(0xffFFF3DC);

void main() => runApp(const NursePathApp());

class NursePathApp extends StatefulWidget {
  const NursePathApp({super.key});
  @override
  State<NursePathApp> createState() => _NursePathAppState();
}

class _NursePathAppState extends State<NursePathApp> {
  final state = AppState();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NursePath Pakistan',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: teal,
        secondary: mint,
        surface: Colors.white,
        onSurface: ink,
      ),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.12,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: -.6,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: muted),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: AppShell(state: state),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({required this.state, super.key});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int page = 0;
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
    final screens = [
      HomePage(
        state: widget.state,
        showLibrary: () => setState(() => page = 1),
      ),
      LibraryPage(state: widget.state),
      PracticePage(state: widget.state),
      ProfilePage(state: widget.state),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (desktop)
                  _DesktopNav(
                    selected: page,
                    onChanged: (value) => setState(() => page = value),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: screens[page],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  height: 72,
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xffDDF5EE),
                  selectedIndex: page,
                  onDestinationSelected: (value) =>
                      setState(() => page = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Today',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: 'Learn',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.psychology_alt_outlined),
                      selectedIcon: Icon(Icons.psychology_alt_rounded),
                      label: 'Practice',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DesktopNav extends StatelessWidget {
  const _DesktopNav({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    width: 226,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: _Logo(light: true),
        ),
        const SizedBox(height: 30),
        for (final item in const [
          (Icons.home_rounded, 'Today'),
          (Icons.menu_book_rounded, 'Learn'),
          (Icons.psychology_alt_rounded, 'Practice'),
          (Icons.person_rounded, 'Profile'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: ListTile(
              selected:
                  selected ==
                  const [
                    'Today',
                    'Learn',
                    'Practice',
                    'Profile',
                  ].indexOf(item.$2),
              selectedTileColor: const Color(0xff24566A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Icon(
                item.$1,
                color:
                    selected ==
                        const [
                          'Today',
                          'Learn',
                          'Practice',
                          'Profile',
                        ].indexOf(item.$2)
                    ? mint
                    : const Color(0xffAFC4CD),
              ),
              title: Text(
                item.$2,
                style: TextStyle(
                  color:
                      selected ==
                          const [
                            'Today',
                            'Learn',
                            'Practice',
                            'Profile',
                          ].indexOf(item.$2)
                      ? Colors.white
                      : const Color(0xffC0D0D6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => onChanged(
                const [
                  'Today',
                  'Learn',
                  'Practice',
                  'Profile',
                ].indexOf(item.$2),
              ),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff173F52),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: mint),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clinically reviewed learning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.state, required this.showLibrary, super.key});
  final AppState state;
  final VoidCallback showLibrary;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
    children: [
      Row(
        children: [
          const _Logo(),
          const Spacer(),
          _CircleButton(icon: Icons.search_rounded, onTap: showLibrary),
          const SizedBox(width: 8),
          _CircleButton(icon: Icons.notifications_none_rounded, onTap: () {}),
        ],
      ),
      const SizedBox(height: 34),
      LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > 760;
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: _Hero(state: state)),
                    const SizedBox(width: 18),
                    const Expanded(flex: 3, child: _ShiftCard()),
                  ],
                )
              : Column(
                  children: [
                    _Hero(state: state),
                    const SizedBox(height: 16),
                    const _ShiftCard(),
                  ],
                );
        },
      ),
      const SizedBox(height: 30),
      _SectionTitle(
        title: 'Your study pulse',
        action: 'See courses',
        onTap: showLibrary,
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, box) => GridView.count(
          crossAxisCount: box.maxWidth > 720 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: box.maxWidth > 720 ? 1.75 : 1.45,
          children: [
            _Metric(
              value: '${state.progress.length}',
              label: 'Completed',
              icon: Icons.check_rounded,
              color: const Color(0xffE2F7F0),
            ),
            _Metric(
              value: '${state.incorrect.length}',
              label: 'Review queue',
              icon: Icons.replay_rounded,
              color: const Color(0xffFFF1DC),
            ),
            const _Metric(
              value: '1 day',
              label: 'Study streak',
              icon: Icons.local_fire_department_rounded,
              color: Color(0xffFFE7EC),
            ),
            const _Metric(
              value: '35%',
              label: 'Weekly goal',
              icon: Icons.track_changes_rounded,
              color: Color(0xffE6F0FF),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      const _SectionTitle(title: 'Continue your course'),
      const SizedBox(height: 12),
      _CourseFocus(state: state),
      const SizedBox(height: 24),
      const _ClinicalPearl(),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [navy2, navy],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260C3044),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GOOD EVENING, FUTURE NURSE',
          style: TextStyle(
            color: mint,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Build confidence for\nyour next clinical shift.',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 13),
        const Text(
          'One focused lesson, one recall check, one step stronger.',
          style: TextStyle(
            color: Color(0xffC1D5DD),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LessonScreen(
                    lesson: SampleRepository.lesson,
                    state: state,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume lesson'),
              style: FilledButton.styleFrom(
                backgroundColor: mint,
                foregroundColor: navy,
              ),
            ),
            const Text(
              '8 min • Fundamentals of Nursing',
              style: TextStyle(
                color: Color(0xffBBD0D8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: warm,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xffF4DFC0)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Color(0xff98641B),
              size: 19,
            ),
            Spacer(),
            Text(
              'TODAY',
              style: TextStyle(
                color: Color(0xff98641B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '20 min',
                style: TextStyle(
                  fontSize: 30,
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Study plan',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: .35,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                backgroundColor: Color(0xffEBD8B9),
                color: Color(0xffC98529),
              ),
            ),
            SizedBox(width: 10),
            Text(
              '1/3',
              style: TextStyle(color: ink, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: navy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CourseFocus extends StatelessWidget {
  const _CourseFocus({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xffDFF5EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: teal,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fundamentals of Nursing I',
                  style: TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Unit 1 • Patient safety foundations',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: .35,
                  minHeight: 7,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  backgroundColor: Color(0xffE8F0EE),
                  color: teal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filled(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LessonScreen(lesson: SampleRepository.lesson, state: state),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ClinicalPearl extends StatelessWidget {
  const _ClinicalPearl();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xffE8F4FA),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_rounded, color: Color(0xff22749A)),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical pearl',
                style: TextStyle(color: ink, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 5),
              Text(
                'Gloves do not replace hand hygiene. Clean your hands at the indicated moments before and after glove use.',
                style: TextStyle(color: muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final courses = SampleRepository.courses
        .where((c) => c.semester == state.selectedSemester)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
      children: [
        const _PageHeader(
          kicker: 'YOUR BSN ROADMAP',
          title: 'Learn by semester',
          subtitle:
              'Every course follows the HEC Generic BSN pathway and moves from understanding to clinical recall.',
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            8,
            (i) => ChoiceChip(
              label: Text('Semester ${i + 1}'),
              selected: state.selectedSemester == i + 1,
              onSelected: (_) => state.chooseSemester(i + 1),
              selectedColor: navy,
              labelStyle: TextStyle(
                color: state.selectedSemester == i + 1 ? Colors.white : ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (state.selectedSemester == 1) ...[
          const _SemesterOneOverview(),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Semester ${state.selectedSemester} courses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${courses.length} courses',
              style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: box.maxWidth > 760 ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 152,
            ),
            itemBuilder: (context, index) =>
                _CourseCard(course: courses[index], state: state),
          ),
        ),
        if (courses.isEmpty) const _LockedSemester(),
      ],
    );
  }
}

class _SemesterOneOverview extends StatelessWidget {
  const _SemesterOneOverview();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [navy2, navy]),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEMESTER ONE AT A GLANCE',
          style: TextStyle(
            color: mint,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your complete first-semester pathway',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore every course, its official outcomes, credit load and evidence sources. Reviewed lessons and questions appear inside each course as they become ready.',
          style: TextStyle(color: Color(0xffC1D3DA), height: 1.45),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _OverviewPill(icon: Icons.menu_book_rounded, label: '7 courses'),
            _OverviewPill(icon: Icons.school_rounded, label: '17 credits'),
            _OverviewPill(
              icon: Icons.verified_rounded,
              label: 'HEC 2024 mapped',
            ),
          ],
        ),
      ],
    ),
  );
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: mint, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.state});
  final CourseSummary course;
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final ready = course.id == SampleRepository.lesson.courseId;
    final icons = [
      Icons.health_and_safety_rounded,
      Icons.biotech_rounded,
      Icons.psychology_rounded,
      Icons.monitor_heart_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
      Icons.computer_rounded,
    ];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CourseScreen(course: course, state: state),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: ready
                      ? const Color(0xffDFF5EF)
                      : const Color(0xffEEF3F4),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icons[course.title.length % icons.length],
                  color: ready ? teal : muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SampleRepository.courseCredits[course.id] ??
                          (ready ? '1 unit ready' : 'Curriculum mapped'),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          ready
                              ? Icons.play_circle_fill_rounded
                              : Icons.lock_clock_rounded,
                          size: 17,
                          color: ready ? teal : muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ready
                              ? 'Open course and study'
                              : 'View course outline',
                          style: TextStyle(
                            color: ready ? teal : muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedSemester extends StatelessWidget {
  const _LockedSemester();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: line),
    ),
    child: const Column(
      children: [
        Icon(Icons.route_rounded, color: teal, size: 40),
        SizedBox(height: 12),
        Text(
          'This semester is mapped',
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Lessons will appear here after academic and clinical review.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ],
    ),
  );
}

class PracticePage extends StatelessWidget {
  const PracticePage({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
    children: [
      const _PageHeader(
        kicker: 'ACTIVE RECALL',
        title: 'Practice with purpose',
        subtitle:
            'Short, focused question sets that adapt to what you need to review.',
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily clinical check',
                    style: TextStyle(
                      color: mint,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '10 questions\nabout patient safety',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'About 8 minutes',
                    style: TextStyle(color: Color(0xffBDD0D8)),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionScreen(
                    question: SampleRepository.questions.first,
                    state: state,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start'),
              style: FilledButton.styleFrom(
                backgroundColor: mint,
                foregroundColor: navy,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, box) => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: box.maxWidth > 720 ? 3 : 1,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: box.maxWidth > 720 ? 1.25 : 2.5,
          children: [
            _PracticeCard(
              icon: Icons.tune_rounded,
              title: 'Build a quiz',
              text: 'Choose course, topic and difficulty.',
              color: const Color(0xffE8F3FF),
              onTap: () {},
            ),
            _PracticeCard(
              icon: Icons.replay_rounded,
              title: 'Review mistakes',
              text: state.incorrect.isEmpty
                  ? 'Your review queue is clear.'
                  : '${state.incorrect.length} question needs review.',
              color: const Color(0xffFFF0E5),
              onTap: () {},
            ),
            _PracticeCard(
              icon: Icons.timer_rounded,
              title: 'Semester mock',
              text: 'Practice pacing under exam conditions.',
              color: const Color(0xffE5F7F0),
              onTap: () {},
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const _ClinicalPearl(),
    ],
  );
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title, text;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: navy),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
    children: [
      const _PageHeader(
        kicker: 'YOUR JOURNEY',
        title: 'Study profile',
        subtitle:
            'Manage progress, offline learning and your personal study plan.',
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [navy2, navy]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 31,
              backgroundColor: mint,
              child: Icon(Icons.person_rounded, color: navy, size: 34),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Future registered nurse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Semester 1 • Generic BSN',
                    style: TextStyle(color: Color(0xffBDD0D8)),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xff6E8B98)),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      for (final row in [
        (
          Icons.insights_rounded,
          'Learning progress',
          '${state.progress.length} activities completed',
        ),
        (
          Icons.download_for_offline_outlined,
          'Offline library',
          'Download semester packages',
        ),
        (
          Icons.notifications_active_outlined,
          'Study reminders',
          'Build a consistent routine',
        ),
        (
          Icons.shield_outlined,
          'Safety and privacy',
          'Clinical disclaimer and support',
        ),
      ])
        _ProfileItem(icon: row.$1, title: row.$2, detail: row.$3),
    ],
  );
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xffE1F5EF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: teal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class CourseScreen extends StatelessWidget {
  const CourseScreen({required this.course, required this.state, super.key});
  final CourseSummary course;
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final ready = course.id == SampleRepository.lesson.courseId;
    final outcomes =
        SampleRepository.courseOutcomes[course.id] ?? const <String>[];
    final credits = SampleRepository.courseCredits[course.id];
    final sources = SampleRepository.courseSources[course.id];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 34),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [navy2, navy]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEMESTER ${course.semester}',
                      style: const TextStyle(
                        color: mint,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ready
                          ? 'Build safe nursing foundations through short lessons and active recall.'
                          : 'Review the complete curriculum outline now. Detailed lessons will be added after academic review.',
                      style: const TextStyle(
                        color: Color(0xffC1D3DA),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (credits != null) ...[
                _CourseInfoStrip(credits: credits, ready: ready),
                const SizedBox(height: 24),
              ],
              if (outcomes.isNotEmpty) ...[
                Text(
                  'What you will learn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        for (var i = 0; i < outcomes.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == outcomes.length - 1 ? 0 : 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 25,
                                  height: 25,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffE1F5EF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    outcomes[i],
                                    style: const TextStyle(
                                      color: ink,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text('Study path', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (ready) ...[
                _StudyStep(
                  number: '01',
                  title: SampleRepository.lesson.title,
                  meta: 'Lesson • 8 minutes',
                  icon: Icons.auto_stories_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(
                        lesson: SampleRepository.lesson,
                        state: state,
                      ),
                    ),
                  ),
                ),
                _StudyStep(
                  number: '02',
                  title: 'Check your understanding',
                  meta: 'Quick check • 1 question',
                  icon: Icons.quiz_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionScreen(
                        question: SampleRepository.questions.first,
                        state: state,
                      ),
                    ),
                  ),
                ),
              ] else
                const _ContentReviewNotice(),
              if (sources != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Curriculum & evidence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const Icon(
                      Icons.verified_user_rounded,
                      color: teal,
                    ),
                    title: Text(
                      sources,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Course mapping is visible now; generated clinical content remains subject to academic review.',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseInfoStrip extends StatelessWidget {
  const _CourseInfoStrip({required this.credits, required this.ready});
  final String credits;
  final bool ready;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 22,
        runSpacing: 14,
        children: [
          _InfoPair(
            icon: Icons.school_rounded,
            label: 'Credit load',
            value: credits,
          ),
          _InfoPair(
            icon: ready ? Icons.play_circle_rounded : Icons.fact_check_rounded,
            label: 'Content status',
            value: ready
                ? 'Lesson available'
                : 'Outline available • lessons in review',
          ),
        ],
      ),
    ),
  );
}

class _InfoPair extends StatelessWidget {
  const _InfoPair({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: teal),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ],
  );
}

class _ContentReviewNotice extends StatelessWidget {
  const _ContentReviewNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xffFFF6E8),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffF1D6A8)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.rate_review_rounded, color: Color(0xff9A6412)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Detailed lessons, diagrams and questions are being checked for academic and clinical accuracy. The official course outcomes and evidence map above are available now.',
            style: TextStyle(
              color: ink,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StudyStep extends StatelessWidget {
  const _StudyStep({
    required this.number,
    required this.title,
    required this.meta,
    required this.icon,
    required this.onTap,
  });
  final String number, title, meta;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: teal,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffE2F5F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: teal),
          ],
        ),
      ),
    ),
  );
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({required this.lesson, required this.state, super.key});
  final Lesson lesson;
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => state.toggleBookmark(lesson.id),
          icon: Icon(
            state.bookmarks.contains(lesson.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
          children: [
            const Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: .65,
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    backgroundColor: line,
                    color: teal,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'LESSON 1 OF 2',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'FUNDAMENTALS OF NURSING I • UNIT 1',
              style: TextStyle(
                color: teal,
                fontSize: 11,
                letterSpacing: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(lesson.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffE3F5F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded, color: teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning outcome',
                          style: TextStyle(
                            color: teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lesson.objective,
                          style: const TextStyle(
                            color: ink,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < lesson.sections.length; i++)
              _LessonSection(index: i, text: lesson.sections[i]),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars_rounded, color: mint),
                      SizedBox(width: 8),
                      Text(
                        'Remember at the bedside',
                        style: TextStyle(
                          color: mint,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.summary,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.5,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffFFF1E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: Color(0xffA25B13),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Follow your institution’s infection-prevention policy and clinical supervisor guidance.',
                      style: TextStyle(
                        color: ink,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Evidence source',
              style: TextStyle(color: ink, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            ...lesson.references.map(
              (r) => Text(r, style: const TextStyle(color: muted)),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionScreen(
                    question: SampleRepository.questions.first,
                    state: state,
                  ),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Check my understanding'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LessonSection extends StatelessWidget {
  const _LessonSection({required this.index, required this.text});
  final int index;
  final String text;
  @override
  Widget build(BuildContext context) {
    final titles = ['Why this matters', 'The five moments', 'Apply it safely'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titles[index % titles.length],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    required this.question,
    required this.state,
    super.key,
  });
  final Mcq question;
  final AppState state;
  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    final correct = selected == widget.question.correctIndex;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Quick check',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
            children: [
              const Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 1,
                      minHeight: 6,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      backgroundColor: line,
                      color: teal,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '1 OF 1',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'PATIENT SAFETY • QUICK RECALL',
                style: TextStyle(
                  color: teal,
                  fontSize: 11,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.question.stem,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < widget.question.options.length; i++)
                _AnswerOption(
                  index: i,
                  label: widget.question.options[i],
                  selected: selected,
                  correct: widget.question.correctIndex,
                  onTap: answered
                      ? null
                      : () {
                          setState(() => selected = i);
                          widget.state.recordAnswer(widget.question, i);
                        },
                ),
              if (answered) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xffE0F6EF)
                        : const Color(0xffFFF0E4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            correct
                                ? Icons.check_circle_rounded
                                : Icons.refresh_rounded,
                            color: correct ? teal : const Color(0xffB96519),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            correct
                                ? 'Correct — well done'
                                : 'Review and remember',
                            style: TextStyle(
                              color: correct ? teal : const Color(0xffB96519),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.question.rationales[selected!],
                        style: const TextStyle(color: ink, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Finish activity'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.index,
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
  });
  final int index, correct;
  final String label;
  final int? selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final chosen = selected == index,
        correctOption = selected != null && correct == index,
        wrong = chosen && index != correct;
    final color = correctOption
        ? teal
        : wrong
        ? const Color(0xffC45E36)
        : line;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: correctOption
                  ? const Color(0xffE5F7F1)
                  : wrong
                  ? const Color(0xffFFF0EA)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color,
                width: chosen || correctOption ? 1.7 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chosen || correctOption
                        ? color
                        : const Color(0xffEFF4F3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: chosen || correctOption ? Colors.white : muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (correctOption) const Icon(Icons.check_rounded, color: teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: light ? const Color(0xff1F5266) : navy,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: mint, size: 22),
            Positioned(
              bottom: 7,
              child: Text(
                '+',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NURSEPATH',
            style: TextStyle(
              color: light ? Colors.white : ink,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Pakistan',
            style: TextStyle(
              color: mint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ],
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      side: const BorderSide(color: line),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.kicker,
    required this.title,
    required this.subtitle,
  });
  final String kicker, title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        kicker,
        style: const TextStyle(
          color: teal,
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
        ),
      ),
    ],
  );
}
