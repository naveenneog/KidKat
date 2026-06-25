import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme.dart';
import '../../data/models/kid_video.dart';
import '../../data/providers.dart';
import '../../data/youtube_api.dart';
import '../../widgets/brand.dart';

/// Plays a finite, curated queue of educational shorts using the official
/// YouTube IFrame player. There is no infinite feed — when the queue ends the
/// child sees a break screen. Advancing is a deliberate tap, never a swipe.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, this.topicIds});
  final List<String>? topicIds;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  Timer? _ticker;

  List<KidVideo> _queue = const [];
  int _index = 0;
  bool _loading = true;
  bool _isPlaying = false;
  bool _ended = false;
  bool _navigated = false;
  int _pendingSeconds = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
  }

  Future<void> _buildQueue() async {
    final config = ref.read(parentConfigProvider);
    final curation = ref.read(curationServiceProvider);
    try {
      final videos = await curation.buildSession(
        config: config,
        topicIds: widget.topicIds,
        onAllowlistResolved: (resolved) => ref
            .read(parentConfigProvider.notifier)
            .saveResolvedAllowlist(resolved),
      );
      if (!mounted) return;
      if (videos.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              "We couldn't find approved videos right now. A grown-up can add "
              'channels or interests in Parent settings.';
        });
        return;
      }
      final controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          strictRelatedVideos: true,
          enableCaption: false,
          playsInline: true,
        ),
      );
      _sub = controller.stream.listen(_onPlayerValue);
      setState(() {
        _queue = videos;
        _index = 0;
        _loading = false;
        _controller = controller;
      });
      await controller.loadVideoById(videoId: videos.first.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is YouTubeApiException) {
      if (e.isQuotaExceeded) {
        return 'Today\'s video search limit was reached. Please try again later.';
      }
      if (e.isKeyInvalid) {
        return 'The YouTube API key looks invalid. A grown-up can fix it in '
            'Parent settings.';
      }
      return 'Network hiccup. Please check the connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _onPlayerValue(YoutubePlayerValue value) {
    final playing = value.playerState == PlayerState.playing;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
    if (value.playerState == PlayerState.ended && !_ended) {
      _ended = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1200), _next);
    }
  }

  void _tick() {
    if (!_isPlaying || _navigated) return;
    _pendingSeconds++;
    if (_pendingSeconds >= 10) _flush();
    final limitSeconds =
        ref.read(parentConfigProvider).dailyLimitMinutes * 60;
    final total = ref.read(watchTimeProvider) + _pendingSeconds;
    if (total >= limitSeconds) {
      _flush();
      _goOnce('/timeup');
    }
  }

  void _flush() {
    if (_pendingSeconds > 0) {
      ref.read(watchTimeProvider.notifier).addSeconds(_pendingSeconds);
      _pendingSeconds = 0;
    }
  }

  void _next() {
    if (_navigated) return;
    _flush();
    _ended = false;
    if (_index >= _queue.length - 1) {
      _goOnce('/break');
      return;
    }
    setState(() => _index++);
    _controller?.loadVideoById(videoId: _queue[_index].id);
  }

  void _goOnce(String location) {
    if (_navigated) return;
    _navigated = true;
    _flush();
    if (mounted) context.go(location);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    _flush();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KidLogo(size: 90),
              SizedBox(height: 20),
              CircularProgressIndicator(color: KidColors.purple),
              SizedBox(height: 12),
              Text('Finding great videos…',
                  style: TextStyle(fontSize: 16, color: KidColors.ink)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _controller == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(_error ?? 'Something went wrong.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  BigButton(
                    label: 'Back home',
                    icon: Icons.home_rounded,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final video = _queue[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _SessionTopBar(
              index: _index,
              total: _queue.length,
              onClose: () => _goOnce('/home'),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: YoutubePlayer(
                controller: _controller!,
                aspectRatio: 16 / 9,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(video.channelTitle,
                        style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 14),
                    _ProgressDots(total: _queue.length, index: _index),
                    const Spacer(),
                    if (_ended)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Nice! Tap Next ▶',
                            style: TextStyle(
                                color: KidColors.sunny,
                                fontWeight: FontWeight.w700)),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => _goOnce('/home'),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text("I'm done"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KidColors.orange,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _next,
                            icon: Icon(_index >= _queue.length - 1
                                ? Icons.celebration_rounded
                                : Icons.skip_next_rounded),
                            label: Text(
                                _index >= _queue.length - 1 ? 'Finish' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.index,
    required this.total,
    required this.onClose,
  });
  final int index;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Video ${index + 1} of $total',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.index});
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= index
                    ? KidColors.orange
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
