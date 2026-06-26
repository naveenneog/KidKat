import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// Plays a finite, curated queue of educational shorts using the official
/// YouTube IFrame player. Controls live in slim bars above/below the video so
/// they're always visible and tappable (overlaying a WebView is unreliable on
/// Android). **Swipe up = next, swipe down = previous** — the swipe is forwarded
/// from the player via gesture recognizers so it works over the video.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, this.topicIds, this.videos});

  /// Interests to curate from (kid home).
  final List<String>? topicIds;

  /// Explicit videos to play (e.g. Saved videos); skips curation when set.
  final List<KidVideo>? videos;

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

  // Gestures are detected inside the WebView (JS) and delivered to Dart via a
  // JavaScript channel, because the native WebView swallows drag gestures and
  // runJavaScriptReturningResult hangs on this player.
  Timer? _gestureTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  Future<void> _buildQueue() async {
    final config = ref.read(parentConfigProvider);
    final curation = ref.read(curationServiceProvider);
    try {
      List<KidVideo> videos;
      if (widget.videos != null && widget.videos!.isNotEmpty) {
        videos = List<KidVideo>.from(widget.videos!);
      } else {
        final demo = kDebugMode && config.apiKey.trim().isEmpty;
        videos = await curation.buildSession(
          config: config,
          topicIds: widget.topicIds,
          demo: demo,
          exclude: demo ? const {} : ref.read(watchedIdsProvider),
          onAllowlistResolved: (resolved) => ref
              .read(parentConfigProvider.notifier)
              .saveResolvedAllowlist(resolved),
        );
      }
      if (!mounted) return;
      if (videos.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              "We've watched everything for now! A grown-up can add channels or "
              'interests in Parent settings.';
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
      await controller.webViewController.addJavaScriptChannel(
        'KidKatGesture',
        onMessageReceived: (m) => _onJsGesture(m.message),
      );
      setState(() {
        _queue = videos;
        _index = 0;
        _loading = false;
        _controller = controller;
      });
      _gestureTimer = Timer.periodic(
          const Duration(milliseconds: 150), (_) => _pollGestures());
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
    if (playing != _isPlaying && mounted) {
      setState(() => _isPlaying = playing);
    }
    if (value.playerState == PlayerState.ended && !_ended) {
      _ended = true;
      if (mounted) setState(() {});
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

  void _markCurrentWatched() {
    if (_queue.isNotEmpty && _index >= 0 && _index < _queue.length) {
      ref.read(watchedIdsProvider.notifier).markWatched([_queue[_index].id]);
    }
  }

  void _next() {
    if (_navigated) return;
    _flush();
    _markCurrentWatched();
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

  // Reads swipe/tap detected by an injected JS overlay inside the WebView.
  Future<void> _pollGestures() async {
    final c = _controller;
    if (c == null || _navigated) return;
    const js = r'''
(function(){
  try{
    if(typeof KidKatGesture==="undefined") return;
    var f=document.querySelector("iframe"); if(f){f.style.pointerEvents="none";}
    if(document.getElementById("__kidkatCatcher")) return;
    var d=document.createElement("div"); d.id="__kidkatCatcher";
    d.style.cssText="position:fixed;left:0;top:0;right:0;bottom:0;z-index:2147483647;background:transparent;touch-action:none;";
    (document.body||document.documentElement).appendChild(d);
    var sy=0,sx=0,st=0;
    d.addEventListener("touchstart",function(e){var t=e.changedTouches[0];sy=t.clientY;sx=t.clientX;st=Date.now();},{passive:true});
    d.addEventListener("touchend",function(e){var t=e.changedTouches[0];var dy=t.clientY-sy;var dx=t.clientX-sx;var dt=Date.now()-st;
      if(Math.abs(dy)>35&&Math.abs(dy)>Math.abs(dx)){KidKatGesture.postMessage(dy<0?"up":"down");}
      else if(Math.abs(dy)<18&&Math.abs(dx)<18&&dt<400){KidKatGesture.postMessage("tap");}
    },{passive:true});
  }catch(err){}
})();
''';
    try {
      await c.webViewController.runJavaScript(js);
    } catch (_) {
      // ignore until the page is ready
    }
  }

  void _onJsGesture(String msg) {
    if (_navigated) return;
    if (msg == 'up') {
      _next();
    } else if (msg == 'down') {
      _prev();
    } else if (msg == 'tap') {
      _togglePlay();
    }
  }

  void _goOnce(String location) {
    if (_navigated) return;
    _navigated = true;
    _flush();
    _markCurrentWatched();
    if (mounted) context.go(location);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _gestureTimer?.cancel();
    _sub?.cancel();
    _flush();
    _controller?.close();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null || _controller == null) return _errorView();

    final video = _queue[_index];
    final isLast = _index >= _queue.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goOnce('/home');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(video),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return YoutubePlayer(
                      controller: _controller!,
                      aspectRatio: constraints.maxWidth / constraints.maxHeight,
                      enableFullScreenOnVerticalDrag: false,
                      autoFullScreen: false,
                      backgroundColor: Colors.black,
                    );
                  },
                ),
              ),
              _bottomBar(video, isLast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(KidVideo video) {
    final isSaved =
        ref.watch(savedVideosProvider).any((v) => v.id == video.id);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _goOnce('/home'),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('🎓 ${_index + 1} / ${_queue.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          if (_showHint)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  Icon(Icons.swipe_vertical_rounded,
                      color: Colors.white70, size: 18),
                  SizedBox(width: 4),
                  Text('swipe',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          IconButton(
            tooltip: isSaved ? 'Saved' : 'Save video',
            onPressed: () =>
                ref.read(savedVideosProvider.notifier).toggle(video),
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isSaved ? KidColors.sunny : Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(KidVideo video, bool isLast) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: KidColors.sky, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(video.channelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressDots(total: _queue.length, index: _index),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white24,
                    side: BorderSide(
                        color: _index == 0 ? Colors.white12 : Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
