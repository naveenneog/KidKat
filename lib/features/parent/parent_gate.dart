import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

/// A simple parental gate: enter the 4-digit PIN to reach parent settings.
class ParentGate extends ConsumerStatefulWidget {
  const ParentGate({super.key});

  @override
  ConsumerState<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends ConsumerState<ParentGate> {
  String _entered = '';
  bool _error = false;

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == 4) _validate();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _validate() {
    final pin = ref.read(parentConfigProvider).pin;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_entered == pin) {
        context.go('/parent');
      } else {
        setState(() {
          _error = true;
          _entered = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Parents only'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_rounded, size: 56, color: KidColors.purple),
            const SizedBox(height: 12),
            Text('Enter parent PIN',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              _error ? 'Incorrect PIN, try again' : 'Keep kids in the safe zone',
              style: TextStyle(
                  color: _error ? Colors.red : KidColors.ink.withValues(alpha: .6)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _entered.length
                          ? KidColors.purple
                          : Colors.transparent,
                      border: Border.all(color: KidColors.purple, width: 2),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            _NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  const _NumPad({required this.onDigit, required this.onBackspace});
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 76,
          height: 76,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap ?? () => onDigit(label),
              child: Center(
                child: child ??
                    Text(label,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: KidColors.ink)),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 92),
            key('0'),
            key('',
                onTap: onBackspace,
                child: const Icon(Icons.backspace_outlined,
                    color: KidColors.ink)),
          ],
        ),
      ],
    );
  }
}
