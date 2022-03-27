import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:proxy_setting_platform_interface/proxy_setting.dart';
import 'package:tests/service.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Proxy Setting'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  void _checkHttpStatus(WidgetRef ref) {
    final notifier = ref.read(httpNotifier.notifier);
    notifier.fetch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final httpStatus = ref.watch(httpNotifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'HttpStatus:',
            ),
            Text(
              '$httpStatus',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _checkHttpStatus(ref),
        tooltip: 'Check',
        child: const Icon(Icons.network_check),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
