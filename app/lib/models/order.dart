import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Status of the DBF export that mirrors each order into the supplier's
/// Google Drive folder.
enum DbfState { none, queue, ok }

extension DbfStateDisplay on DbfState {
  String get label => switch (this) {
        DbfState.ok => 'DBF на Диске',
        DbfState.queue => 'DBF в очереди',
        DbfState.none => 'DBF не сформирован',
      };

  Color get fg => switch (this) {
        DbfState.ok => AppColors.accent,
        DbfState.queue => AppColors.warnFg,
        DbfState.none => AppColors.dangerFg,
      };

  Color get bg => switch (this) {
        DbfState.ok => AppColors.accentSoftBg,
        DbfState.queue => AppColors.warnBg,
        DbfState.none => AppColors.dangerBg,
      };
}

/// Lifecycle status of a submitted order.
enum OrderStatus { placed, assembling, paid, delivered }

extension OrderStatusDisplay on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Принят',
        OrderStatus.assembling => 'В сборке',
        OrderStatus.paid => 'Оплачен',
        OrderStatus.delivered => 'Доставлен',
      };

  Color get fg => this == OrderStatus.placed ? AppColors.warnFg : this == OrderStatus.assembling ? AppColors.accent : AppColors.textMuted;

  Color get bg => this == OrderStatus.placed ? AppColors.warnBg : this == OrderStatus.assembling ? AppColors.accentSoftBg : AppColors.chipBg;
}

/// One product line inside an order — quantity times the unit price the
/// client actually paid (discount already applied, rounded to the ruble).
class OrderLine {
  const OrderLine({required this.productId, required this.qty, required this.price});

  final String productId;
  final int qty;
  final double price;

  double get sum => qty * price;
}

class Order {
  const Order({
    required this.number,
    required this.date,
    required this.client,
    required this.code,
    required this.region,
    required this.status,
    required this.comment,
    required this.dbf,
    required this.lines,
  });

  /// Order number, e.g. "Z2418760431".
  final String number;

  /// Human-readable date/time, as it appears on the order card.
  final String date;
  final String client;
  final String code;
  final String region;
  final OrderStatus status;
  final String comment;
  final DbfState dbf;
  final List<OrderLine> lines;

  bool get hasComment => comment.isNotEmpty;
  int get packs => lines.fold(0, (s, l) => s + l.qty);
  double get total => lines.fold(0, (s, l) => s + l.sum);
  int get positions => lines.length;

  String get dbfFile => '$number.dbf';
  String get dbfFolder => 'Google Диск / Заказы / $region';

  Order copyWith({OrderStatus? status, DbfState? dbf}) => Order(
        number: number,
        date: date,
        client: client,
        code: code,
        region: region,
        status: status ?? this.status,
        comment: comment,
        dbf: dbf ?? this.dbf,
        lines: lines,
      );
}
