package jp.playon.proxy_setting_android

import java.net.Proxy
import java.net.ProxySelector
import java.net.URI
import android.content.Context
import android.net.ConnectivityManager
import android.net.ProxyInfo
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

public final class ProxySettingPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "playon.jp/proxy_setting_android")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "proxySetting" -> {
        val url = call.argument<String>("url")
        val setting = mutableMapOf<String, Any?>()

        if (url != null && url.isNotEmpty()) {
          val proxies = ProxySelector.getDefault().select(URI(url))
          if (proxies.size > 0) {
            val proxy = proxies[0]
            setting["isAutoDetect"] = false
            setting["configUrl"] = ""
            setting["proxyBypass"] = ""
            if (proxy.type() == Proxy.NO_PROXY) {
              setting["mode"] = "direct"
              setting["proxy"] = ""
            } else {
              setting["mode"] = "proxy"
              setting["proxy"] = proxy.address().toString()
            }
            result.success(setting)
            return
          }
        }
        val connectivityManager = getConnectivityManager()
        if (connectivityManager == null) {
          result.error("proxy_error", "Failed to load ConnectivityManager", null)
          return
        }
        val proxySetting = connectivityManager.getDefaultProxy()

        if (proxySetting == null) {
          setting["mode"] = "direct"
          setting["isAutoDetect"] = false
          setting["configUrl"] = ""
          setting["proxy"] = ""
          setting["proxyBypass"] = ""
        } else {
          val proxy = proxySetting.getHost()

          setting["mode"] = if (proxy.isEmpty())  "direct" else "proxy"
          val pacFileUrl = proxySetting.getPacFileUrl().toString()
          setting["isAutoDetect"] = pacFileUrl.isNotEmpty()
          setting["configUrl"] = pacFileUrl

          if (proxy.isNotEmpty()) {
            val port = proxySetting.getPort()
            setting["proxy"] = "${proxy}:${port}"
          } else {
            setting["proxy"] = ""
          }
          setting["proxyBypass"] = ""
        }
        result.success(setting)
      } else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun getConnectivityManager(): ConnectivityManager? {
    return flutterPluginBinding.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
  }
}

