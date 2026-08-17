import 'database_helper.dart';

class CustomerRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _helper.database;
    return db.query(
      'customers',
      orderBy: 'name ASC',
    );
  }

  Future<int> insert({
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final db = await _helper.database;

    return db.insert('customers', {
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
      'customers',
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

    return db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await _helper.database;

    return db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<int> addPayment({
    required int customerId,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) {
      throw ArgumentError('مبلغ السداد يجب أن يكون أكبر من صفر');
    }

    final db = await _helper.database;

    return db.transaction((txn) async {
      final customerRows = await txn.query(
        'customers',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );

      if (customerRows.isEmpty) {
        throw Exception('العميل غير موجود');
      }

      final balance =
          (customerRows.first['balance'] as num?)?.toDouble() ?? 0;

      if (amount > balance) {
        throw Exception('مبلغ السداد أكبر من الدين الحالي');
      }

      final paymentId = await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.update(
        'customers',
        {
          'balance': balance - amount,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      return paymentId;
    });
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
