import Flutter
import Foundation

public class SwiftProxySettingPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "playon.jp/proxy_setting_ios",
      binaryMessenger: registrar.messenger())
    let instance = SwiftProxySettingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // let urlString: String? = (call.arguments as? [String: Any])?["url"] as? String
    switch call.method {
    case "proxySetting":
      guard let proxySetting = getProxySetting() else {
        result(FlutterError(
          code: "proxy_error",
          message: "Failed to load CFNetworkCopySystemProxySettings.",
          details: ""))
        return
      }
      
      var setting: [String: Any] = [:]
      setting["mode"] = getMapInteger(map: proxySetting, key: kCFNetworkProxiesHTTPEnable) == 1 ? "proxy" : "direct"
      setting["isAutoDetect"] = getMapInteger(map: proxySetting, key: kCFNetworkProxiesProxyAutoConfigEnable)
      setting["configUrl"] = getMapString(map: proxySetting, key: kCFNetworkProxiesProxyAutoConfigURLString)

      let proxy = getMapString(map: proxySetting, key: kCFNetworkProxiesHTTPProxy)
      let port = getMapInteger(map: proxySetting, key: kCFNetworkProxiesHTTPPort)
      if proxy.isEmpty {
        setting["proxy"] = ""
      } else if let port = port {
        setting["proxy"] = "\(proxy):\(port)"
      } else {
        setting["proxy"] = proxy
      }

      setting["proxyBypass"] = ""
      result(setting)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getProxySetting() -> [String:Any]? {
    guard let setting = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
      return nil
    }
    return setting
  }

  private func getMapInteger(map: [String:Any], key: CFString) -> Int? {
    guard let value = map[key as String] as? NSNumber else {
      return nil
    }
    
    return value.intValue
  }

  private func getMapString(map: [String:Any], key: CFString) -> String {
    guard let value = map[key as String] as? String else {
      return ""
    }
    
    return value
  }
}
