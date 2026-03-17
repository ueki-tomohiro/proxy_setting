package jp.playon.proxy_setting_android
import android.content.Context
import android.os.Build
import android.net.ConnectivityManager
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
        val defaultSetting = loadDefaultProxySetting()
        if (defaultSetting == null) {
          result.error("proxy_error", "Failed to load ConnectivityManager", null)
          return
        }

        val setting = if (url.isNullOrEmpty()) {
          defaultSetting
        } else {
          ProxySettingResolver.resolveForUrl(url, defaultSetting)
        }
        result.success(setting.toMap())
      } else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun loadDefaultProxySetting(): ProxySettingData? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      loadModernDefaultProxySetting()
    } else {
      loadLegacyDefaultProxySetting()
    }
  }

  private fun loadModernDefaultProxySetting(): ProxySettingData? {
    val connectivityManager = getConnectivityManager() ?: return null
    val proxySetting = connectivityManager.defaultProxy ?: return ProxySettingData()
    val host = proxySetting.host.orEmpty()
    val pacFileUrl = proxySetting.pacFileUrl?.toString().orEmpty()

    return ProxySettingData(
      mode = if (host.isEmpty()) "direct" else "proxy",
      isAutoDetect = pacFileUrl.isNotEmpty(),
      configUrl = pacFileUrl,
      proxy = if (host.isEmpty()) "" else ProxySettingResolver.formatHostAndPort(host, proxySetting.port),
      proxyBypass = ""
    )
  }

  @Suppress("DEPRECATION")
  private fun loadLegacyDefaultProxySetting(): ProxySettingData {
    val context = flutterPluginBinding.applicationContext
    val host = android.net.Proxy.getHost(context).orEmpty()

    return if (host.isEmpty()) {
      ProxySettingData()
    } else {
      ProxySettingData(
        mode = "proxy",
        proxy = ProxySettingResolver.formatHostAndPort(host, android.net.Proxy.getPort(context))
      )
    }
  }

  private fun getConnectivityManager(): ConnectivityManager? {
    return flutterPluginBinding.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
  }
}
