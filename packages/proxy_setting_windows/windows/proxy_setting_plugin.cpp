// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "proxy_setting_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <cwctype>
#include <memory>
#include <optional>
#include <string>

namespace proxy_setting_plugin {

namespace {
using flutter::EncodableMap;
using flutter::EncodableValue;

struct ScopedIeProxyConfig {
  WINHTTP_CURRENT_USER_IE_PROXY_CONFIG value{};

  ~ScopedIeProxyConfig() {
    if (value.lpszAutoConfigUrl) {
      ::GlobalFree(value.lpszAutoConfigUrl);
    }
    if (value.lpszProxy) {
      ::GlobalFree(value.lpszProxy);
    }
    if (value.lpszProxyBypass) {
      ::GlobalFree(value.lpszProxyBypass);
    }
  }
};

struct ScopedProxyInfo {
  WINHTTP_PROXY_INFO value{};

  ~ScopedProxyInfo() {
    if (value.lpszProxy) {
      ::GlobalFree(value.lpszProxy);
    }
    if (value.lpszProxyBypass) {
      ::GlobalFree(value.lpszProxyBypass);
    }
  }
};

struct ScopedSessionHandle {
  explicit ScopedSessionHandle(HINTERNET session_handle)
      : value(session_handle) {}

  ~ScopedSessionHandle() {
    if (value != nullptr) {
      ::WinHttpCloseHandle(value);
    }
  }

  HINTERNET value;
};

struct UrlParts {
  std::wstring scheme;
  std::wstring host;
};

bool LoadCurrentUserProxyConfig(
    SystemApis *system_apis, ScopedIeProxyConfig *proxy_config) {
  if (system_apis->GetIEProxyConfigForCurrentUser(&proxy_config->value)) {
    return true;
  }

  if (::GetLastError() == ERROR_FILE_NOT_FOUND) {
    ::SetLastError(ERROR_SUCCESS);
    return true;
  }

  return false;
}

std::wstring Utf16FromUtf8(const std::string &utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}

std::string Utf8FromUtf16(std::wstring const &src) {
  if (src.empty()) {
    return std::string();
  }
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, src.data(), static_cast<int>(src.size()),
      nullptr, 0, nullptr, nullptr);
  if (target_length == 0) {
    return std::string();
  }
  std::string utf8_string(target_length, '\0');
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, src.data(), static_cast<int>(src.size()),
      utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

std::string Utf8FromWidePtr(const wchar_t *value) {
  if (value == nullptr) {
    return std::string();
  }
  return Utf8FromUtf16(std::wstring(value));
}

std::string GetUrlArgument(const flutter::MethodCall<> &method_call) {
  std::string url = "";
  const auto *arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (arguments != nullptr) {
    auto url_it = arguments->find(EncodableValue("url"));
    if (url_it != arguments->end() && !url_it->second.IsNull()) {
      url = std::get<std::string>(url_it->second);
    }
  }
  return url;
}

std::wstring ToLower(const std::wstring &value) {
  std::wstring lowered = value;
  for (auto &ch : lowered) {
    ch = static_cast<wchar_t>(std::towlower(ch));
  }
  return lowered;
}

std::wstring Trim(const std::wstring &value) {
  const auto start = value.find_first_not_of(L" \t");
  if (start == std::wstring::npos) {
    return std::wstring();
  }
  const auto end = value.find_last_not_of(L" \t");
  return value.substr(start, end - start + 1);
}

std::optional<UrlParts> ParseUrl(const std::wstring &url) {
  URL_COMPONENTS components{};
  components.dwStructSize = sizeof(URL_COMPONENTS);
  components.dwSchemeLength = static_cast<DWORD>(-1);
  components.dwHostNameLength = static_cast<DWORD>(-1);

  if (!::WinHttpCrackUrl(url.c_str(), static_cast<DWORD>(url.size()), 0,
                         &components)) {
    return std::nullopt;
  }

  UrlParts parts;
  if (components.lpszScheme != nullptr && components.dwSchemeLength > 0) {
    parts.scheme.assign(components.lpszScheme, components.dwSchemeLength);
  }
  if (components.lpszHostName != nullptr && components.dwHostNameLength > 0) {
    parts.host.assign(components.lpszHostName, components.dwHostNameLength);
  }
  return parts;
}

bool WildcardMatch(const std::wstring &pattern, const std::wstring &value) {
  const std::wstring lowered_pattern = ToLower(pattern);
  const std::wstring lowered_value = ToLower(value);

  size_t pattern_index = 0;
  size_t value_index = 0;
  size_t star_index = std::wstring::npos;
  size_t match_index = 0;

  while (value_index < lowered_value.size()) {
    if (pattern_index < lowered_pattern.size() &&
        (lowered_pattern[pattern_index] == L'?' ||
         lowered_pattern[pattern_index] == lowered_value[value_index])) {
      ++pattern_index;
      ++value_index;
      continue;
    }
    if (pattern_index < lowered_pattern.size() &&
        lowered_pattern[pattern_index] == L'*') {
      star_index = pattern_index++;
      match_index = value_index;
      continue;
    }
    if (star_index != std::wstring::npos) {
      pattern_index = star_index + 1;
      value_index = ++match_index;
      continue;
    }
    return false;
  }

  while (pattern_index < lowered_pattern.size() &&
         lowered_pattern[pattern_index] == L'*') {
    ++pattern_index;
  }

  return pattern_index == lowered_pattern.size();
}

bool ShouldBypassProxy(const wchar_t *proxy_bypass, const std::wstring &host) {
  if (proxy_bypass == nullptr || host.empty()) {
    return false;
  }

  std::wstring bypass_list(proxy_bypass);
  size_t start = 0;
  while (start <= bypass_list.size()) {
    const size_t separator = bypass_list.find(L';', start);
    std::wstring entry = Trim(bypass_list.substr(
        start, separator == std::wstring::npos ? std::wstring::npos
                                               : separator - start));
    if (!entry.empty()) {
      if (ToLower(entry) == L"<local>") {
        if (host.find(L'.') == std::wstring::npos) {
          return true;
        }
      } else if (WildcardMatch(entry, host)) {
        return true;
      }
    }

    if (separator == std::wstring::npos) {
      break;
    }
    start = separator + 1;
  }

  return false;
}

std::wstring ResolveManualProxyForScheme(const wchar_t *proxy,
                                         const std::wstring &scheme) {
  if (proxy == nullptr) {
    return std::wstring();
  }

  std::wstring proxy_list(proxy);
  std::wstring default_proxy;
  const std::wstring lowered_scheme = ToLower(scheme);

  size_t start = 0;
  while (start <= proxy_list.size()) {
    const size_t separator = proxy_list.find(L';', start);
    std::wstring entry = Trim(proxy_list.substr(
        start, separator == std::wstring::npos ? std::wstring::npos
                                               : separator - start));
    if (!entry.empty()) {
      const size_t equals = entry.find(L'=');
      if (equals == std::wstring::npos) {
        if (default_proxy.empty()) {
          default_proxy = entry;
        }
      } else {
        const std::wstring key = ToLower(Trim(entry.substr(0, equals)));
        const std::wstring value = Trim(entry.substr(equals + 1));
        if (key == lowered_scheme && !value.empty()) {
          return value;
        }
      }
    }

    if (separator == std::wstring::npos) {
      break;
    }
    start = separator + 1;
  }

  return default_proxy;
}

std::wstring ResolveManualProxyForUrl(
    const WINHTTP_CURRENT_USER_IE_PROXY_CONFIG &proxyConfig,
    const std::wstring &url) {
  if (proxyConfig.lpszProxy == nullptr) {
    return std::wstring();
  }

  const auto parts = ParseUrl(url);
  if (!parts.has_value()) {
    return std::wstring(proxyConfig.lpszProxy);
  }
  if (ShouldBypassProxy(proxyConfig.lpszProxyBypass, parts->host)) {
    return std::wstring();
  }
  return ResolveManualProxyForScheme(proxyConfig.lpszProxy, parts->scheme);
}

bool HasAutoProxyConfig(
    const WINHTTP_CURRENT_USER_IE_PROXY_CONFIG &proxyConfig) {
  return proxyConfig.fAutoDetect == TRUE ||
         (proxyConfig.lpszAutoConfigUrl != nullptr &&
          proxyConfig.lpszAutoConfigUrl[0] != L'\0');
}

bool HasManualProxyConfig(
    const WINHTTP_CURRENT_USER_IE_PROXY_CONFIG &proxyConfig) {
  return proxyConfig.lpszProxy != nullptr && proxyConfig.lpszProxy[0] != L'\0';
}

// Returns a WINHTTP_PROXY_INFO whose lpszProxy points into |proxy|.
// The caller must ensure |proxy| outlives the returned struct.
WINHTTP_PROXY_INFO CreateProxyInfoFromProxyString(const std::wstring &proxy) {
  WINHTTP_PROXY_INFO proxy_info{};
  proxy_info.dwAccessType = proxy.empty() ? WINHTTP_ACCESS_TYPE_NO_PROXY
                                          : WINHTTP_ACCESS_TYPE_NAMED_PROXY;
  proxy_info.lpszProxy = proxy.empty() ? nullptr : const_cast<LPWSTR>(proxy.c_str());
  return proxy_info;
}
} // namespace

// static
void ProxySettingPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      registrar->messenger(), "playon.jp/proxy_setting_windows",
      &flutter::StandardMethodCodec::GetInstance());

  std::unique_ptr<ProxySettingPlugin> plugin =
      std::make_unique<ProxySettingPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ProxySetting::ProxySetting() {
  mode = "direct";
  isAutoDetect = false;
  proxy = "";
  proxyBypass = "";
  configUrl = "";
}
ProxySetting::~ProxySetting() = default;

ProxySettingPlugin::ProxySettingPlugin()
    : system_apis_(std::make_unique<SystemApisImpl>()) {}

ProxySettingPlugin::ProxySettingPlugin(std::unique_ptr<SystemApis> system_apis)
    : system_apis_(std::move(system_apis)) {}

ProxySettingPlugin::~ProxySettingPlugin() = default;

void ProxySettingPlugin::HandleMethodCall(
    const flutter::MethodCall<> &method_call,
    std::unique_ptr<flutter::MethodResult<>> result) {
  std::string url = GetUrlArgument(method_call);
  if (method_call.method_name().compare("proxySetting") == 0) {
    ProxySetting *setting = nullptr;
    if (url.empty()) {
      setting = GetDefaultProxyConfig();
    } else {
      setting = GetProxyForUrl(url);
    }
    if (setting == nullptr) {
      DWORD code = GetLastError();
      result->Error("proxy_error", "Failed get proxy setting",
                    EncodableValue((int)code));
    } else {
      EncodableMap map = EncodableMap();
      map[EncodableValue("mode")] = EncodableValue(setting->mode);
      map[EncodableValue("isAutoDetect")] =
          EncodableValue((int)setting->isAutoDetect);
      map[EncodableValue("proxy")] = EncodableValue(setting->proxy);
      map[EncodableValue("proxyBypass")] = EncodableValue(setting->proxyBypass);
      map[EncodableValue("configUrl")] = EncodableValue(setting->configUrl);
      delete setting;
      setting = nullptr;
      result->Success(EncodableValue(map));
    }
  } else {
    result->NotImplemented();
  }
}

ProxySetting *ProxySettingPlugin::GetProxyForUrl(std::string url) {
  ScopedIeProxyConfig proxyConfig;
  if (!LoadCurrentUserProxyConfig(system_apis_.get(), &proxyConfig)) {
    return nullptr;
  }

  const std::wstring wide_url = Utf16FromUtf8(url);
  if (wide_url.empty()) {
    ::SetLastError(ERROR_INVALID_PARAMETER);
    return nullptr;
  }

  const bool has_manual_proxy = HasManualProxyConfig(proxyConfig.value);
  const std::wstring resolved_manual_proxy =
      ResolveManualProxyForUrl(proxyConfig.value, wide_url);
  if (!HasAutoProxyConfig(proxyConfig.value)) {
    if (has_manual_proxy) {
      const WINHTTP_PROXY_INFO proxyInfo =
          CreateProxyInfoFromProxyString(resolved_manual_proxy);
      return ConvertSetting(proxyConfig.value, proxyInfo);
    }

    ScopedProxyInfo defaultProxyInfo;
    if (system_apis_->GetDefaultProxyConfiguration(&defaultProxyInfo.value)) {
      return ConvertSetting(proxyConfig.value, defaultProxyInfo.value);
    }
    return nullptr;
  }

  ScopedSessionHandle session(system_apis_->HttpOpen(
      WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME,
      WINHTTP_NO_PROXY_BYPASS, 0));
  if (session.value == nullptr) {
    return nullptr;
  }

  WINHTTP_AUTOPROXY_OPTIONS proxyOptions{};
  if (proxyConfig.value.fAutoDetect) {
    proxyOptions.dwFlags |= WINHTTP_AUTOPROXY_AUTO_DETECT;
    proxyOptions.dwAutoDetectFlags =
        WINHTTP_AUTO_DETECT_TYPE_DHCP | WINHTTP_AUTO_DETECT_TYPE_DNS_A;
  }
  if (proxyConfig.value.lpszAutoConfigUrl != nullptr &&
      proxyConfig.value.lpszAutoConfigUrl[0] != L'\0') {
    proxyOptions.dwFlags |= WINHTTP_AUTOPROXY_CONFIG_URL;
    proxyOptions.lpszAutoConfigUrl = proxyConfig.value.lpszAutoConfigUrl;
  }
  proxyOptions.fAutoLogonIfChallenged = TRUE;

  ScopedProxyInfo proxyInfo;
  BOOL apiResult = system_apis_->GetProxyForUrl(
      session.value, wide_url.c_str(), &proxyOptions, &proxyInfo.value);
  if (apiResult) {
    return ConvertSetting(proxyConfig.value, proxyInfo.value);
  }

  if (has_manual_proxy) {
    const WINHTTP_PROXY_INFO fallbackInfo =
        CreateProxyInfoFromProxyString(resolved_manual_proxy);
    return ConvertSetting(proxyConfig.value, fallbackInfo);
  }

  ScopedProxyInfo defaultProxyInfo;
  if (system_apis_->GetDefaultProxyConfiguration(&defaultProxyInfo.value)) {
    return ConvertSetting(proxyConfig.value, defaultProxyInfo.value);
  }

  return nullptr;
}

ProxySetting *ProxySettingPlugin::GetDefaultProxyConfig() {
  ScopedIeProxyConfig proxyConfig;
  if (!LoadCurrentUserProxyConfig(system_apis_.get(), &proxyConfig)) {
    return nullptr;
  }

  if (HasManualProxyConfig(proxyConfig.value)) {
    const std::wstring proxy =
        ResolveManualProxyForScheme(proxyConfig.value.lpszProxy, L"http");
    const WINHTTP_PROXY_INFO proxyInfo = CreateProxyInfoFromProxyString(proxy);
    return ConvertSetting(proxyConfig.value, proxyInfo);
  }

  ScopedProxyInfo defaultProxyInfo;
  if (system_apis_->GetDefaultProxyConfiguration(&defaultProxyInfo.value)) {
    return ConvertSetting(proxyConfig.value, defaultProxyInfo.value);
  }

  return nullptr;
}

ProxySetting *ProxySettingPlugin::ConvertSetting(
    const WINHTTP_CURRENT_USER_IE_PROXY_CONFIG &proxyConfig,
    const WINHTTP_PROXY_INFO &proxyInfo) {
  ProxySetting *setting = new ProxySetting();

  if (proxyInfo.dwAccessType == WINHTTP_ACCESS_TYPE_NAMED_PROXY) {
    setting->mode = "proxy";
    setting->proxy = Utf8FromWidePtr(proxyInfo.lpszProxy);
  } else if (proxyInfo.dwAccessType == WINHTTP_ACCESS_TYPE_NO_PROXY) {
    setting->mode = "direct";
    setting->proxy = "";
  } else {
    setting->proxy = Utf8FromWidePtr(proxyConfig.lpszProxy);
    setting->mode = setting->proxy.empty() ? "direct" : "proxy";
  }
  setting->isAutoDetect = proxyConfig.fAutoDetect == TRUE;
  setting->proxyBypass = Utf8FromWidePtr(proxyConfig.lpszProxyBypass);
  if (setting->proxyBypass.empty()) {
    setting->proxyBypass = Utf8FromWidePtr(proxyInfo.lpszProxyBypass);
  }
  setting->configUrl = Utf8FromWidePtr(proxyConfig.lpszAutoConfigUrl);

  return setting;
}

} // namespace proxy_setting_plugin
