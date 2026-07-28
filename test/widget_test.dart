// Basic smoke test: verifies the app's root widget class builds correctly.
//
// Note: TamennyPharmacistApp depends on Firebase.initializeApp() and
// setupInjection() (get_it) having already run in main() before it is
// pumped, and this project has no Firebase test-mocking setup yet. A full
// pumpWidget(TamennyPharmacistApp()) test therefore requires that
// infrastructure to be added first (see AUDIT_REPORT.md, Step 13). Until
// then, this test only verifies the widget class itself is constructible.

import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacist/main.dart';

void main() {
  test('TamennyPharmacistApp can be constructed', () {
    const app = TamennyPharmacistApp();
    expect(app, isA<TamennyPharmacistApp>());
  });
}
