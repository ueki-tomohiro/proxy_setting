import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class HttpNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  Future<void> fetch() async {
    state = null;
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse("https://playon.jp"),
      );
      state = response.statusCode;
    } catch (_) {
      state = HttpStatus.badRequest;
    } finally {
      client.close();
    }
  }
}

final httpNotifier =
    NotifierProvider.autoDispose<HttpNotifier, int?>(HttpNotifier.new);
