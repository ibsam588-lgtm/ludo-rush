import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/app_platform_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ludo_rush/app');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('shareText sends the result to the platform share channel', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final shared = await AppPlatformService.shareText('I won!');

    expect(shared, isTrue);
    expect(received?.method, 'shareText');
    expect(received?.arguments, {'text': 'I won!'});
  });

  test('shareText ignores empty content', () async {
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      called = true;
      return true;
    });

    expect(await AppPlatformService.shareText('   '), isFalse);
    expect(called, isFalse);
  });
}
