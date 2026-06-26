import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import '../data/youtube_api.dart';

/// Direct Google Cloud Console links that make key creation a guided, near
/// one-tap experience.
const _kEnableApiUrl =
    'https://console.cloud.google.com/flows/enableapi?apiid=youtube.googleapis.com';
const _kCredentialsUrl = 'https://console.cloud.google.com/apis/credentials';

enum _Setup { idle, checking, valid, invalid, serviceDisabled, unreachable }

/// A guided, self-verifying YouTube Data API key setup card.
///
/// Flow: tap to open the exact Cloud Console page → create a key → tap **Paste**
/// (reads the clipboard) → the key is **verified live** against the API and
/// saved automatically on success.
class ApiKeySetup extends ConsumerStatefulWidget {
  const ApiKeySetup({super.key, this.dark = false, this.onValidated});

  /// Use light-on-dark styling (for the gradient onboarding background).
  final bool dark;

  /// Called once a key is verified and saved.
  final VoidCallback? onValidated;

  @override
  ConsumerState<ApiKeySetup> createState() => _ApiKeySetupState();
}

class _ApiKeySetupState extends ConsumerState<ApiKeySetup> {
  late final TextEditingController _ctrl;
  _Setup _state = _Setup.idle;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(parentConfigProvider).apiKey);
    if (_ctrl.text.trim().isNotEmpty) _state = _Setup.valid;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _fg => widget.dark ? Colors.white : KidColors.ink;
  Color get _muted =>
      widget.dark ? Colors.white70 : KidColors.ink.withValues(alpha: .6);

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _ctrl.text = text;
      await _verify();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
    }
  }

  Future<void> _verify() async {
    final candidate = _ctrl.text.trim();
    if (candidate.isEmpty) {
      setState(() => _state = _Setup.invalid);
      return;
    }
    setState(() => _state = _Setup.checking);
    final api =
        YouTubeApi(apiKey: candidate, client: ref.read(httpClientProvider));
    final result = await api.validateKey();
    if (!mounted) return;
    setState(() => _state = _Setup.values.byName(result.name));
    if (result == ApiKeyStatus.valid) {
      await ref.read(parentConfigProvider.notifier).setApiKey(candidate);
      widget.onValidated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connect YouTube (one-time)',
            style: TextStyle(
                color: _fg, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'KidKat uses your own free YouTube Data API key to find videos. '
          'Two quick taps and a paste — we verify it for you.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 14),

        // Step 1
        _stepRow('1', 'Open Google Cloud & enable the API'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _btn(
                icon: Icons.open_in_new_rounded,
                label: 'Enable API',
                onTap: () => _open(_kEnableApiUrl),
                filled: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _btn(
                icon: Icons.vpn_key_rounded,
                label: 'Create key',
                onTap: () => _open(_kCredentialsUrl),
                filled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 2
        _stepRow('2', 'Paste your key — we verify it instantly'),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          obscureText: true,
          onChanged: (_) {
            if (_state != _Setup.idle) setState(() => _state = _Setup.idle);
          },
          style: TextStyle(color: _fg),
          decoration: InputDecoration(
            hintText: 'AIza…  (your API key)',
            hintStyle: TextStyle(color: _muted),
            filled: true,
            fillColor: widget.dark
                ? Colors.white.withValues(alpha: .12)
                : KidColors.bg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: widget.dark ? Colors.white30 : const Color(0xFFE3DEF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: KidColors.purple, width: 2),
            ),
            suffixIcon: TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Paste'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statusChip()),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _state == _Setup.checking ? null : _verify,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepRow(String n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
              color: KidColors.purple, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(n,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: _fg, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final fg = filled ? Colors.white : (widget.dark ? Colors.white : KidColors.purple);
    return Material(
      color: filled
          ? KidColors.purple
          : (widget.dark ? Colors.white.withValues(alpha: .14) : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: widget.dark
                          ? Colors.white30
                          : KidColors.purple.withValues(alpha: .4)),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    late final IconData icon;
    late final Color color;
    late final String text;
    switch (_state) {
      case _Setup.idle:
        return Text('Not connected yet',
            style: TextStyle(color: _muted, fontSize: 13));
      case _Setup.checking:
        return Row(children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Verifying…', style: TextStyle(color: _fg, fontSize: 13)),
        ]);
      case _Setup.valid:
        icon = Icons.check_circle_rounded;
        color = KidColors.green;
        text = 'Connected! Key verified ✓';
        break;
      case _Setup.invalid:
        icon = Icons.error_rounded;
        color = Colors.redAccent;
        text = 'Key invalid — check it and try again';
        break;
      case _Setup.serviceDisabled:
        icon = Icons.report_problem_rounded;
        color = Colors.orangeAccent;
        text = 'Enable the API first (tap "Enable API")';
        break;
      case _Setup.unreachable:
        icon = Icons.wifi_off_rounded;
        color = Colors.orangeAccent;
        text = "Couldn't verify — check your connection";
        break;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }
}
