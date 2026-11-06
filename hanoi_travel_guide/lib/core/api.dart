import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'catalog.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class GuideApi {
  final String baseUrl;
  final http.Client _client;
  final http.Client _eventsClient;
  String? token;
  bool _disposed = false;
  GuideApi({String? baseUrl, http.Client? client, http.Client? eventsClient})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: '',
          ).replaceAll(RegExp(r'/$'), ''),
      _client = client ?? http.Client(),
      _eventsClient = eventsClient ?? http.Client();

  String get effectiveBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    if (kIsWeb) return '${Uri.base.scheme}://${Uri.base.host}:8090';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8090'
        : 'http://localhost:8090';
  }

  Uri uri(String path) => Uri.parse('$effectiveBaseUrl/api$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final request = http.Request(method, uri(path))..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request),
      ).timeout(const Duration(seconds: 12));
      dynamic data;
      if (response.bodyBytes.isNotEmpty) {
        try {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {
          throw const ApiException(
            502,
            'The server returned an unexpected response.',
          );
        }
      }
      if (response.statusCode >= 400) {
        throw ApiException(
          response.statusCode,
          data is Map
              ? data['error']?.toString() ?? 'Request failed.'
              : 'Request failed.',
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        0,
        'The server is taking too long. Please retry.',
      );
    } catch (_) {
      throw const ApiException(
        0,
        'Cannot reach the guide server. Check your connection and try again.',
      );
    }
  }

  Future<List<CatalogRecord>> fetchRecords(String collection) async {
    final data = await _request('GET', '/$collection') as List;
    return data
        .map(
          (row) =>
              CatalogRecord(collection, Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchEmergency() async {
    final data = await _request('GET', '/emergency') as List;
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> saveRecord(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      '/$collection${id == null ? '' : '/$id'}',
      data,
    );
  }

  Future<void> deleteRecord(CatalogRecord record) async {
    await _request('DELETE', '/${record.collection}/${record.id}');
  }

  Future<Map<String, dynamic>> authenticate(
    String email,
    String password, {
    bool register = false,
  }) async {
    final result = await _request(
      'POST',
      '/auth/${register ? 'register' : 'login'}',
      {'email': email.trim().toLowerCase(), 'password': password},
    );
    token = result['token'] as String;
    return Map<String, dynamic>.from(result['user'] as Map);
  }

  Future<void> logout() async {
    try {
      if (token != null) await _request('POST', '/auth/logout');
    } finally {
      token = null;
    }
  }

  // The stream carries only invalidations, never personal content or credentials.
  Stream<Map<String, dynamic>> watchChanges() async* {
    while (!_disposed) {
      try {
        final response = await _eventsClient
            .send(
              http.Request('GET', uri('/events'))
                ..headers['Accept'] = 'text/event-stream',
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          throw const ApiException(503, 'Live updates unavailable');
        }
        await for (final line
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (_disposed) return;
          if (line.startsWith('data: ')) {
            yield Map<String, dynamic>.from(
              jsonDecode(line.substring(6)) as Map,
            );
          }
        }
      } catch (_) {
        /* Reconnect below and refresh a complete snapshot on ready. */
      }
      if (_disposed) return;
      yield {'type': 'reconnecting'};
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  void dispose() {
    _disposed = true;
    _client.close();
    _eventsClient.close();
  }
}
