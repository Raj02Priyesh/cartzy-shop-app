import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Error returned by the API (or a network failure), with a message safe to show users.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Thin JSON client for the Cartzy REST API.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _http;
  final String _baseUrl;

  /// JWT sent as a Bearer token when set.
  String? token;

  /// Called when an authenticated request is rejected (expired or invalid token).
  void Function()? onUnauthorized;

  // The API runs on a free host that sleeps when idle; the first request can take ~50s.
  static const _timeout = Duration(seconds: 75);

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    final sentToken = token;
    if (sentToken != null) request.headers['Authorization'] = 'Bearer $sentToken';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw ApiException('The server is taking too long to respond. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Check your internet connection.');
    }

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    final serverMessage = data is Map ? (data['message'] ?? data['error']) : null;
    final error = ApiException(
      serverMessage?.toString() ?? 'Something went wrong (error ${response.statusCode}).',
      statusCode: response.statusCode,
    );
    if (error.isUnauthorized && sentToken != null) onUnauthorized?.call();
    throw error;
  }
}
