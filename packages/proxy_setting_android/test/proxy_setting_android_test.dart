import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

import '../lib/proxy_setting_android.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$ProxySettingAndroid', () {
    const MethodChannel channel =
        MethodChannel('playon.jp/proxy_setting_android');
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
      ProxySettingAndroid.registerWith();
      expect(ProxySettingPlatform.instance, isA<ProxySettingAndroid>());
    });
    test('proxySetting', () async {
      final ProxySettingAndroid setting = ProxySettingAndroid();
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
      final ProxySettingAndroid setting = ProxySettingAndroid();
      final proxySetting =
          await setting.proxySetting(url: 'http://example.com/');

      expect(
        proxySetting.toString(),
        ProxySetting().toString(),
      );
    });
  });
}
