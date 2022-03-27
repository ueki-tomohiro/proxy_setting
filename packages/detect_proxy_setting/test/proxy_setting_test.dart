import 'package:flutter_test/flutter_test.dart';
import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

import 'mock_proxy_setting_platform.dart';

ProxySetting mockSetting = ProxySetting();

void main() {
  final mock = MockProxySetting();
  final url = "https://playon.jp";
  ProxySettingPlatform.instance = mock;

  test('proxySetting', () async {
    mock
      ..setProxySettingExpectations(url: url)
      ..setProxySetting(mockSetting);

    final result = await proxySetting(url: url);

    expect(result, mockSetting);
    expect(mock.url, url);
    expect(mock.proxySettingCalled, isTrue);
  });
}
