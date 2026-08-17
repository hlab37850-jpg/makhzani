import 'database_helper.dart';

class PurchaseRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<int> createPurchase({
    int? supplierId,
    required List<Map<String, dynamic>> items,
    required double paid,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('يجب إضافة منتج واحد على الأقل');
    }

    final db = await _helper.database;

    return db.transaction((txn) async {
      double total = 0;

      for (final item in items) {
        final quantity = (item['quantity'] as num).toDouble();
        final purchasePrice = (item['purchasePrice'] as num).toDouble();

        if (quantity <= 0) {
          throw ArgumentError('الكمية يجب أن تكون أكبر من صفر');
        }

        if (purchasePrice < 0) {
          throw ArgumentError('سعر الشراء غير صحيح');
        }

        total += quantity * purchasePrice;
      }

      if (paid < 0 || paid > total) {
        throw ArgumentError('المبلغ المدفوع غير صحيح');
      }

      final debt = total - paid;

      if (supplierId != null) {
        final supplier = await txn.query(
          'suppliers',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [supplierId],
          limit: 1,
        );

        if (supplier.isEmpty) {
          throw Exception('المورد غير موجود');
        }
      }

      final purchaseId = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'total': total,
        'paid': paid,
        'debt': debt,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        final productId = item['productId'] as int;
        final quantity = (item['quantity'] as num).toDouble();
        final purchasePrice =
            (item['purchasePrice'] as num).toDouble();

        final product = await txn.query(
          'products',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (product.isEmpty) {
          throw Exception('المنتج غير موجود');
        }

        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': productId,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'total': quantity * purchasePrice,
        });

        await txn.rawUpdate(
          '''
          UPDATE products
          SET quantity = quantity + ?,
              purchase_price = ?
          WHERE id = ?
          ''',
          [quantity, purchasePrice, productId],
        );
      }

      if (supplierId != null && debt > 0) {
        await txn.rawUpdate(
          '''
          UPDATE suppliers
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [debt, supplierId],
        );
      }

      return purchaseId;
    });
  }

  Future<double> todayPurchases() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS value
      FROM purchases
      WHERE date(created_at) = date('now', 'localtime')
    ''');

    return (result.first['value'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _helper.database;

    return db.rawQuery('''
      SELECT
        p.id,
        p.supplier_id,
        p.total,
        p.paid,
        p.debt,
        p.created_at,
        s.name AS supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      ORDER BY p.id DESC
    ''');
  }
}
