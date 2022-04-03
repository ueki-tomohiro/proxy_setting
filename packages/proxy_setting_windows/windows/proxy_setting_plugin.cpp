// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "proxy_setting_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <sstream>
#include <string>

namespace proxy_setting_plugin {

namespace {
using flutter::EncodableMap;
using flutter::EncodableValue;

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
  std::size_t converted{};
  std::vector<char> dest(src.size() * sizeof(wchar_t) + 1, '\0');
  if (::_wcstombs_s_l(&converted, dest.data(), dest.size(), src.data(),
                      _TRUNCATE, ::_create_locale(LC_ALL, "jpn")) != 0) {
    throw std::system_error{errno, std::system_category()};
  }
  dest.resize(std::char_traits<char>::length(dest.data()));
  dest.shrink_to_fit();
  return std::string(dest.begin(), dest.end());
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

std::string ToString(BYTE *data, int len) {
  int length = len;
  length = (len - 1) & ~1;
  char ms[MAX_LEN + 1];
  size_t mslen;
  wcstombs_s(&mslen, ms, MAX_LEN, reinterpret_cast<WCHAR *>(data), length);
  return std::string(ms, mslen - 1);
}

std::string ToString(WCHAR *data, int len) {
  std::wstring base = std::wstring(data, len);
  return Utf8FromUtf16(base);
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
  WINHTTP_CURRENT_USER_IE_PROXY_CONFIG proxyConfig;
  BOOL apiResult = system_apis_->GetIEProxyConfigForCurrentUser(&proxyConfig);
  if (apiResult == FALSE) {
    return nullptr;
  }

  HINTERNET hSession = system_apis_->HttpOpen(
      WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME,
      WINHTTP_NO_PROXY_BYPASS, WINHTTP_FLAG_ASYNC);

  if (hSession == nullptr) {
    return nullptr;
  }

  WINHTTP_AUTOPROXY_OPTIONS proxyOptions;
  ZeroMemory(&proxyOptions, sizeof(WINHTTP_AUTOPROXY_OPTIONS));
  if (proxyConfig.fAutoDetect) {
    proxyOptions.dwFlags = WINHTTP_AUTOPROXY_AUTO_DETECT;
    proxyOptions.dwAutoDetectFlags =
        WINHTTP_AUTO_DETECT_TYPE_DHCP | WINHTTP_AUTO_DETECT_TYPE_DNS_A;
  } else if (proxyConfig.lpszAutoConfigUrl) {
    proxyOptions.dwFlags = WINHTTP_AUTOPROXY_CONFIG_URL;
    proxyOptions.lpszAutoConfigUrl = proxyConfig.lpszAutoConfigUrl;
  }

  WINHTTP_PROXY_INFO proxyInfo;
  apiResult = system_apis_->GetProxyForUrl(hSession, Utf16FromUtf8(url).c_str(),
                                           &proxyOptions, &proxyInfo);
  if (apiResult) {
    return ConvertSetting(proxyConfig, proxyInfo);
  } else if (ERROR_WINHTTP_AUTODETECTION_FAILED == GetLastError()) {
    if (system_apis_->GetDefaultProxyConfiguration(&proxyInfo)) {
      return ConvertSetting(proxyConfig, proxyInfo);
    }
  }

  return nullptr;
}

ProxySetting *ProxySettingPlugin::GetDefaultProxyConfig() {
  WINHTTP_CURRENT_USER_IE_PROXY_CONFIG proxyConfig;
  BOOL apiResult = system_apis_->GetIEProxyConfigForCurrentUser(&proxyConfig);
  if (apiResult == FALSE) {
    return nullptr;
  }
  WINHTTP_PROXY_INFO proxyInfo;
  BOOL result = system_apis_->GetDefaultProxyConfiguration(&proxyInfo);
  if (result == FALSE) {
    return nullptr;
  }

  return ConvertSetting(proxyConfig, proxyInfo);
}

ProxySetting *ProxySettingPlugin::ConvertSetting(
    WINHTTP_CURRENT_USER_IE_PROXY_CONFIG &proxyConfig,
    WINHTTP_PROXY_INFO &proxyInfo) {
  ProxySetting *setting = new ProxySetting();

  if (proxyInfo.dwAccessType == WINHTTP_ACCESS_TYPE_NAMED_PROXY) {
    setting->mode = "proxy";
  } else if (proxyInfo.dwAccessType == WINHTTP_ACCESS_TYPE_NO_PROXY) {
    setting->mode = "direct";
  }
  if (proxyConfig.fAutoDetect) {
    setting->isAutoDetect = true;
  }

  if (proxyConfig.lpszProxy) {
    size_t proxyLen = wcslen(proxyConfig.lpszProxy);
    setting->proxy = ToString(proxyConfig.lpszProxy, (int)proxyLen);
    ::GlobalFree(proxyConfig.lpszProxy);
  }

  if (proxyConfig.lpszProxyBypass) {
    size_t proxyBypassLen = wcslen(proxyConfig.lpszProxyBypass);
    setting->proxyBypass =
        ToString(proxyConfig.lpszProxyBypass, (int)proxyBypassLen);
    ::GlobalFree(proxyConfig.lpszProxyBypass);
  }

  if (proxyConfig.lpszAutoConfigUrl) {
    size_t autoConfigUrlLen = wcslen(proxyConfig.lpszAutoConfigUrl);
    setting->configUrl =
        ToString(proxyConfig.lpszAutoConfigUrl, (int)autoConfigUrlLen);
    ::GlobalFree(proxyConfig.lpszAutoConfigUrl);
  }

  return setting;
}

} // namespace proxy_setting_plugin
