import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

import '../lib/proxy_setting_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$ProxySettingWindows', () {
    const MethodChannel channel =
        MethodChannel('playon.jp/proxy_setting_windows');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == "proxySetting") {
        return <String, Object>{
          "mode": "direct",
          "isAutoDetect": 0,
          "proxy": "",
          "proxyBypass": "",
          "configUrl": "",
        };
      }
      return null;
    });

    tearDown(() {
      log.clear();
    });

    test('registers instance', () {
      ProxySettingWindows.registerWith();
      expect(ProxySettingPlatform.instance, isA<ProxySettingWindows>());
    });
    test('proxySetting', () async {
      final ProxySettingWindows setting = ProxySettingWindows();
      await setting.proxySetting(url: 'http://example.com/');

      expect(
        log,
        <Matcher>[
          isMethodCall('proxySetting', arguments: <String, Object>{
            'url': 'http://example.com/',
          })
        ],
      );
    });

    test('proxySetting result', () async {
      final ProxySettingWindows setting = ProxySettingWindows();
      final proxySetting =
          await setting.proxySetting(url: 'http://example.com/');

      expect(
        proxySetting.toString(),
        ProxySetting().toString(),
      );
    });
  });
}
