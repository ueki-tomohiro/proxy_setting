#include "include/proxy_setting_windows/proxy_setting_windows.h"

#include <flutter/plugin_registrar_windows.h>

#include "proxy_setting_plugin.h"

void ProxySettingWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  proxy_setting_plugin::ProxySettingPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}