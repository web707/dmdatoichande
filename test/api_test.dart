import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hanoi_travel_guide/core/api.dart';

void main() {
  test('fetch decodes UTF8 and keeps the server identity', () async {
    final api = GuideApi(
      baseUrl: 'http://localhost:8090',
      client: MockClient((request) async {
        expect(request.url.path, '/api/phrases');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode([
              {'id': '1', 'vietnamese_text': 'Cảm ơn'},
            ]),
          ),
          200,
        );
      }),
    );
    final rows = await api.fetchRecords('phrases');
    expect(rows.single.id, '1');
    expect(rows.single.title, 'Cảm ơn');
    api.dispose();
  });
  test(
    'authenticated writes send bearer token and validated payload',
    () async {
      final api = GuideApi(
        baseUrl: 'http://localhost:8090',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer example-token');
          expect(jsonDecode(request.body)['vietnamese_text'], 'Xin chào');
          return http.Response('{"id":"created"}', 201);
        }),
      );
      api.token = 'example-token';
      await api.saveRecord('phrases', {'vietnamese_text': 'Xin chào'});
      api.dispose();
    },
  );
  test('backend failures become actionable errors', () async {
    final api = GuideApi(
      baseUrl: 'http://localhost:8090',
      client: MockClient(
        (_) async => http.Response('{"error":"Please sign in again."}', 401),
      ),
    );
    await expectLater(
      api.fetchRecords('places'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    api.dispose();
  });
}
