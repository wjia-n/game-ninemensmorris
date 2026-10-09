/// Regression test for player-name persistence (names-fix batch).
///
/// Nine Men's Morris stores each player name under its own order-safe
/// `setString` key (`nmm_name_0` / `nmm_name_1`) — NEVER a `setStringList`,
/// which Android backs with an unordered StringSet and would scramble name
/// order on every restart (MASTER_RULES ban; ludo commit 6ceb537).
///
/// This test guards that: names survive a save/reload cycle in seat order,
/// and no StringList is ever used for the name keys.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ninemensmorris/state/settings.dart';

void main() {
  test('player names persist per-seat in order; no StringList used', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final s = SettingsStore.I;
    await s.init();

    await s.setPlayerName(0, 'Zed');
    await s.setPlayerName(1, 'Amy');

    // Seat order preserved at the raw storage level (what a restart reads).
    final p = await SharedPreferences.getInstance();
    expect(p.getString('nmm_name_0'), 'Zed');
    expect(p.getString('nmm_name_1'), 'Amy');
    // The unordered-StringSet trap: names must not live in a StringList.
    expect(p.get('nmm_name_0'), isNot(isA<List>()));
    expect(p.get('nmm_name_1'), isNot(isA<List>()));

    // Blank names fall back to the defaults, never empty strings.
    await s.setPlayerName(0, '   ');
    expect(s.playerName(0), 'Bronze');
    await s.setPlayerName(1, '');
    expect(s.playerName(1), 'Bone');
    expect(p.getString('nmm_name_0'), 'Bronze');
    expect(p.getString('nmm_name_1'), 'Bone');
  });
}
