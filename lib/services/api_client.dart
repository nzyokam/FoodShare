import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Android emulator → 10.0.2.2:8000
  // Physical device on same WiFi → use your machine's local IP
  // Production → replace with your deployed backend URL
  static const baseUrl = 'http://192.168.1.4:8000';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessKey = 'fs_access_token';
  static const _refreshKey = 'fs_refresh_token';

  // ── Token management ──────────────────────────────────────────────────────

  static Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final newToken = jsonDecode(res.body)['access_token'] as String;
        await _storage.write(key: _accessKey, value: newToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = body != null ? jsonEncode(body) : null;
    const timeout = Duration(seconds: 15);
    return switch (method) {
      'GET' => http.get(uri, headers: headers).timeout(timeout),
      'POST' => http.post(uri, headers: headers, body: encoded).timeout(timeout),
      'PUT' => http.put(uri, headers: headers, body: encoded).timeout(timeout),
      'PATCH' => http.patch(uri, headers: headers, body: encoded).timeout(timeout),
      'DELETE' => http.delete(uri, headers: headers).timeout(timeout),
      _ => throw UnsupportedError('Unknown HTTP method: $method'),
    };
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String?>? query,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null) {
      final filtered = Map.fromEntries(
        query.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!)),
      );
      if (filtered.isNotEmpty) uri = uri.replace(queryParameters: filtered);
    }

    var headers = await _headers();
    var response = await _send(method, uri, headers, body);

    if (response.statusCode == 401) {
      if (await _tryRefresh()) {
        headers = await _headers();
        response = await _send(method, uri, headers, body);
      }
    }

    return response;
  }

  static Future<http.Response> get(String path, {Map<String, String?>? query}) =>
      request('GET', path, query: query);

  static Future<http.Response> post(String path, {Map<String, dynamic>? body}) =>
      request('POST', path, body: body);

  static Future<http.Response> put(String path, {Map<String, dynamic>? body}) =>
      request('PUT', path, body: body);

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body}) =>
      request('PATCH', path, body: body);

  static Future<http.Response> delete(String path) => request('DELETE', path);

  // ── Error helper ──────────────────────────────────────────────────────────

  static String errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map;
      return (body['detail'] ?? 'Request failed (${res.statusCode})').toString();
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}
