import 'package:flutter_test/flutter_test.dart';
import 'package:dental_camera_s700c_plugin/dental_camera_s700c_plugin.dart';
import 'package:dental_camera_s700c_plugin/dental_camera_s700c_plugin_platform_interface.dart';
import 'package:dental_camera_s700c_plugin/dental_camera_s700c_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDentalCameraS700cPluginPlatform
    with MockPlatformInterfaceMixin
    implements DentalCameraS700cPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DentalCameraS700cPluginPlatform initialPlatform = DentalCameraS700cPluginPlatform.instance;

  test('$MethodChannelDentalCameraS700cPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDentalCameraS700cPlugin>());
  });

  test('getPlatformVersion', () async {
    DentalCameraS700cPlugin dentalCameraS700cPlugin = DentalCameraS700cPlugin();
    MockDentalCameraS700cPluginPlatform fakePlatform = MockDentalCameraS700cPluginPlatform();
    DentalCameraS700cPluginPlatform.instance = fakePlatform;

    expect(await dentalCameraS700cPlugin.getPlatformVersion(), '42');
  });
}
