import 'package:flutter_test/flutter_test.dart';
import 'package:kidkat/data/local_store.dart';
import 'package:kidkat/data/models/parent_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads default config when nothing stored', () async {
    final store = await LocalStore.create();
    expect(store.loadConfig().pin, '');
    expect(store.isOnboarded, false);
  });

  test('saves and reloads config', () async {
    final store = await LocalStore.create();
    await store.saveConfig(const ParentConfig(pin: '4321', apiKey: 'K'));
    final reloaded = (await LocalStore.create()).loadConfig();
    expect(reloaded.pin, '4321');
    expect(reloaded.apiKey, 'K');
  });

  test('tracks onboarding flag', () async {
    final store = await LocalStore.create();
    await store.setOnboarded(true);
    expect(store.isOnboarded, true);
  });

  test('accumulates and resets daily watch time', () async {
    final store =
        await LocalStore.create(clock: () => DateTime(2024, 1, 2, 10));
    expect(store.watchedSecondsToday(), 0);
    await store.addWatchedSeconds(30);
    await store.addWatchedSeconds(15);
    expect(store.watchedSecondsToday(), 45);
    await store.addWatchedSeconds(0);
    expect(store.watchedSecondsToday(), 45);
    await store.resetTodayWatch();
    expect(store.watchedSecondsToday(), 0);
  });

  test('watch time is isolated per day', () async {
    final day2 =
        await LocalStore.create(clock: () => DateTime(2024, 1, 2, 10));
    await day2.addWatchedSeconds(120);
    final day3 =
        await LocalStore.create(clock: () => DateTime(2024, 1, 3, 10));
    expect(day3.watchedSecondsToday(), 0);
    expect(day2.watchedSecondsToday(), 120);
  });
}
