/// A registered pharmacy, keyed by its delivery code.
class Client {
  const Client({
    required this.code,
    required this.name,
    required this.region,
    required this.discount,
  });

  /// Delivery code, e.g. "190172-04" — also the login key.
  final String code;
  final String name;
  final String region;

  /// Personal discount in percent, negative = discount (e.g. -2), 0 = none.
  final int discount;

  /// Client id is the part of the delivery code before the dash.
  String get clientCode => code.split('-').first;
}
