import 'database_helper.dart';

class SalesRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<int> createSale({
    int? customerId,
    required List<Map<String, dynamic>> items,
    required double paid,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('يجب إضافة منتج واحد على الأقل');
    }

    if (paid < 0) {
      throw ArgumentError('المبلغ المدفوع غير صحيح');
    }

    final db = await _helper.database;

    return db.transaction((txn) async {
      double total = 0;
      double profit = 0;

      final preparedItems = <Map<String, dynamic>>[];

      for (final item in items) {
        final productId = item['productId'] as int;
        final quantity =
            (item['quantity'] as num).toDouble();

        if (quantity <= 0) {
          throw ArgumentError(
            'الكمية يجب أن تكون أكبر من صفر',
          );
        }

        final productRows = await txn.query(
          'products',
          columns: [
            'id',
            'quantity',
            'purchase_price',
            'sale_price',
          ],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (productRows.isEmpty) {
          throw Exception('المنتج غير موجود');
        }

        final product = productRows.first;

        final stock =
            (product['quantity'] as num?)
                    ?.toDouble() ??
                0;

        final purchasePrice =
            (product['purchase_price'] as num?)
                    ?.toDouble() ??
                0;

        final salePrice =
            (product['sale_price'] as num?)
                    ?.toDouble() ??
                0;

        if (quantity > stock) {
          throw Exception(
            'المخزون غير كافٍ للمنتج رقم $productId',
          );
        }

        if (purchasePrice < 0 || salePrice < 0) {
          throw Exception('سعر المنتج غير صحيح');
        }

        final itemTotal = quantity * salePrice;
        final itemProfit =
            quantity * (salePrice - purchasePrice);

        total += itemTotal;
        profit += itemProfit;

        preparedItems.add({
          'productId': productId,
          'quantity': quantity,
          'purchasePrice': purchasePrice,
          'salePrice': salePrice,
          'total': itemTotal,
          'profit': itemProfit,
        });
      }

      if (paid > total) {
        throw ArgumentError(
          'المبلغ المدفوع أكبر من إجمالي الفاتورة',
        );
      }

      final debt = total - paid;

      if (debt > 0 && customerId == null) {
        throw Exception(
          'يجب اختيار عميل عند وجود مبلغ متبقي',
        );
      }

      if (customerId != null) {
        final customer = await txn.query(
          'customers',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );

        if (customer.isEmpty) {
          throw Exception('العميل غير موجود');
        }
      }

      final saleId = await txn.insert(
        'sales',
        {
          'customer_id': customerId,
          'total': total,
          'paid': paid,
          'debt': debt,
          'profit': profit,
          'created_at':
              DateTime.now().toIso8601String(),
        },
      );

      for (final item in preparedItems) {
        final productId =
            item['productId'] as int;
        final quantity =
            item['quantity'] as double;
        final purchasePrice =
            item['purchasePrice'] as double;
        final salePrice =
            item['salePrice'] as double;
        final itemTotal =
            item['total'] as double;
        final itemProfit =
            item['profit'] as double;

        await txn.insert(
          'sale_items',
          {
            'sale_id': saleId,
            'product_id': productId,
            'quantity': quantity,
            'purchase_price': purchasePrice,
            'sale_price': salePrice,
            'total': itemTotal,
            'profit': itemProfit,
          },
        );

        final updated = await txn.rawUpdate(
          '''
          UPDATE products
          SET quantity = quantity - ?
          WHERE id = ?
            AND quantity >= ?
          ''',
          [
            quantity,
            productId,
            quantity,
          ],
        );

        if (updated == 0) {
          throw Exception(
            'تعذر تحديث مخزون المنتج',
          );
        }
      }

      if (customerId != null && debt > 0) {
        final updatedCustomer =
            await txn.rawUpdate(
          '''
          UPDATE customers
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [
            debt,
            customerId,
          ],
        );

        if (updatedCustomer == 0) {
          throw Exception(
            'تعذر تحديث دين العميل',
          );
        }
      }

      return saleId;
    });
  }

  Future<double> todaySales() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS value
      FROM sales
      WHERE date(created_at) =
            date('now', 'localtime')
    ''');

    return (result.first['value'] as num?)
            ?.toDouble() ??
        0;
  }

  Future<double> todayProfit() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(profit), 0) AS value
      FROM sales
      WHERE date(created_at) =
            date('now', 'localtime')
    ''');

    return (result.first['value'] as num?)
            ?.toDouble() ??
        0;
  }

  Future<double> totalDebt() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) AS value
      FROM customers
      WHERE balance > 0
    ''');

    return (result.first['value'] as num?)
            ?.toDouble() ??
        0;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _helper.database;

    return db.rawQuery('''
      SELECT
        s.id,
        s.customer_id,
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
    ''');
  }
}
