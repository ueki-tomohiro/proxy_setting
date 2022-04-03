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
    let urlString: String? = (call.arguments as? [String: Any])?["url"] as? String
    switch call.method {
    case "proxySetting":
      guard let proxySetting = getProxySetting() else {
        result(FlutterError(
          code: "proxy_error",
          message: "Failed to load CFNetworkCopySystemProxySettings.",
          details: ""))
        return
      }
      guard let proxyMap = proxySetting as? [String : Any]  else {
        result(FlutterError(
          code: "proxy_error",
          message: "Failed to load CFNetworkCopySystemProxySettings.",
          details: ""))
        return
      }

      var setting: [String: Any] = [:]
      setting["mode"] = getMapInteger(map: proxyMap, key: kCFNetworkProxiesHTTPEnable) == 1 ? "proxy" : "direct"
      setting["isAutoDetect"] = getMapInteger(map: proxyMap, key: kCFNetworkProxiesProxyAutoConfigEnable)
      setting["configUrl"] = getMapString(map: proxyMap, key: kCFNetworkProxiesProxyAutoConfigURLString)

      let proxy: String
      let port: Int?
      if let urlString = urlString , let url = CFURLCreateWithString(kCFAllocatorDefault, urlString as CFString, nil),  let proxies = CFNetworkCopyProxiesForURL(url, proxySetting).takeRetainedValue() as? [[String: Any]], proxies.count > 0 {
        proxy = getMapString(map: proxies[0], key: kCFNetworkProxiesHTTPProxy)
        port = getMapInteger(map: proxies[0], key: kCFNetworkProxiesHTTPPort)
      } else {
        proxy = getMapString(map: proxyMap, key: kCFNetworkProxiesHTTPProxy)
        port = getMapInteger(map: proxyMap, key: kCFNetworkProxiesHTTPPort)
      }
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

  private func getProxySetting() -> CFDictionary? {
    guard let setting = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else {
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
