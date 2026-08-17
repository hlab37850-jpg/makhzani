import 'database_helper.dart';

class ReportRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Map<String, double>> summary() async {
    final db = await _helper.database;

    final sales = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS total,
        COALESCE(SUM(paid), 0) AS paid,
        COALESCE(SUM(debt), 0) AS debt,
        COALESCE(SUM(profit), 0) AS profit
      FROM sales
    ''');

    final purchases = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS total,
        COALESCE(SUM(paid), 0) AS paid,
        COALESCE(SUM(debt), 0) AS debt
      FROM purchases
    ''');

    final stock = await db.rawQuery('''
      SELECT
        COUNT(*) AS products,
        COALESCE(
          SUM(quantity * purchase_price),
          0
        ) AS stock_value,
        COALESCE(
          SUM(
            CASE
              WHEN quantity <= min_quantity THEN 1
              ELSE 0
            END
          ),
          0
        ) AS low_stock
      FROM products
    ''');

    final customerDebt = await db.rawQuery('''
      SELECT
        COALESCE(SUM(balance), 0) AS value
      FROM customers
      WHERE balance > 0
    ''');

    final supplierDebt = await db.rawQuery('''
      SELECT
        COALESCE(SUM(balance), 0) AS value
      FROM suppliers
      WHERE balance > 0
    ''');

    double value(
      List<Map<String, Object?>> rows,
      String key,
    ) {
      return (rows.first[key] as num?)?.toDouble() ?? 0;
    }

    return {
      'sales': value(sales, 'total'),
      'salesPaid': value(sales, 'paid'),

      // إجمالي الديون التاريخية للفواتير.
      'salesDebt': value(sales, 'debt'),

      // الرصيد الحالي الفعلي للعملاء.
      'customerDebt': value(customerDebt, 'value'),

      'profit': value(sales, 'profit'),

      'purchases': value(purchases, 'total'),
      'purchasesPaid': value(purchases, 'paid'),
      'purchaseDebt': value(purchases, 'debt'),

      // الرصيد الحالي الفعلي للموردين.
      'supplierDebt': value(supplierDebt, 'value'),

      'products': value(stock, 'products'),
      'stockValue': value(stock, 'stock_value'),
      'lowStock': value(stock, 'low_stock'),
    };
  }

  Future<List<Map<String, dynamic>>> recentSales() async {
    final db = await _helper.database;

    return db.rawQuery('''
      SELECT
        s.id,
        s.total,
        s.paid,
        s.debt,
        s.profit,
        s.created_at,
        c.name AS customer_name
      FROM sales s
      LEFT JOIN customers c
        ON c.id = s.customer_id
      ORDER BY s.id DESC
      LIMIT 20
    ''');
  }

  Future<List<Map<String, dynamic>>> recentPurchases() async {
    final db = await _helper.database;

    return db.rawQuery('''
      SELECT
        p.id,
        p.total,
        p.paid,
        p.debt,
        p.created_at,
        s.name AS supplier_name
      FROM purchases p
      LEFT JOIN suppliers s
        ON s.id = p.supplier_id
      ORDER BY p.id DESC
      LIMIT 20
    ''');
  }
}
