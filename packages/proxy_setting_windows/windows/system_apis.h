#include <windows.h>
#include <winhttp.h>

namespace proxy_setting_plugin {
class SystemApis {
public:
  SystemApis();
  virtual ~SystemApis();

  SystemApis(const SystemApis &) = delete;
  SystemApis &operator=(const SystemApis &) = delete;

  virtual HINTERNET HttpOpen(DWORD dwAccessType, LPCWSTR pszProxyW,
                             LPCWSTR pszProxyBypassW, DWORD dwFlags) = 0;
  virtual BOOL GetProxyForUrl(HINTERNET hSession, LPCWSTR lpcwszUrl,
                              WINHTTP_AUTOPROXY_OPTIONS *pAutoProxyOptions,
                              WINHTTP_PROXY_INFO *pProxyInfo) = 0;
  virtual BOOL GetDefaultProxyConfiguration(WINHTTP_PROXY_INFO *proxyInfo) = 0;
  virtual BOOL GetIEProxyConfigForCurrentUser(
      WINHTTP_CURRENT_USER_IE_PROXY_CONFIG *proxyConfig) = 0;
};

class SystemApisImpl : public SystemApis {
public:
  SystemApisImpl();
  virtual ~SystemApisImpl();

  SystemApisImpl(const SystemApisImpl &) = delete;
  SystemApisImpl &operator=(const SystemApisImpl &) = delete;

  virtual HINTERNET HttpOpen(DWORD dwAccessType, LPCWSTR pszProxyW,
                             LPCWSTR pszProxyBypassW, DWORD dwFlags);
  virtual BOOL GetProxyForUrl(HINTERNET hSession, LPCWSTR lpcwszUrl,
                              WINHTTP_AUTOPROXY_OPTIONS *pAutoProxyOptions,
                              WINHTTP_PROXY_INFO *pProxyInfo);
  virtual BOOL GetDefaultProxyConfiguration(WINHTTP_PROXY_INFO *proxyInfo);
  virtual BOOL GetIEProxyConfigForCurrentUser(
      WINHTTP_CURRENT_USER_IE_PROXY_CONFIG *proxyConfig);
};

} // namespace proxy_setting_plugin
