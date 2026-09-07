import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import 'mock_data.dart';
import 'price_sync_service.dart';

/// Sends a placed order to the PriceSync Apps Script endpoint (`doPost` in
/// PriceSync.gs), which appends it as a row to a dedicated "Заказы (Аптека
/// Опт)" Google Sheet on the price-list owner's Drive — separate from
/// "Прайс.xlsx" itself.
///
/// This reuses the same web app URL as [PriceSyncService]: GET reads the
/// price list, POST files an order.
class OrderSyncService {
  const OrderSyncService({this.endpoint = PriceSyncService.defaultEndpoint});

  final String endpoint;

  /// Throws [PriceSyncException] on any failure — network, non-200, or the
  /// script reporting `ok: false`. Callers decide how to surface that (a
  /// toast, a DBF-state badge, ...); nothing here retries automatically.
  Future<void> submitOrder(Order order, {Duration timeout = const Duration(seconds: 20)}) async {
    final payload = {
      'number': order.number,
      'date': order.date,
      'client': order.client,
      'code': order.code,
      'region': order.region,
      'comment': order.comment,
      'total': order.total,
      'lines': order.lines
          .map((l) => {
                'code': l.productId,
                'name': MockData.findProduct(l.productId)?.name ?? l.productId,
                'quantity': l.qty,
                'price': l.price,
                'sum': l.sum,
              })
          .toList(),
    };

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } catch (e) {
      throw PriceSyncException('Не удалось отправить заказ на Google Диск: $e');
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
      throw PriceSyncException(json['error']?.toString() ?? 'Скрипт отклонил заказ');
    }
  }
}
