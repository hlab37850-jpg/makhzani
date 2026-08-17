import 'database_helper.dart';

class SalesRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<int> createSale({
    int? customerId,
    required List<Map<String, dynamic>> items,
    required double paid,
  }) async {
    final db = await _helper.database;

    return db.transaction((txn) async {
      double total = 0;
      double profit = 0;

      for (final item in items) {
        final quantity = (item['quantity'] as num).toDouble();
        final salePrice = (item['salePrice'] as num).toDouble();
        final purchasePrice = (item['purchasePrice'] as num).toDouble();

        total += quantity * salePrice;
        profit += quantity * (salePrice - purchasePrice);
      }

      final debt = total - paid;

      final saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'total': total,
        'paid': paid,
        'debt': debt < 0 ? 0 : debt,
        'profit': profit,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        final productId = item['productId'] as int;
        final quantity = (item['quantity'] as num).toDouble();
        final salePrice = (item['salePrice'] as num).toDouble();
        final purchasePrice =
            (item['purchasePrice'] as num).toDouble();

        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': productId,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'sale_price': salePrice,
          'total': quantity * salePrice,
          'profit': quantity * (salePrice - purchasePrice),
        });

        await txn.rawUpdate(
          '''
          UPDATE products
          SET quantity = quantity - ?
          WHERE id = ?
          ''',
          [quantity, productId],
        );
      }

      if (customerId != null && debt > 0) {
        await txn.rawUpdate(
          '''
          UPDATE customers
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [debt, customerId],
        );
      }

      return saleId;
    });
  }

  Future<double> todaySales() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS value
      FROM sales
      WHERE date(created_at) = date('now', 'localtime')
    ''');

    return (result.first['value'] as num?)?.toDouble() ?? 0;
  }

  Future<double> todayProfit() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(profit), 0) AS value
      FROM sales
      WHERE date(created_at) = date('now', 'localtime')
    ''');

    return (result.first['value'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalDebt() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) AS value
      FROM customers
      WHERE balance > 0
    ''');

    return (result.first['value'] as num?)?.toDouble() ?? 0;
  }
}
