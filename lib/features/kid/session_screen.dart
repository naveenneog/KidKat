import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme.dart';
import '../../data/models/kid_video.dart';
import '../../data/providers.dart';
import '../../data/youtube_api.dart';
import '../../widgets/brand.dart';

/// Plays a finite, curated queue of educational shorts **full-screen** using the
/// official YouTube IFrame player. The video fills the screen (immersive), with
/// lightweight overlay controls. There is no infinite feed — when the queue ends
/// the child sees a break screen. Advancing is a deliberate tap, never a swipe.
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
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    // Immersive full-screen: hide system bars for a true Shorts feel.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _showHint = false);
    });
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
          showControls: false,
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

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (_isPlaying) {
      c.pauseVideo();
    } else {
      c.playVideo();
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

  void _prev() {
    if (_navigated || _index == 0) return;
    _flush();
    _ended = false;
    setState(() => _index--);
    _controller?.loadVideoById(videoId: _queue[_index].id);
  }

  void _onVerticalDrag(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -250) {
      _next(); // swipe up → next
    } else if (v > 250) {
      _prev(); // swipe down → previous
    }
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
    // Restore system bars when leaving the player.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null || _controller == null) return _errorView();

    final size = MediaQuery.sizeOf(context);
    final video = _queue[_index];
    final isLast = _index >= _queue.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goOnce('/home');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed player.
            YoutubePlayer(
              controller: _controller!,
              aspectRatio: size.width / size.height,
              enableFullScreenOnVerticalDrag: false,
              autoFullScreen: false,
            ),

            // Tap to pause/play; swipe up = next, swipe down = previous.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                onVerticalDragEnd: _onVerticalDrag,
              ),
            ),

            // Paused indicator.
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 52),
                  ),
                ),
              ),
            ),

            // Swipe hint (auto-hides).
            _swipeHint(),

            // Top scrim + bar.
            _topBar(),

            // Bottom scrim + info + actions.
            _bottomBar(video, isLast),
          ],
        ),
      ),
    );
  }

  Widget _swipeHint() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showHint ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Align(
          alignment: const Alignment(0, 0.45),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe_vertical_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Swipe up for next · down to go back',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            bottom: 28,
            left: 8,
            right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _goOnce('/home'),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('🎓 Video ${_index + 1} of ${_queue.length}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(KidVideo video, bool isLast) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 30,
            bottom: MediaQuery.paddingOf(context).bottom + 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.78),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: KidColors.sky, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(video.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressDots(total: _queue.length, index: _index),
            if (_ended)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Nice! Tap Next ▶',
                    style: TextStyle(
                        color: KidColors.sunny, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white24,
                      side: BorderSide(
                          color: _index == 0
                              ? Colors.white12
                              : Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _index == 0 ? null : _prev,
                    icon: const Icon(Icons.skip_previous_rounded),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _next,
                    icon: Icon(isLast
                        ? Icons.celebration_rounded
                        : Icons.skip_next_rounded),
                    label: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingView() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KidLogo(size: 90),
            SizedBox(height: 20),
            CircularProgressIndicator(color: KidColors.sunny),
            SizedBox(height: 12),
            Text('Finding great videos…',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Scaffold(
      backgroundColor: Colors.black,
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
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
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
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= index
                    ? KidColors.orange
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
