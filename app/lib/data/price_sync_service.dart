import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Result of a successful price-list fetch from the Google Apps Script
/// endpoint (see PriceSync.gs) — the products themselves plus the
/// timestamps the endpoint reports, for the "Прайс обновлён ..." UI.
class PriceSyncResult {
  const PriceSyncResult({
    required this.items,
    required this.fetchedAt,
    this.sourceModifiedAt,
  });

  final List<Product> items;

  /// When this device fetched the data (local clock).
  final DateTime fetchedAt;

  /// When the Google Drive price-list file itself last changed, as reported
  /// by the sync script — null if the endpoint didn't send one.
  final DateTime? sourceModifiedAt;
}

/// Fetches the live price list published by the PriceSync Google Apps
/// Script web app, which mirrors the "Прайс.xlsx" file kept on Google
/// Drive (see `PriceSync.gs` at the repo root for the script itself).
class PriceSyncService {
  const PriceSyncService({this.endpoint = defaultEndpoint});

  /// Deployed Apps Script web app URL ("Execute as: Me", "Who has access:
  /// Anyone"). Replacing the Google Drive file (whole-file re-upload or
  /// in-place cell edits) is picked up by the script's own 10-minute
  /// polling trigger — this client just reads whatever it last cached.
  static const String defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbz0cOUloNj03VjL9uB2tT0iQTDI-DyDwKaloXnDVmkzW6aGfJswWdD61RFl-xCrdZGK/exec';

  final String endpoint;

  Future<PriceSyncResult> fetchPriceList({Duration timeout = const Duration(seconds: 20)}) async {
    final http.Response response;
    try {
      response = await http.get(Uri.parse(endpoint)).timeout(timeout);
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

    final rawItems = json['items'];
    if (rawItems is! List) {
      throw PriceSyncException('В ответе сервера нет списка товаров');
    }

    final items = <Product>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final product = _productFromJson(raw);
      if (product != null) items.add(product);
    }

    return PriceSyncResult(
      items: items,
      fetchedAt: DateTime.now(),
      sourceModifiedAt: _tryParseDate(json['sourceModifiedAt']),
    );
  }

  Product? _productFromJson(Map raw) {
    final name = (raw['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    return Product(
      id: (raw['id'] as String?)?.trim() ?? '',
      name: name,
      producer: (raw['producer'] as String?)?.trim() ?? '',
      period: (raw['period'] as String?)?.trim() ?? '',
      basePrice: _toDouble(raw['basePrice']),
      stock: _toInt(raw['stock']),
      minOrder: _toInt(raw['minOrder'], fallback: 1),
      barcode: (raw['barcode'] as String?)?.trim() ?? '',
      marking: (raw['marking'] as String?)?.trim() ?? '',
    );
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  DateTime? _tryParseDate(dynamic v) {
    if (v is! String) return null;
    return DateTime.tryParse(v);
  }
}

class PriceSyncException implements Exception {
  PriceSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}
