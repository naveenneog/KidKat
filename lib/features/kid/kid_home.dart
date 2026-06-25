import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/duration_utils.dart';
import '../../core/theme.dart';
import '../../data/models/topic.dart';
import '../../data/providers.dart';
import '../../widgets/brand.dart';

/// The child's home: friendly interest tiles and a big "Start watching" button.
/// A small lock opens the parent area. Honors the daily time limit.
class KidHome extends ConsumerWidget {
  const KidHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(parentConfigProvider);
    final remaining = ref.watch(remainingSecondsProvider);
    final topics = config.selectedTopicIds
        .map(topicById)
        .whereType<Topic>()
        .toList();
    final locked = remaining <= 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(remaining: remaining),
            Expanded(
              child: locked
                  ? const _LockedView()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Text('Hi there! 👋',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want to learn today?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: KidColors.ink.withValues(alpha: .7)),
                        ),
                        const SizedBox(height: 20),
                        if (topics.isEmpty)
                          _EmptyTopics()
                        else
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.05,
                            children: [
                              for (final t in topics)
                                _TopicTile(
                                  topic: t,
                                  onTap: () =>
                                      context.go('/session', extra: [t.id]),
                                ),
                            ],
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
            if (!locked && topics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: BigButton(
                    label: 'Start watching',
                    icon: Icons.play_circle_fill_rounded,
                    onPressed: () => context.go('/session',
                        extra: config.selectedTopicIds),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const KidLogo(size: 44),
          const SizedBox(width: 10),
          Text('KidKat',
              style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: KidColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 18, color: KidColors.green),
                const SizedBox(width: 6),
                Text('${formatDuration(remaining)} left',
                    style: const TextStyle(
                        color: KidColors.green,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Parents',
            onPressed: () => context.go('/gate'),
            icon: const Icon(Icons.lock_outline_rounded,
                color: KidColors.ink),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.onTap});
  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: topic.color,
      borderRadius: BorderRadius.circular(26),
      elevation: 4,
      shadowColor: topic.color.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(topic.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                topic.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTopics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🐱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'No interests yet. Ask a grown-up to add some in Parent settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Open Parents',
            icon: Icons.lock_outline_rounded,
            onPressed: () => context.go('/gate'),
          ),
        ],
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text("That's all for today!",
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'You used all your learning time. Come back tomorrow for more!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            BigButton(
              label: 'Parents',
              icon: Icons.lock_outline_rounded,
              color: KidColors.blue,
              onPressed: () => context.go('/gate'),
            ),
          ],
        ),
      ),
    );
  }
}
