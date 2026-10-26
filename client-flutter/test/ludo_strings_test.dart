import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/l10n/localized_text.dart';
import 'package:ludo_rush/l10n/ludo_string_keys.dart';
import 'package:ludo_rush/l10n/ludo_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android translations update visible UI with English fallback', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('ludo_rush/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getUiStrings');
          return {ludoStringKeys['Shop']!: 'Boutique'};
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LudoStringsScope(
          notifier: LudoStrings.instance,
          child: const Column(
            children: [LocalizedText('Shop'), LocalizedText('Unknown UI copy')],
          ),
        ),
      ),
    );
    expect(find.text('Shop'), findsOneWidget);

    await LudoStrings.instance.load();
    await tester.pump();
    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Unknown UI copy'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
