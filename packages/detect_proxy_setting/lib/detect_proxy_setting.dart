import 'dart:async';

import 'package:proxy_setting_platform_interface/proxy_setting_platform_interface.dart';

Future<ProxySetting?> proxySetting({String? url}) async {
  return await ProxySettingPlatform.instance.proxySetting(url: url);
}
