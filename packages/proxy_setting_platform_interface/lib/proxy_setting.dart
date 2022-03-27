enum ProxySettingModeEnum { proxy, direct }

class ProxySetting {
  bool isAutoDetect;
  ProxySettingModeEnum mode;
  String proxy;
  String proxyBypass;
  String configUrl;

  ProxySetting(
      {this.mode = ProxySettingModeEnum.direct,
      this.isAutoDetect = false,
      this.proxy = "",
      this.proxyBypass = "",
      this.configUrl = ""});

  @override
  String toString() {
    return "{mode = $mode, isAutoDetect = $isAutoDetect, proxy = $proxy, proxyBypass = $proxyBypass, configUrl = $configUrl}";
  }
}
