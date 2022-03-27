// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>
#include <winhttp.h>

#include <memory>
#include <optional>
#include <sstream>
#include <string>

#include "system_apis.h"

#define MAX_LEN 2048

namespace proxy_setting_plugin {
class ProxySetting {
public:
  std::string mode;
  boolean isAutoDetect;
  std::string proxy;
  std::string proxyBypass;
  std::string configUrl;

  ProxySetting();
  virtual ~ProxySetting();
};

class ProxySettingPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  ProxySettingPlugin();

  // Creates a plugin instance with the given SystemApi instance.
  //
  // Exists for unit testing with mock implementations.
  ProxySettingPlugin(std::unique_ptr<SystemApis> system_apis);

  virtual ~ProxySettingPlugin();

  // Disallow copy and move.
  ProxySettingPlugin(const ProxySettingPlugin &) = delete;
  ProxySettingPlugin &operator=(const ProxySettingPlugin &) = delete;

  // Called when a method is called on the plugin channel.
  void HandleMethodCall(const flutter::MethodCall<> &method_call,
                        std::unique_ptr<flutter::MethodResult<>> result);

private:
  ProxySetting *HttpGetIEProxyConfigForCurrentUser();

  std::unique_ptr<SystemApis> system_apis_;
};

} // namespace proxy_setting_plugin
