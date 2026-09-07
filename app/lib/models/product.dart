/// A single price-list entry (a packaged medicine SKU).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.producer,
    required this.period,
    required this.basePrice,
    required this.stock,
    required this.minOrder,
    required this.barcode,
    required this.marking,
  });

  /// Internal product code (also what the price list calls "код").
  final String id;
  final String name;
  final String producer;

  /// Expiry, formatted like the price list ("09.2027").
  final String period;

  /// Price-list base price, before any discount/markup.
  final double basePrice;

  /// Packs in stock.
  final int stock;

  /// Packaging multiple — the step used by "+ pack".
  final int minOrder;
  final String barcode;

  /// "ЧЗ" (Честный Знак) marking requirement, empty string if none.
  final String marking;

  bool get requiresMarking => marking.isNotEmpty;
  bool get outOfStock => stock == 0;
  bool get lowStock => stock > 0 && stock < 100;
}
