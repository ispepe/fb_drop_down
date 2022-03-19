import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fb_drop_down/fb_drop_down.dart';

void main() {
  const MethodChannel channel = MethodChannel('fb_drop_down');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FbDropDown.platformVersion, '42');
  });
}
