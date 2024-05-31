import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_camera_s700c_plugin/dental_camera_s700c_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDentalCameraS700cPlugin platform = MethodChannelDentalCameraS700cPlugin();
  const MethodChannel channel = MethodChannel('dental_camera_s700c_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
