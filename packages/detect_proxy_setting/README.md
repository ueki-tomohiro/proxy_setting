[![pub package](https://img.shields.io/pub/v/detect_proxy_setting.svg)](https://pub.dev/packages/detect_proxy_setting)

# detect_proxy_setting

Flutter plugin for reading the system HTTP proxy configuration.

Supported platforms:

- Android
- iOS
- macOS
- Windows

## Installation

```yaml
dependencies:
  detect_proxy_setting: ^0.0.10
```

## Usage

Read the current system proxy setting:

```dart
import 'package:detect_proxy_setting/detect_proxy_setting.dart';

final ProxySetting? setting = await proxySetting();

if (setting == null || setting.mode == ProxySettingModeEnum.direct) {
  print('DIRECT');
} else {
  print('PROXY ${setting.proxy}');
}
```

Resolve the proxy for a specific URL:

```dart
final ProxySetting? setting =
    await proxySetting(url: 'https://example.com');
```

`proxySetting()` returns a `ProxySetting` with the following fields:

- `mode`: `proxy` or `direct`
- `isAutoDetect`: whether automatic proxy detection is enabled
- `proxy`: proxy host and port such as `proxy.example.com:8080`
- `proxyBypass`: bypass list when provided by the platform
- `configUrl`: PAC or auto-config URL when provided by the platform

See [`example/lib/main.dart`](example/lib/main.dart) for a complete example app.
