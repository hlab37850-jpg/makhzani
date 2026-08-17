import 'database_helper.dart';

class SupplierRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _helper.database;

    return db.query(
      'suppliers',
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await _helper.database;

    return db.query(
      'suppliers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<int> insert({
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final db = await _helper.database;

    return db.insert('suppliers', {
      'name': name,
      'phone': phone,
      'address': address,
      'balance': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> update({
    required int id,
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final db = await _helper.database;

    return db.update(
      'suppliers',
      {
        'name': name,
        'phone': phone,
        'address': address,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _helper.database;

    final purchases = await db.query(
      'purchases',
      columns: ['id'],
      where: 'supplier_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (purchases.isNotEmpty) {
      throw Exception(
        'لا يمكن حذف مورد لديه عمليات شراء مسجلة',
      );
    }

    return db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> totalDebt() async {
    final db = await _helper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) AS value
      FROM suppliers
      WHERE balance > 0
    ''');

    return (result.first['value'] as num?)?.toDouble() ?? 0;
  }

  Future<int> addPayment({
    required int supplierId,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'مبلغ السداد يجب أن يكون أكبر من صفر',
      );
    }

    final db = await _helper.database;

    return db.transaction((txn) async {
      final rows = await txn.query(
        'suppliers',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [supplierId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('المورد غير موجود');
      }

      final balance =
          (rows.first['balance'] as num?)?.toDouble() ?? 0;

      if (amount > balance) {
        throw Exception(
          'مبلغ السداد أكبر من المستحق الحالي',
        );
      }

      final paymentId = await txn.insert(
        'supplier_payments',
        {
          'supplier_id': supplierId,
          'amount': amount,
          'note': note,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      await txn.update(
        'suppliers',
        {
          'balance': balance - amount,
        },
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      return paymentId;
    });
  }

  Future<List<Map<String, dynamic>>> getPayments(
    int supplierId,
  ) async {
    final db = await _helper.database;

    return db.query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'id DESC',
    );
  }
}
