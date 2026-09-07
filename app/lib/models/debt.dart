/// A single ledger entry against a client's outstanding balance: either a
/// debt charged to them (goods handed over on credit) or a payment they
/// made against it (partial, or — if it brings the balance to zero — full).
enum DebtOpKind { charge, payment }

extension DebtOpKindDisplay on DebtOpKind {
  String get label => this == DebtOpKind.charge ? 'Долг' : 'Оплата';
}

/// One row in a client's debt history, as shown in the admin "Долги" tab and
/// quoted in the SMS sent to the client. Mirrors a row in the "Долги (Аптека
/// Опт)" Google Sheet kept by PriceSync.gs.
class DebtOperation {
  const DebtOperation({
    required this.kind,
    required this.amount,
    required this.date,
    required this.balanceAfter,
    this.comment = '',
  });

  final DebtOpKind kind;

  /// Always positive — the sign is implied by [kind].
  final double amount;

  /// Human-readable date/time, same free-form convention as [Order.date]
  /// (e.g. "сегодня" or "04.09.2026 10:12").
  final String date;

  /// Outstanding balance right after this operation was applied.
  final double balanceAfter;

  final String comment;

  bool get isFullSettlement => kind == DebtOpKind.payment && balanceAfter <= 0.005;
}
