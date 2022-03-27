#include "system_apis.h"

#include <windows.h>
#include <winhttp.h>

namespace proxy_setting_plugin {

SystemApis::SystemApis() {}

SystemApis::~SystemApis() {}

SystemApisImpl::SystemApisImpl() {}

SystemApisImpl::~SystemApisImpl() {}

BOOL SystemApisImpl::GetProxyForUrl(
    HINTERNET hSession, LPCWSTR lpcwszUrl,
    WINHTTP_AUTOPROXY_OPTIONS *pAutoProxyOptions,
    WINHTTP_PROXY_INFO *pProxyInfo) {
  return ::WinHttpGetProxyForUrl(hSession, lpcwszUrl, pAutoProxyOptions,
                                 pProxyInfo);
}

BOOL SystemApisImpl::GetDefaultProxyConfiguration(
    WINHTTP_PROXY_INFO *proxyInfo) {
  return ::WinHttpGetDefaultProxyConfiguration(proxyInfo);
}

BOOL SystemApisImpl::GetIEProxyConfigForCurrentUser(
    WINHTTP_CURRENT_USER_IE_PROXY_CONFIG *proxyConfig) {
  return ::WinHttpGetIEProxyConfigForCurrentUser(proxyConfig);
}

} // namespace proxy_setting_plugin
