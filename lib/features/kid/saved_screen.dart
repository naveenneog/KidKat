import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models/session_args.dart';
import '../../data/providers.dart';
import '../../widgets/brand.dart';

/// Shows the child's bookmarked videos and lets them replay them.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedVideosProvider);

    return Scaffold(
      body: KidBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go('/home'),
                    ),
                    const Icon(Icons.bookmark_rounded,
                        color: KidColors.purple),
                    const SizedBox(width: 8),
                    Text('Saved videos',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: saved.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: saved.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final v = saved[i];
                          return RoundedCard(
                            onTap: () => context.go('/session',
                                extra: SessionArgs(
                                    videos: saved.sublist(i))),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    v.thumbnailUrl,
                                    width: 96,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 96,
                                      height: 64,
                                      color: KidColors.purple
                                          .withValues(alpha: 0.15),
                                      child: const Icon(Icons.movie_rounded,
                                          color: KidColors.purple),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(v.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(v.channelTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: KidColors.ink
                                                  .withValues(alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.bookmark_rounded,
                                      color: KidColors.purple),
                                  onPressed: () => ref
                                      .read(savedVideosProvider.notifier)
                                      .remove(v.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (saved.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: BigButton(
                      label: 'Play all saved',
                      icon: Icons.play_circle_fill_rounded,
                      onPressed: () => context.go('/session',
                          extra: SessionArgs(videos: saved)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('No saved videos yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Tap the bookmark on a video while watching to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            BigButton(
              label: 'Back home',
              icon: Icons.home_rounded,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}
