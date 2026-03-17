import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:owany_app/services/solicitacoes_service.dart';

void main() {
  test('getSolicitacoes uses apartamentos/{id}/solicitacoes when incluirHistorico=true', () async {
    Uri? capturedUri;

    final mockClient = MockClient((http.Request request) async {
      capturedUri = request.url;

      final body = jsonEncode({
        'sucesso': true,
        'data': {
          'items': [],
          'total': 0,
          'pageNumber': 1,
          'pageSize': 20,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        }
      });

      return http.Response(body, 200, headers: {'content-type': 'application/json'});
    });

    final service = SolicitacoesService(httpClient: mockClient);

    final result = await service.getSolicitacoes(
      pageNumber: 1,
      pageSize: 20,
      apartamentoId: 'apt1',
      incluirHistorico: true,
    );

    expect(capturedUri, isNotNull);
    expect(capturedUri!.path.toLowerCase(), contains('/apartamentos/apt1/solicitacoes'));
    expect(capturedUri!.queryParameters['incluirHistorico'], 'true');
    expect(result.total, 0);
  });
}
