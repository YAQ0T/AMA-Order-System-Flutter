import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient() {
    if (kIsWeb) {
      _client = http.Client();
    } else {
      final ioClient = HttpClient();
      if (ApiConfig.allowBadCertificates) {
        ioClient.badCertificateCallback = (cert, host, port) => true;
      }
      _client = IOClient(ioClient);
    }
  }

  late final http.Client _client;
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final baseConfig = ApiConfig.baseUrl.trim();
    final base = path.startsWith('http')
        ? ''
        : (() {
            // On web, prefer the current origin when baseUrl points to localhost or is blank.
            if (kIsWeb && (baseConfig.isEmpty || baseConfig.contains('localhost') || baseConfig.contains('127.0.0.1'))) {
              return Uri.base.origin;
            }
            return baseConfig;
          })();
    final normalized = path.startsWith('http') ? path : '$base$path';
    return Uri.parse(normalized).replace(queryParameters: query);
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    return _client.get(_buildUri(path, query), headers: _headers(json: false));
  }

  Future<http.Response> post(String path, {Object? body}) {
    return _client.post(_buildUri(path), headers: _headers(), body: jsonEncode(body));
  }

  Future<http.Response> put(String path, {Object? body}) {
    return _client.put(_buildUri(path), headers: _headers(), body: jsonEncode(body));
  }

  Future<http.Response> delete(String path) {
    return _client.delete(_buildUri(path), headers: _headers(json: false));
  }
}
