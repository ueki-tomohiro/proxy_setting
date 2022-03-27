import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../lib/method_channel_proxy_setting.dart';
import '../lib/proxy_setting_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Store the initial instance before any tests change it.
  final ProxySettingPlatform initialInstance = ProxySettingPlatform.instance;

  group('$ProxySettingPlatform', () {
    test('$MethodChannelProxySetting() is the default instance', () {
      expect(initialInstance, isInstanceOf<MethodChannelProxySetting>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        ProxySettingPlatform.instance = ImplementsProxySettingPlatform();
      }, throwsA(isInstanceOf<AssertionError>()));
    });

    test('Can be mocked with `implements`', () {
      final ProxySettingPlatformMock mock = ProxySettingPlatformMock();
      ProxySettingPlatform.instance = mock;
    });
  });

  group('$ProxySettingPlatform', () {
    const MethodChannel channel = MethodChannel('playon.jp/proxy_setting');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });

    final MethodChannelProxySetting launcher = MethodChannelProxySetting();

    tearDown(() {
      log.clear();
    });

    test('proxySetting', () async {
      await launcher.proxySetting();
      expect(
        log,
        <Matcher>[
          isMethodCall('proxySetting', arguments: {"url": null})
        ],
      );
    });
  });
}

class ProxySettingPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements ProxySettingPlatform {}

class ImplementsProxySettingPlatform extends Mock
    implements ProxySettingPlatform {}
