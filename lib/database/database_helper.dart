import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';
import '../models/user.dart';
import '../models/shift.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTransactionTables(db);
    }
    if (oldVersion < 3) {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tables'",
      );
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE tables (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'kosong'
          )
        ''');
      }
    }
    if (oldVersion < 4) {
      await _createUserTables(db);
    }
    if (oldVersion < 5) {
      final columns = await db.rawQuery("PRAGMA table_info(transactions)");
      final hasUserId = columns.any((c) => c['name'] == 'user_id');
      if (!hasUserId) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN user_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN user_name TEXT',
        );
      }
    }
    if (oldVersion < 6) {
      // Migrate users table: pin -> email, password
      final userColumns = await db.rawQuery("PRAGMA table_info(users)");
      final hasEmail = userColumns.any((c) => c['name'] == 'email');
      if (!hasEmail) {
        await db.execute(
          'ALTER TABLE users ADD COLUMN email TEXT',
        );
        await db.execute(
          'ALTER TABLE users ADD COLUMN password TEXT',
        );
      }
      // Add customer_name to transactions
      final txColumns = await db.rawQuery("PRAGMA table_info(transactions)");
      final hasCustomerName = txColumns.any((c) => c['name'] == 'customer_name');
      if (!hasCustomerName) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN customer_name TEXT',
        );
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE menu_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      category TEXT NOT NULL
    )
  ''');
    await db.execute('''
    CREATE TABLE tables (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'kosong'
    )
  ''');
    await _createTransactionTables(db);
    await _createUserTables(db);
  }

  Future _createTransactionTables(Database db) async {
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total REAL NOT NULL,
      created_at TEXT NOT NULL,
      user_id INTEGER,
      user_name TEXT,
      customer_name TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE transaction_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      menu_item_id INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      item_price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id)
    )
  ''');
  }

  Future _createUserTables(Database db) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'kasir',
      created_at TEXT NOT NULL
    )
  ''');
    await db.execute('''
    CREATE TABLE shifts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      user_name TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT,
      total_sales REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  ''');
  }

  // === MENU ITEMS ===
  Future<int> insertMenuItem(MenuItem item) async {
    final db = await instance.database;
    return await db.insert('menu_items', item.toMap());
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await instance.database;
    final result = await db.query('menu_items');
    return result.map((map) => MenuItem.fromMap(map)).toList();
  }

  Future<int> updateMenuItem(MenuItem item) async {
    final db = await instance.database;
    return await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMenuItem(int id) async {
    final db = await instance.database;
    return await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }

  // === TRANSACTIONS ===
  Future<int> checkout(
    double total,
    List<Map<String, dynamic>> items, {
    int? tableId,
    String? tableName,
    int? userId,
    String? userName,
    String? customerName,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final transactionId = await txn.insert('transactions', {
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'user_name': userName,
        'customer_name': customerName,
      });

      for (final item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'menu_item_id': item['menu_item_id'],
          'item_name': item['item_name'],
          'item_price': item['item_price'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
        });
      }

      // Update total sales di shift aktif user
      if (userId != null) {
        await txn.rawUpdate('''
          UPDATE shifts SET total_sales = total_sales + ?
          WHERE user_id = ? AND end_time IS NULL
        ''', [total, userId]);
      }

      return transactionId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(
    int transactionId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<double> getTodayTotal() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(total) as sum_total FROM transactions WHERE created_at >= ?',
      [startOfDay],
    );

    final sum = result.first['sum_total'];
    return sum == null ? 0.0 : (sum as num).toDouble();
  }

  // === FINANCIAL REPORTS ===
  Future<Map<String, dynamic>> getReport({
    required DateTime startDate,
    required DateTime endDate,
    int? userId,
  }) async {
    final db = await instance.database;
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();

    String whereClause = 'created_at >= ? AND created_at <= ?';
    List<dynamic> whereArgs = [start, end];

    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    // Total penjualan
    final totalResult = await db.rawQuery(
      'SELECT SUM(total) as total, COUNT(*) as count FROM transactions WHERE $whereClause',
      whereArgs,
    );

    // Rincian per kasir
    final byUserResult = await db.rawQuery('''
      SELECT user_name, SUM(total) as total, COUNT(*) as count
      FROM transactions
      WHERE $whereClause AND user_id IS NOT NULL
      GROUP BY user_id
      ORDER BY total DESC
    ''', whereArgs);

    // Rincian per tanggal
    final byDateResult = await db.rawQuery('''
      SELECT DATE(created_at) as date, SUM(total) as total, COUNT(*) as count
      FROM transactions
      WHERE $whereClause
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    ''', whereArgs);

    // Item terlaris
    final topItemsResult = await db.rawQuery('''
      SELECT item_name, SUM(quantity) as total_qty, SUM(subtotal) as total
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE $whereClause
      GROUP BY item_name
      ORDER BY total_qty DESC
      LIMIT 10
    ''', whereArgs);

    final total = (totalResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final count = (totalResult.first['count'] as int?) ?? 0;

    return {
      'total_sales': total,
      'transaction_count': count,
      'average_per_transaction': count > 0 ? total / count : 0.0,
      'by_user': byUserResult,
      'by_date': byDateResult,
      'top_items': topItemsResult,
    };
  }

  // === TABLE MANAGEMENT ===
  Future<int> insertTable(String name) async {
    final db = await instance.database;
    return await db.insert('tables', {'name': name, 'status': 'kosong'});
  }

  Future<List<Map<String, dynamic>>> getAllTables() async {
    final db = await instance.database;
    return await db.query('tables', orderBy: 'id ASC');
  }

  Future<int> updateTableStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'tables',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTable(int id) async {
    final db = await instance.database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  // === USER MANAGEMENT ===
  Future<int> insertUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserByEmailPassword(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getUserCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return (result.first['count'] as int?) ?? 0;
  }

  // === SHIFT MANAGEMENT ===
  Future<int> startShift(int userId, String userName) async {
    final db = await instance.database;

    // Cek apakah sudah ada shift aktif
    final activeShift = await db.query(
      'shifts',
      where: 'user_id = ? AND end_time IS NULL',
      whereArgs: [userId],
      limit: 1,
    );

    if (activeShift.isNotEmpty) {
      return activeShift.first['id'] as int;
    }

    return await db.insert('shifts', {
      'user_id': userId,
      'user_name': userName,
      'start_time': DateTime.now().toIso8601String(),
      'total_sales': 0.0,
    });
  }

  Future<void> endShift(int userId) async {
    final db = await instance.database;
    await db.update(
      'shifts',
      {'end_time': DateTime.now().toIso8601String()},
      where: 'user_id = ? AND end_time IS NULL',
      whereArgs: [userId],
    );
  }

  Future<Shift?> getActiveShift(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'shifts',
      where: 'user_id = ? AND end_time IS NULL',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Shift.fromMap(result.first);
  }

  Future<List<Shift>> getShiftHistory({int limit = 30}) async {
    final db = await instance.database;
    final result = await db.query(
      'shifts',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return result.map((map) => Shift.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getTodaySalesByUser() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery('''
      SELECT user_name, SUM(total) as total, COUNT(*) as count
      FROM transactions
      WHERE created_at >= ? AND user_id IS NOT NULL
      GROUP BY user_id
      ORDER BY total DESC
    ''', [startOfDay]);

    return {'today_sales': result};
  }
}
