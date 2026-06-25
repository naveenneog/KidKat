import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';

class KidKatApp extends ConsumerWidget {
  const KidKatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: KidKat.appName,
      debugShowCheckedModeBanner: false,
      theme: buildKidKatTheme(),
      routerConfig: router,
    );
  }
}
