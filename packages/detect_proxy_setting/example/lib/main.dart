import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProxySettingExampleApp());
}

class ProxySettingExampleApp extends StatelessWidget {
  const ProxySettingExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'detect_proxy_setting example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ProxySettingHomePage(),
    );
  }
}

class ProxySettingHomePage extends StatefulWidget {
  const ProxySettingHomePage({super.key});

  @override
  State<ProxySettingHomePage> createState() => _ProxySettingHomePageState();
}

class _ProxySettingHomePageState extends State<ProxySettingHomePage> {
  ProxySetting? _setting;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadProxySetting();
  }

  Future<void> _loadProxySetting() async {
    try {
      final setting = await proxySetting(url: 'https://example.com');
      if (!mounted) {
        return;
      }
      setState(() {
        _setting = setting;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Proxy Setting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _error != null
            ? Text('Failed to read proxy setting: $_error')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proxy setting', style: textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _SettingRow(
                    label: 'Mode',
                    value: _setting?.mode.name ?? 'loading...',
                  ),
                  _SettingRow(
                    label: 'Auto detect',
                    value: _setting?.isAutoDetect.toString() ?? 'loading...',
                  ),
                  _SettingRow(
                    label: 'Proxy',
                    value: _setting?.proxy.isNotEmpty == true
                        ? _setting!.proxy
                        : '(empty)',
                  ),
                  _SettingRow(
                    label: 'Bypass',
                    value: _setting?.proxyBypass.isNotEmpty == true
                        ? _setting!.proxyBypass
                        : '(empty)',
                  ),
                  _SettingRow(
                    label: 'Config URL',
                    value: _setting?.configUrl.isNotEmpty == true
                        ? _setting!.configUrl
                        : '(empty)',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loadProxySetting,
                    child: const Text('Reload'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
