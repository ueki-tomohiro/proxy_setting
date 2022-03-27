import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:proxy_setting_platform_interface/proxy_setting.dart';
import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

class MockProxySetting extends Fake
    with MockPlatformInterfaceMixin
    implements ProxySettingPlatform {
  ProxySetting? setting;
  String? url;

  bool proxySettingCalled = false;

  void setProxySettingExpectations({required String url}) {
    this.url = url;
  }

  void setProxySetting(ProxySetting? setting) {
    this.setting = setting;
  }

  @override
  Future<ProxySetting> proxySetting({String? url}) async {
    proxySettingCalled = true;
    return setting!;
  }
}
