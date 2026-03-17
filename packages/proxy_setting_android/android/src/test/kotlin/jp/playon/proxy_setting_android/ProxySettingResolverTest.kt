package jp.playon.proxy_setting_android

import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.URI
import org.junit.Assert.assertEquals
import org.junit.Test

class ProxySettingResolverTest {
  @Test
  fun resolveForUrl_returnsDirectForNoProxy() {
    val defaultSetting = ProxySettingData(
      mode = "direct",
      isAutoDetect = true,
      configUrl = "https://proxy.example.com/proxy.pac"
    )

    val resolved = ProxySettingResolver.resolveForUrl(
      url = "https://example.com",
      defaultSetting = defaultSetting,
      proxySelector = FakeProxySelector(listOf(Proxy.NO_PROXY))
    )

    assertEquals("direct", resolved.mode)
    assertEquals("", resolved.proxy)
    assertEquals(true, resolved.isAutoDetect)
    assertEquals("https://proxy.example.com/proxy.pac", resolved.configUrl)
  }

  @Test
  fun resolveForUrl_formatsInetSocketAddressWithoutSlash() {
    val resolved = ProxySettingResolver.resolveForUrl(
      url = "https://example.com",
      defaultSetting = ProxySettingData(),
      proxySelector = FakeProxySelector(
        listOf(
          Proxy(
            Proxy.Type.HTTP,
            InetSocketAddress.createUnresolved("proxy.example.com", 8080)
          )
        )
      )
    )

    assertEquals("proxy", resolved.mode)
    assertEquals("proxy.example.com:8080", resolved.proxy)
  }

  @Test
  fun resolveForUrl_fallsBackToDefaultWhenUrlIsInvalid() {
    val defaultSetting = ProxySettingData(
      mode = "proxy",
      proxy = "default.example.com:3128"
    )

    val resolved = ProxySettingResolver.resolveForUrl(
      url = "://bad-url",
      defaultSetting = defaultSetting,
      proxySelector = FakeProxySelector(emptyList())
    )

    assertEquals(defaultSetting, resolved)
  }

  @Test
  fun formatHostAndPort_omitsInvalidPort() {
    assertEquals("proxy.example.com", ProxySettingResolver.formatHostAndPort("proxy.example.com", -1))
  }

  private class FakeProxySelector(private val proxies: List<Proxy>) : ProxySelector() {
    override fun select(uri: URI): List<Proxy> = proxies

    override fun connectFailed(uri: URI?, sa: java.net.SocketAddress?, ioe: java.io.IOException?) {
    }
  }
}
