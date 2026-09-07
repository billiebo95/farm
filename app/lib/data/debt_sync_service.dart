import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/debt.dart';
import 'price_sync_service.dart';

/// Talks to the same PriceSync Apps Script endpoint used for the price list
/// and order log (see `PriceSync.gs`), for the debt ledger:
///  - [submitOperation] POSTs one charge/payment as it happens — `doPost`
///    there tells it apart from an order by `type: "debt"`.
///  - [sendSms] POSTs the client's operation history for the script to
///    forward to an SMS gateway (`type: "sms"`).
///  - [fetchLedger] GETs `?type=debts`, so every admin device ends up
///    looking at the same balances rather than only what it posted itself.
class DebtSyncService {
  const DebtSyncService({this.endpoint = PriceSyncService.defaultEndpoint});

  final String endpoint;

  Future<void> submitOperation({
    required String code,
    required String client,
    required DebtOpKind kind,
    required double amount,
    required double balanceAfter,
    required String date,
    String comment = '',
    Duration timeout = const Duration(seconds: 20),
  }) {
    return _post({
      'type': 'debt',
      'code': code,
      'client': client,
      'kind': kind == DebtOpKind.charge ? 'charge' : 'payment',
      'amount': amount,
      'balanceAfter': balanceAfter,
      'date': date,
      'comment': comment,
    }, timeout: timeout);
  }

  /// Sends [text] (the client's debt history) to [phone] via whatever SMS
  /// gateway the script is configured with. Throws [PriceSyncException] if
  /// the gateway isn't configured or rejects the message — same as every
  /// other failure here, callers turn it into a toast rather than crashing.
  Future<void> sendSms({required String phone, required String text, Duration timeout = const Duration(seconds: 20)}) {
    return _post({'type': 'sms', 'phone': phone, 'text': text}, timeout: timeout);
  }

  /// Pulls the current debt ledger for every client — grouped by delivery
  /// code, each with its full operation history in chronological order.
  Future<Map<String, List<DebtOperation>>> fetchLedger({Duration timeout = const Duration(seconds: 20)}) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: {'type': 'debts'});
    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } catch (e) {
      throw PriceSyncException('Не удалось связаться с Google Диском: $e');
    }

    if (response.statusCode != 200) {
      throw PriceSyncException('Сервер вернул ошибку ${response.statusCode}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw PriceSyncException('Не удалось разобрать ответ сервера: $e');
    }

    final rawDebts = json['debts'];
    if (rawDebts is! List) return {};

    final result = <String, List<DebtOperation>>{};
    for (final rawClient in rawDebts) {
      if (rawClient is! Map) continue;
      final code = (rawClient['code'] as String?)?.trim() ?? '';
      if (code.isEmpty) continue;

      final rawOps = rawClient['operations'];
      if (rawOps is! List) continue;

      final ops = <DebtOperation>[];
      for (final rawOp in rawOps) {
        if (rawOp is! Map) continue;
        ops.add(DebtOperation(
          kind: (rawOp['kind'] as String?) == 'payment' ? DebtOpKind.payment : DebtOpKind.charge,
          amount: _toDouble(rawOp['amount']),
          date: (rawOp['date'] as String?)?.trim() ?? '',
          balanceAfter: _toDouble(rawOp['balanceAfter']),
          comment: (rawOp['comment'] as String?)?.trim() ?? '',
        ));
      }
      result[code] = ops;
    }
    return result;
  }

  Future<void> _post(Map<String, dynamic> payload, {Duration timeout = const Duration(seconds: 20)}) async {
    final http.Response response;
    try {
      response = await http
          .post(Uri.parse(endpoint), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(timeout);
    } catch (e) {
      throw PriceSyncException('Не удалось связаться с Google Диском: $e');
    }

    if (response.statusCode != 200) {
      throw PriceSyncException('Сервер вернул ошибку ${response.statusCode}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw PriceSyncException('Не удалось разобрать ответ сервера: $e');
    }

    if (json['ok'] != true) {
      throw PriceSyncException(json['error']?.toString() ?? 'Скрипт отклонил запрос');
    }
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
