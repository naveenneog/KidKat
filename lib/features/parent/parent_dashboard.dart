import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/allowlisted_channel.dart';
import '../../data/models/parent_config.dart';
import '../../data/models/topic.dart';
import '../../data/providers.dart';
import '../../widgets/api_key_setup.dart';

/// Parent control center: API key, interests, channel allowlist, time limits,
/// short-length, safe search and a compliance note.
class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(parentConfigProvider);
    final notifier = ref.read(parentConfigProvider.notifier);
    final watched = ref.watch(watchTimeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Parent settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            title: 'YouTube Data API key',
            icon: Icons.key_rounded,
            child: const ApiKeySetup(),
          ),
          _Section(
            title: 'Interests',
            icon: Icons.interests_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kTopics)
                  FilterChip(
                    label: Text('${t.emoji} ${t.label}'),
                    selected: config.selectedTopicIds.contains(t.id),
                    onSelected: (_) => notifier.toggleTopic(t.id),
                  ),
              ],
            ),
          ),
          _Section(
            title: 'Approved channels',
            icon: Icons.verified_user_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.allowlist.isEmpty)
                  Text('No channels added yet.',
                      style: TextStyle(
                          color: KidColors.ink.withValues(alpha: .6))),
                for (final ch in config.allowlist)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline,
                        color: KidColors.purple),
                    title: Text(ch.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      onPressed: () => notifier.removeChannel(ch),
                    ),
                  ),
                const Divider(),
                const Text('Quick add trusted channels:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in kSuggestedChannels)
                      if (!config.allowlist
                          .any((c) => c.title == s.title))
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(s.title),
                          onPressed: () => notifier.addChannel(
                            AllowlistedChannel(
                                title: s.title, query: s.query),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _showAddChannelDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add custom channel'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only show approved channels'),
                  subtitle: const Text(
                      'Strictest mode: ignore open educational search.'),
                  value: config.restrictToAllowlist,
                  onChanged: notifier.setRestrictToAllowlist,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Time & limits',
            icon: Icons.timer_rounded,
            child: Column(
              children: [
                _Stepper(
                  label: 'Daily limit',
                  value: '${config.dailyLimitMinutes} min',
                  onMinus: config.dailyLimitMinutes > 5
                      ? () => notifier
                          .setDailyLimit(config.dailyLimitMinutes - 5)
                      : null,
                  onPlus: config.dailyLimitMinutes < 180
                      ? () => notifier
                          .setDailyLimit(config.dailyLimitMinutes + 5)
                      : null,
                ),
                _Stepper(
                  label: 'Videos per session',
                  value: '${config.sessionVideoCount}',
                  onMinus: config.sessionVideoCount > 3
                      ? () => notifier
                          .setSessionCount(config.sessionVideoCount - 1)
                      : null,
                  onPlus: config.sessionVideoCount < 15
                      ? () => notifier
                          .setSessionCount(config.sessionVideoCount + 1)
                      : null,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Video length',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ShortLength>(
                  segments: const [
                    ButtonSegment(
                        value: ShortLength.shortsOnly,
                        label: Text('≤1 min')),
                    ButtonSegment(
                        value: ShortLength.shortClips,
                        label: Text('≤4 min')),
                  ],
                  selected: {config.shortLength},
                  onSelectionChanged: (s) =>
                      notifier.setShortLength(s.first),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict Safe Search'),
                  value: config.safeSearchStrict,
                  onChanged: notifier.setSafeSearch,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text("Reset today's watch time"),
                  subtitle: Text('Used so far: ${watched ~/ 60} min'),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(watchTimeProvider.notifier).reset();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Watch time reset for today')),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'About & compliance',
            icon: Icons.info_outline_rounded,
            child: const Text(
              'KidKat is a curated educational front-end. It uses the official '
              'YouTube Data API to discover videos and the official YouTube '
              'player to play them — it never downloads streams and does not '
              'alter YouTube\'s recommendations. There is no YouTube Kids login; '
              'all controls live on this device. Finite sessions and daily '
              'limits are built in to prevent endless scrolling.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddChannelDialog() async {
    final titleCtrl = TextEditingController();
    final queryCtrl = TextEditingController();
    final notifier = ref.read(parentConfigProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: queryCtrl,
              decoration: const InputDecoration(
                  labelText: 'Channel name to search'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final query = queryCtrl.text.trim().isEmpty
                  ? title
                  : queryCtrl.text.trim();
              if (title.isNotEmpty) {
                notifier.addChannel(
                    AllowlistedChannel(title: title, query: query));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: KidColors.purple),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });
  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          IconButton.filledTonal(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 70,
            child: Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          IconButton.filledTonal(
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
