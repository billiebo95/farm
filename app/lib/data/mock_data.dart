import '../models/client.dart';
import '../models/debt.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Static seed data standing in for the real backend (Google Drive price
/// sync, client registry, order history) until that integration lands.
/// Mirrors PRICE / CLIENTS / BASE_ORDERS in Аптека Опт v2.dc.html.
class MockData {
  MockData._();

  static const companyName = 'ООО «Шах»';
  static const supplierPassword = '5727';
  static const regions = ['Чечня', 'Дагестан'];
  static const catalogFilters = ['Все', 'В заказе', 'Заканчивается', 'Маркировка ЧЗ', 'В наличии'];

  /// Seed/fallback data, shown until the first live sync completes (or if it
  /// fails). [AppState.syncPrice] replaces this list wholesale with whatever
  /// PriceSync.gs currently has cached from "Прайс.xlsx".
  static List<Product> priceList = <Product>[
    Product(
      id: '10412',
      name: 'Амоксиклав табл. 875 мг + 125 мг №14',
      producer: 'Lek d.d., Словения',
      period: '09.2027',
      basePrice: 412,
      stock: 340,
      minOrder: 10,
      barcode: '4602509012345',
      marking: 'ЧЗ',
    ),
    Product(
      id: '10096',
      name: 'Ибупрофен табл. 400 мг №20',
      producer: 'Синтез, Курган',
      period: '04.2028',
      basePrice: 96,
      stock: 1280,
      minOrder: 20,
      barcode: '4600123008812',
      marking: '',
    ),
    Product(
      id: '10187',
      name: 'Лозартан табл. 50 мг №30',
      producer: 'Канонфарма, Россия',
      period: '11.2026',
      basePrice: 187,
      stock: 74,
      minOrder: 10,
      barcode: '4602841004417',
      marking: 'ЧЗ',
    ),
    Product(
      id: '10118',
      name: 'Омепразол капс. 20 мг №30',
      producer: 'Озон, Жигулёвск',
      period: '02.2028',
      basePrice: 118,
      stock: 610,
      minOrder: 20,
      barcode: '4602884001129',
      marking: '',
    ),
    Product(
      id: '10054',
      name: 'Цефтриаксон пор. д/ин. 1 г',
      producer: 'Биохимик, Саранск',
      period: '07.2027',
      basePrice: 54,
      stock: 2400,
      minOrder: 50,
      barcode: '4602676009003',
      marking: 'ЧЗ',
    ),
    Product(
      id: '10143',
      name: 'Аскорбиновая кислота шип. табл. 500 мг №20',
      producer: 'Ozon Life, Россия',
      period: '12.2027',
      basePrice: 143,
      stock: 480,
      minOrder: 12,
      barcode: '4602841117025',
      marking: '',
    ),
    Product(
      id: '10268',
      name: 'Нурофен для детей сусп. 100 мг/5 мл 100 мл',
      producer: 'Reckitt, Великобритания',
      period: '06.2027',
      basePrice: 268,
      stock: 38,
      minOrder: 6,
      barcode: '5000158104402',
      marking: 'ЧЗ',
    ),
    Product(
      id: '10154',
      name: 'Бисопролол табл. 5 мг №50',
      producer: 'Вертекс, Санкт-Петербург',
      period: '08.2027',
      basePrice: 154,
      stock: 0,
      minOrder: 10,
      barcode: '4602509887311',
      marking: 'ЧЗ',
    ),
    Product(
      id: '10211',
      name: 'Смекта пор. 3 г №10',
      producer: 'Beaufour Ipsen, Франция',
      period: '03.2029',
      basePrice: 211,
      stock: 156,
      minOrder: 10,
      barcode: '3282770024234',
      marking: '',
    ),
    Product(
      id: '10041',
      name: 'Парацетамол табл. 500 мг №20',
      producer: 'Фармстандарт, Уфа',
      period: '05.2028',
      basePrice: 41,
      stock: 3100,
      minOrder: 40,
      barcode: '4602191002286',
      marking: '',
    ),
  ];

  /// Registered pharmacies. Mutable — [AppState.finishRegistration] appends
  /// newly self-registered pharmacies here, so [findClient]/[AppState.isRegistered]
  /// recognize their delivery code on future logins.
  static List<Client> clients = <Client>[
    Client(code: '190455-01', name: 'Аптека «Мед-Лайн»', region: 'Дагестан', discount: -4, phone: '+7 928 000-00-01'),
    Client(code: '190780-02', name: 'Аптека «Здоровье»', region: 'Чечня', discount: 0, phone: '+7 928 000-00-02'),
  ];

  /// Seed debt ledger, keyed by delivery code — one client already owes part
  /// of a shipment taken on credit, so the "Долги" admin tab has something to
  /// look at before any real operation gets recorded. [AppState.syncDebts]
  /// replaces this wholesale with whatever PriceSync.gs currently has in its
  /// "Долги (Аптека Опт)" sheet, same as the price list.
  static final Map<String, List<DebtOperation>> debtOps = {
    '190455-01': [
      DebtOperation(kind: DebtOpKind.charge, amount: 18000, date: '28.08.2026', balanceAfter: 18000, comment: 'Отгрузка в долг'),
      DebtOperation(kind: DebtOpKind.payment, amount: 8000, date: '02.09.2026', balanceAfter: 10000, comment: 'Частичная оплата'),
    ],
  };

  static final baseOrders = <Order>[
    Order(
      number: 'Z2418760431',
      date: '04.09.2026 10:12',
      client: 'Аптека «Мед-Лайн»',
      code: '190455-01',
      region: 'Дагестан',
      status: OrderStatus.assembling,
      comment: 'Привезти до 12:00, звонить Ирине',
      dbf: DbfState.ok,
      lines: const [
        OrderLine(productId: '10412', qty: 60, price: 391),
        OrderLine(productId: '10118', qty: 40, price: 112),
        OrderLine(productId: '10041', qty: 120, price: 39),
      ],
    ),
    Order(
      number: 'Z2418093117',
      date: '28.08.2026 09:40',
      client: 'Аптека «Мед-Лайн»',
      code: '190455-01',
      region: 'Дагестан',
      status: OrderStatus.delivered,
      comment: '',
      dbf: DbfState.ok,
      lines: const [
        OrderLine(productId: '10041', qty: 80, price: 39),
        OrderLine(productId: '10096', qty: 40, price: 91),
      ],
    ),
    Order(
      number: 'Z2417455028',
      date: '19.08.2026 16:05',
      client: 'Аптека «Мед-Лайн»',
      code: '190455-01',
      region: 'Дагестан',
      status: OrderStatus.paid,
      comment: 'Отгрузить одной машиной',
      dbf: DbfState.ok,
      lines: const [
        OrderLine(productId: '10054', qty: 200, price: 50),
      ],
    ),
  ];

  static Product? findProduct(String id) {
    for (final p in priceList) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Client? findClient(String code) {
    for (final c in clients) {
      if (c.code == code) return c;
    }
    return null;
  }
}
