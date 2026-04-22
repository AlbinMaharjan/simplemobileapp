// lib/services/db_service.dart
//
// Uses sqflite to store products locally on the device.
// Provides full CRUD operations.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DbService {
  static Database? _db;

  // Singleton pattern — only one DB instance
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'products.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            imageUrl TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');

        // Seed with some demo products so the app isn't empty on first launch
        await db.insert('products', {
          'title': 'Wireless Headphones',
          'description': 'Premium sound quality with noise cancellation.',
          'price': 49.99,
          'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
          'category': 'Electronics',
        });
        await db.insert('products', {
          'title': 'Running Shoes',
          'description': 'Lightweight shoes perfect for daily runs.',
          'price': 89.99,
          'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
          'category': 'Sports',
        });
        await db.insert('products', {
          'title': 'Coffee Mug',
          'description': 'Ceramic mug that keeps drinks hot for hours.',
          'price': 14.99,
          'imageUrl': 'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=400',
          'category': 'Kitchen',
        });
      },
    );
  }

  // CREATE
  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  // READ ALL
  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'id DESC');
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  // READ ONE
  Future<ProductModel?> getProduct(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  // UPDATE
  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // DELETE
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
