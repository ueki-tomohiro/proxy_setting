package jp.playon.proxy_setting_android

import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.SocketAddress
import java.net.URI

internal data class ProxySettingData(
  val mode: String = "direct",
  val isAutoDetect: Boolean = false,
  val configUrl: String = "",
  val proxy: String = "",
  val proxyBypass: String = ""
) {
  fun toMap(): Map<String, Any> {
    return mapOf(
      "mode" to mode,
      "isAutoDetect" to isAutoDetect,
      "configUrl" to configUrl,
      "proxy" to proxy,
      "proxyBypass" to proxyBypass
    )
  }
}

internal object ProxySettingResolver {
  fun resolveForUrl(
    url: String,
    defaultSetting: ProxySettingData,
    proxySelector: ProxySelector? = ProxySelector.getDefault()
  ): ProxySettingData {
    val uri = try {
      URI(url)
    } catch (_: Exception) {
      return defaultSetting
    }

    if (proxySelector == null) {
      return defaultSetting
    }

    val proxies = try {
      proxySelector.select(uri)
    } catch (_: RuntimeException) {
      return defaultSetting
    }

    for (proxy in proxies) {
      when (proxy.type()) {
        Proxy.Type.DIRECT -> {
          return defaultSetting.copy(mode = "direct", proxy = "")
        }
        Proxy.Type.HTTP, Proxy.Type.SOCKS -> {
          val address = formatSocketAddress(proxy.address()) ?: continue
          return defaultSetting.copy(mode = "proxy", proxy = address)
        }
      }
    }

    return defaultSetting
  }

  fun formatHostAndPort(host: String, port: Int): String {
    return if (port > 0) {
      "$host:$port"
    } else {
      host
    }
  }

  internal fun formatSocketAddress(address: SocketAddress?): String? {
    val socketAddress = address as? InetSocketAddress ?: return null
    return formatHostAndPort(socketAddress.hostString, socketAddress.port)
  }
}
