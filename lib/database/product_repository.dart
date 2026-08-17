import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import 'database_helper.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Product product) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'products',
      product.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getAll() async {
    final db = await _databaseHelper.database;

    final rows = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> search(String query) async {
    final db = await _databaseHelper.database;

    final rows = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return rows.map(Product.fromMap).toList();
  }

  Future<int> update(Product product) async {
    if (product.id == null) {
      throw ArgumentError('لا يمكن تعديل منتج بدون رقم تعريف');
    }

    final db = await _databaseHelper.database;

    return db.update(
      'products',
      product.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> count() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> lowStockCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM products
      WHERE quantity <= min_quantity
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
