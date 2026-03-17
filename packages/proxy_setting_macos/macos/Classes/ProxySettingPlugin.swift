import CFNetwork
import FlutterMacOS
import Foundation

private final class AutoConfigurationContext {
  var proxies: [[String: Any]]?
  var completed = false
}

private let retainAutoConfigurationContext: CFAllocatorRetainCallBack = { info in
  guard let info else {
    return nil
  }

  _ = Unmanaged<AutoConfigurationContext>.fromOpaque(info).retain()
  return info
}

private let releaseAutoConfigurationContext: CFAllocatorReleaseCallBack = { info in
  guard let info else {
    return
  }

  Unmanaged<AutoConfigurationContext>.fromOpaque(info).release()
}

private struct ResolvedProxy {
  let mode: String
  let proxy: String
}

public class ProxySettingPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "playon.jp/proxy_setting_macos",
      binaryMessenger: registrar.messenger)
    let instance = ProxySettingPlugin()
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
      guard let proxyMap = proxySetting as? [String: Any] else {
        result(FlutterError(
          code: "proxy_error",
          message: "Failed to load CFNetworkCopySystemProxySettings.",
          details: ""))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let setting = self.buildSetting(
          proxySettings: proxySetting,
          proxyMap: proxyMap,
          urlString: urlString)
        DispatchQueue.main.async {
          result(setting)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func buildSetting(
    proxySettings: CFDictionary,
    proxyMap: [String: Any],
    urlString: String?
  ) -> [String: Any] {
    let resolvedProxy = resolveProxy(
      urlString: urlString,
      proxySettings: proxySettings,
      proxyMap: proxyMap)

    return [
      "mode": resolvedProxy.mode,
      "isAutoDetect": getMapInteger(map: proxyMap, key: kCFNetworkProxiesProxyAutoConfigEnable) ?? 0,
      "configUrl": getMapString(map: proxyMap, key: kCFNetworkProxiesProxyAutoConfigURLString),
      "proxy": resolvedProxy.proxy,
      "proxyBypass": "",
    ]
  }

  private func resolveProxy(
    urlString: String?,
    proxySettings: CFDictionary,
    proxyMap: [String: Any]
  ) -> ResolvedProxy {
    if let urlString,
       let url = CFURLCreateWithString(kCFAllocatorDefault, urlString as CFString, nil),
       let proxies = CFNetworkCopyProxiesForURL(url, proxySettings).takeRetainedValue() as? [[String: Any]],
       let resolved = resolveProxyList(proxies, targetURL: url) {
      return resolved
    }

    return defaultResolvedProxy(from: proxyMap)
  }

  private func resolveProxyList(_ proxies: [[String: Any]], targetURL: CFURL) -> ResolvedProxy? {
    for proxy in proxies {
      if let resolvedProxy = resolveProxyEntry(proxy, targetURL: targetURL) {
        return resolvedProxy
      }
    }
    return nil
  }

  private func resolveProxyEntry(_ proxy: [String: Any], targetURL: CFURL) -> ResolvedProxy? {
    let proxyType = getMapString(map: proxy, key: kCFProxyTypeKey)

    if proxyType == (kCFProxyTypeNone as String) {
      return ResolvedProxy(mode: "direct", proxy: "")
    }

    if proxyType == (kCFProxyTypeAutoConfigurationURL as String) {
      guard let proxyAutoConfigurationURLString = getOptionalMapString(
        map: proxy,
        key: kCFProxyAutoConfigurationURLKey),
        let proxyAutoConfigurationURL = CFURLCreateWithString(
          kCFAllocatorDefault,
          proxyAutoConfigurationURLString as CFString,
          nil),
        let proxies = executeAutoConfigurationURL(
          proxyAutoConfigurationURL,
          targetURL: targetURL)
      else {
        return nil
      }

      return resolveProxyList(proxies, targetURL: targetURL)
    }

    if proxyType == (kCFProxyTypeAutoConfigurationJavaScript as String) {
      guard let script = getOptionalMapString(
        map: proxy,
        key: kCFProxyAutoConfigurationJavaScriptKey),
        let proxies = executeAutoConfigurationScript(script as CFString, targetURL: targetURL)
      else {
        return nil
      }

      return resolveProxyList(proxies, targetURL: targetURL)
    }

    let proxyHost = getMapString(map: proxy, key: kCFProxyHostNameKey)
    guard !proxyHost.isEmpty else {
      return nil
    }
    let proxyPort = getMapInteger(map: proxy, key: kCFProxyPortNumberKey)
    return ResolvedProxy(mode: "proxy", proxy: formatProxy(host: proxyHost, port: proxyPort))
  }

  private func defaultResolvedProxy(from proxyMap: [String: Any]) -> ResolvedProxy {
    guard getMapInteger(map: proxyMap, key: kCFNetworkProxiesHTTPEnable) == 1 else {
      return ResolvedProxy(mode: "direct", proxy: "")
    }

    let proxyHost = getMapString(map: proxyMap, key: kCFNetworkProxiesHTTPProxy)
    guard !proxyHost.isEmpty else {
      return ResolvedProxy(mode: "direct", proxy: "")
    }

    let proxyPort = getMapInteger(map: proxyMap, key: kCFNetworkProxiesHTTPPort)
    return ResolvedProxy(mode: "proxy", proxy: formatProxy(host: proxyHost, port: proxyPort))
  }

  private func executeAutoConfigurationURL(
    _ proxyAutoConfigurationURL: CFURL,
    targetURL: CFURL
  ) -> [[String: Any]]? {
    let context = AutoConfigurationContext()

    var clientContext = CFStreamClientContext(
      version: 0,
      info: Unmanaged.passUnretained(context).toOpaque(),
      retain: retainAutoConfigurationContext,
      release: releaseAutoConfigurationContext,
      copyDescription: nil)

    let callback: CFProxyAutoConfigurationResultCallback = { client, proxyList, _ in
      guard let client else {
        return
      }

      let context = Unmanaged<AutoConfigurationContext>.fromOpaque(client).takeUnretainedValue()
      if let proxyList = proxyList as? [[String: Any]] {
        context.proxies = proxyList
      }
      context.completed = true
    }

    let source = CFNetworkExecuteProxyAutoConfigurationURL(
      proxyAutoConfigurationURL,
      targetURL,
      callback,
      &clientContext)

    return runAutoConfigurationSource(source, context: context)
  }

  private func executeAutoConfigurationScript(_ script: CFString, targetURL: CFURL) -> [[String: Any]]? {
    let context = AutoConfigurationContext()

    var clientContext = CFStreamClientContext(
      version: 0,
      info: Unmanaged.passUnretained(context).toOpaque(),
      retain: retainAutoConfigurationContext,
      release: releaseAutoConfigurationContext,
      copyDescription: nil)

    let callback: CFProxyAutoConfigurationResultCallback = { client, proxyList, _ in
      guard let client else {
        return
      }

      let context = Unmanaged<AutoConfigurationContext>.fromOpaque(client).takeUnretainedValue()
      if let proxyList = proxyList as? [[String: Any]] {
        context.proxies = proxyList
      }
      context.completed = true
    }

    let source = CFNetworkExecuteProxyAutoConfigurationScript(
      script,
      targetURL,
      callback,
      &clientContext)

    return runAutoConfigurationSource(source, context: context)
  }

  private func runAutoConfigurationSource(
    _ source: CFRunLoopSource,
    context: AutoConfigurationContext
  ) -> [[String: Any]]? {
    let runLoop = CFRunLoopGetCurrent()
    CFRunLoopAddSource(runLoop, source, CFRunLoopMode.defaultMode)
    defer {
      CFRunLoopRemoveSource(runLoop, source, CFRunLoopMode.defaultMode)
    }

    let deadline = Date().addingTimeInterval(5)
    while !context.completed && Date() < deadline {
      CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.05, true)
    }

    if !context.completed {
      CFRunLoopSourceInvalidate(source)
      return nil
    }

    return context.proxies
  }

  private func getProxySetting() -> CFDictionary? {
    guard let setting = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else {
      return nil
    }
    return setting
  }

  private func getMapInteger(map: [String: Any], key: CFString) -> Int? {
    guard let value = map[key as String] as? NSNumber else {
      return nil
    }

    return value.intValue
  }

  private func getOptionalMapString(map: [String: Any], key: CFString) -> String? {
    guard let value = map[key as String] as? String, !value.isEmpty else {
      return nil
    }

    return value
  }

  private func getMapString(map: [String: Any], key: CFString) -> String {
    guard let value = map[key as String] as? String else {
      return ""
    }

    return value
  }

  private func formatProxy(host: String, port: Int?) -> String {
    guard let port else {
      return host
    }

    return "\(host):\(port)"
  }
}
