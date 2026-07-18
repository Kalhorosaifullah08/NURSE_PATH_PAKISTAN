import 'package:flutter/material.dart';

import 'data/sample_repository.dart';
import 'domain/models.dart';

void main() => runApp(const OwnerApp());

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'NursePath Pakistan Owner', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff12355b)), useMaterial3: true), home: const OwnerDashboard());
}

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  ReviewState lessonState = SampleRepository.lesson.reviewState;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('BSN Path • Owner operations'), actions: const [Padding(padding: EdgeInsets.all(16), child: Chip(label: Text('INTERNAL BETA')))]), body: Row(children: [
    NavigationRail(selectedIndex: 0, onDestinationSelected: (_) {}, labelType: NavigationRailLabelType.all, destinations: const [
      NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Overview')),
      NavigationRailDestination(icon: Icon(Icons.account_tree), label: Text('Curriculum')),
      NavigationRailDestination(icon: Icon(Icons.auto_awesome), label: Text('Generate')),
      NavigationRailDestination(icon: Icon(Icons.fact_check), label: Text('Review')),
      NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('Packages')),
      NavigationRailDestination(icon: Icon(Icons.report_problem), label: Text('Reports')),
    ]),
    const VerticalDivider(width: 1),
    Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
      Text('Operations overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _Metric(label: 'Semesters', value: '8', icon: Icons.school),
        _Metric(label: 'Course shells', value: '${SampleRepository.courses.length}', icon: Icons.menu_book),
        _Metric(label: 'Owner review', value: lessonState == ReviewState.ownerReview ? '1' : '0', icon: Icons.fact_check),
        const _Metric(label: 'GenAI credit', value: r'$1,000', icon: Icons.savings),
      ]),
      const SizedBox(height: 24),
      Text('Clinical approval queue', style: Theme.of(context).textTheme.titleLarge),
      Card(child: ListTile(
        leading: const Icon(Icons.health_and_safety),
        title: Text(SampleRepository.lesson.title),
        subtitle: Text('Patient safety • ${lessonState.name} • ${SampleRepository.lesson.references.first}'),
        trailing: Wrap(spacing: 8, children: [OutlinedButton(onPressed: () => setState(() => lessonState = ReviewState.rejected), child: const Text('Reject')), FilledButton(onPressed: () => setState(() => lessonState = ReviewState.approved), child: const Text('Approve'))]),
      )),
      const SizedBox(height: 24),
      Text('Content workflow', style: Theme.of(context).textTheme.titleLarge),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Source collected  →  Draft generated  →  Critic review  →  Independent verification  →  Deterministic QA  →  Risk classification  →  Owner review  →  Package'))),
      const Card(child: ListTile(leading: Icon(Icons.lock), title: Text('Production publishing disabled'), subtitle: Text('Clinical approval and release checks are enforced server-side.'))),
    ])),
  ]));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 220, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineSmall), Text(label)])]))));
}
