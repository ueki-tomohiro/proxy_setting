import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:http/http.dart' as http;

class HttpNotifier extends StateNotifier<int?> {
  HttpNotifier() : super(null);

  Future fetch() async {
    state = null;
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse("https://playon.jp"),
      );
      state = response.statusCode;
    } catch (_) {
      state = HttpStatus.badRequest;
    }
  }
}

final httpNotifier = StateNotifierProvider.autoDispose<HttpNotifier, int?>(
    (ref) => HttpNotifier());
