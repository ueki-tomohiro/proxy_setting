This package detect proxy setting in desktop.
Supported os are MacOS, Windows.

## Usage

To See `/tests` folder.

### Initialize
```dart
class HttpOverridesImpl extends HttpOverrides {
  String address = "";
  String type = "DIRECT";

  @override
  String findProxyFromEnvironment(Uri uri, Map<String, String>? environment) {
    if (type == "DIRECT") {
      return "DIRECT";
    }
    return 'PROXY $address';
  }

  Future init() async {
    final setting = await proxySetting();
    print(setting);
    if (setting == null || setting.mode == ProxySettingModeEnum.direct) {
      type = "DIRECT";
    } else if (setting.mode == ProxySettingModeEnum.proxy &&
        setting.proxy.isNotEmpty) {
      type = "PROXY";
      address = setting.proxy;
    }
  }
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var httpOverrides = HttpOverridesImpl();
  await httpOverrides.init();
  HttpOverrides.global = httpOverrides;

  runApp(const ProviderScope(child: MyApp()));
}
```