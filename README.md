[![pub package](https://img.shields.io/pub/v/detect_proxy_setting.svg)](https://pub.dev/packages/detect_proxy_setting)

# proxy_setting

Flutter plugin workspace for reading the system HTTP proxy configuration.

The package you normally add to an app is `detect_proxy_setting`. This repository also contains the platform-specific implementations for Android, iOS, macOS, and Windows.

## Packages

- `packages/detect_proxy_setting`: public Flutter plugin used by applications
- `packages/proxy_setting_android`: Android implementation
- `packages/proxy_setting_ios`: iOS implementation
- `packages/proxy_setting_macos`: macOS implementation
- `packages/proxy_setting_windows`: Windows implementation
- `packages/proxy_setting_platform_interface`: shared platform interface and model
- `tests`: sample Flutter app used for manual verification

## Supported platforms

- Android
- iOS
- macOS
- Windows

Linux and Web are not implemented in this repository.

## Installation

Add `detect_proxy_setting` to your `pubspec.yaml`.

```yaml
dependencies:
  detect_proxy_setting: ^0.0.8
```

## Usage

Read the current system proxy setting:

```dart
import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:proxy_setting_platform_interface/proxy_setting.dart';

final ProxySetting? setting = await proxySetting();

if (setting == null || setting.mode == ProxySettingModeEnum.direct) {
  print('DIRECT');
} else {
  print('PROXY ${setting.proxy}');
}
```

If you want to resolve the proxy for a specific URL, pass `url`:

```dart
final setting = await proxySetting(url: 'https://example.com');
```

This is useful on platforms that support PAC or auto-detected proxy configuration.

## Using with `HttpOverrides`

The repository includes a simple example app under [`tests`](./tests). The following pattern matches that app:

```dart
import 'dart:io';

import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:proxy_setting_platform_interface/proxy_setting.dart';

class HttpOverridesImpl extends HttpOverrides {
  String address = '';
  String type = 'DIRECT';

  @override
  String findProxyFromEnvironment(Uri uri, Map<String, String>? environment) {
    if (type == 'DIRECT') {
      return 'DIRECT';
    }
    return 'PROXY $address';
  }

  Future<void> init() async {
    final setting = await proxySetting();

    if (setting == null || setting.mode == ProxySettingModeEnum.direct) {
      type = 'DIRECT';
      address = '';
      return;
    }

    if (setting.proxy.isNotEmpty) {
      type = 'PROXY';
      address = setting.proxy;
    }
  }
}
```

## Returned values

`proxySetting()` returns a `ProxySetting` object with these fields:

- `mode`: `proxy` or `direct`
- `isAutoDetect`: whether auto-detection is enabled
- `proxy`: proxy host and port such as `proxy.example.com:8080`
- `proxyBypass`: bypass list when the platform provides it
- `configUrl`: PAC / auto-config URL when the platform provides it

Available fields depend on the current platform and OS configuration.

## Development

This repository is managed with Melos.

```bash
melos test
```

For a manual check, run the sample app in [`tests`](./tests).
