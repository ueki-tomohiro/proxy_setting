import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

import '../lib/proxy_setting_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$ProxySettingWindows', () {
    const MethodChannel channel = MethodChannel(
      'playon.jp/proxy_setting_windows',
    );
    final List<MethodCall> log = <MethodCall>[];
    Map<String, Object?>? result;

    setUp(() {
      result = <String, Object?>{
        'mode': 'direct',
        'isAutoDetect': 0,
        'proxy': '',
        'proxyBypass': '',
        'configUrl': '',
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'proxySetting') {
              return result;
            }
            return null;
          });
    });

    tearDown(() {
      log.clear();
      result = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('registers instance', () {
      ProxySettingWindows.registerWith();
      expect(ProxySettingPlatform.instance, isA<ProxySettingWindows>());
    });

    test('proxySetting', () async {
      final ProxySettingWindows setting = ProxySettingWindows();
      await setting.proxySetting(url: 'http://example.com/');

      expect(log, <Matcher>[
        isMethodCall(
          'proxySetting',
          arguments: <String, Object>{'url': 'http://example.com/'},
        ),
      ]);
    });

    test('proxySetting sends null url when omitted', () async {
      final ProxySettingWindows setting = ProxySettingWindows();
      await setting.proxySetting();

      expect(log, <Matcher>[
        isMethodCall('proxySetting', arguments: <String, Object?>{'url': null}),
      ]);
    });

    test('proxySetting result', () async {
      final ProxySettingWindows setting = ProxySettingWindows();
      final proxySetting = await setting.proxySetting(
        url: 'http://example.com/',
      );

      expect(proxySetting.toString(), ProxySetting().toString());
    });

    test('proxySetting maps boolean native response', () async {
      result = <String, Object?>{
        'mode': 'proxy',
        'isAutoDetect': true,
        'proxy': 'proxy.example.com:8080',
        'proxyBypass': 'localhost,127.0.0.1',
        'configUrl': 'https://proxy.example.com/proxy.pac',
      };

      final ProxySettingWindows setting = ProxySettingWindows();
      final proxySetting = await setting.proxySetting(
        url: 'http://example.com/',
      );

      expect(proxySetting, isNotNull);
      expect(proxySetting!.mode, ProxySettingModeEnum.proxy);
      expect(proxySetting.isAutoDetect, isTrue);
      expect(proxySetting.proxy, 'proxy.example.com:8080');
      expect(proxySetting.proxyBypass, 'localhost,127.0.0.1');
      expect(proxySetting.configUrl, 'https://proxy.example.com/proxy.pac');
    });

    test('proxySetting returns null when native response is null', () async {
      result = null;

      final ProxySettingWindows setting = ProxySettingWindows();
      final proxySetting = await setting.proxySetting(
        url: 'http://example.com/',
      );

      expect(proxySetting, isNull);
    });
  });
}
