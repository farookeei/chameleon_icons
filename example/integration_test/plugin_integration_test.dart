// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chameleon_icons/chameleon_icons.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final ChameleonIcons plugin = ChameleonIcons();
    final String? version = await plugin.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  testWidgets('icon change from default to dark', (WidgetTester tester) async {
    final ChameleonIcons plugin = ChameleonIcons();

    await plugin.changeIcon("MainActivityDark");

    final String? currentIcon = await plugin.getCurrentIconClassName();

    expect(currentIcon?.endsWith("MainActivityDark"), true);
  });

  testWidgets('icon change from default to gold', (WidgetTester tester) async {
    final ChameleonIcons plugin = ChameleonIcons();

    await plugin.changeIcon("MainActivityGold");

    final String? currentIcon = await plugin.getCurrentIconClassName();

    expect(currentIcon?.endsWith("MainActivity"), true);
  });
}
