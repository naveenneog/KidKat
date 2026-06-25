import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/topic.dart';
import '../../data/providers.dart';
import '../../widgets/brand.dart';

/// First-run parent setup: welcome → API key + PIN → interests.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _apiKeyCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final Set<String> _topics = {'science', 'animals', 'space', 'art'};

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  bool get _setupValid =>
      _apiKeyCtrl.text.trim().isNotEmpty && _pinCtrl.text.length == 4;

  Future<void> _finish() async {
    await ref.read(parentConfigProvider.notifier).completeOnboarding(
          pin: _pinCtrl.text,
          apiKey: _apiKeyCtrl.text,
          topicIds: _topics.toList(),
        );
    ref.read(onboardedProvider.notifier).state = true;
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return BrandGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_step) {
              0 => _welcome(),
              1 => _setup(),
              _ => _interests(),
            },
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const KidLogo(size: 160),
        const SizedBox(height: 24),
        Text(KidKat.appName,
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          KidKat.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _glassCard(
          const Text(
            'KidKat shows your child only short, educational videos you '
            'approve — played in the official YouTube player. Finite sessions '
            'and daily limits mean no endless scrolling.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ),
        const Spacer(),
        BigButton(
          label: "Let's set up",
          icon: Icons.arrow_forward_rounded,
          color: Colors.white,
          onPressed: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _setup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Parent setup', 'Step 1 of 2'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              _glassCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YouTube Data API key',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'KidKat uses your own free YouTube Data API v3 key to find '
                      'educational videos. Create one at console.cloud.google.com '
                      '→ APIs & Services → Credentials.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Paste API key'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _glassCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Parent PIN (4 digits)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Guards the parent settings so kids stay in the safe zone.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(
                          color: Colors.white, letterSpacing: 8, fontSize: 22),
                      decoration: _inputDecoration('• • • •')
                          .copyWith(counterText: ''),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
            const Spacer(),
            BigButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              color: Colors.white,
              onPressed: _setupValid ? () => setState(() => _step = 2) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _interests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Pick interests', 'Step 2 of 2'),
        const SizedBox(height: 8),
        const Text('Choose what your child loves to learn about.',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in kTopics)
                  _TopicChip(
                    topic: t,
                    selected: _topics.contains(t.id),
                    onTap: () => setState(() {
                      if (_topics.contains(t.id)) {
                        _topics.remove(t.id);
                      } else {
                        _topics.add(t.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
            const Spacer(),
            BigButton(
              label: 'Start KidKat',
              icon: Icons.check_rounded,
              color: Colors.white,
              onPressed: _topics.isEmpty ? null : _finish,
            ),
          ],
        ),
      ],
    );
  }

  Widget _header(String title, String step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step, style: const TextStyle(color: Colors.white70)),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white)),
      ],
    );
  }

  Widget _glassCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.topic,
    required this.selected,
    required this.onTap,
  });
  final Topic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? Colors.white : Colors.white30, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(topic.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              topic.label,
              style: TextStyle(
                color: selected ? KidColors.ink : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle,
                  color: KidColors.green, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
