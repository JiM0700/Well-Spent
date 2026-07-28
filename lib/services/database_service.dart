import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'well_spent.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // Insert default monthly budget
        await db.insert('settings', {'key': 'monthly_budget', 'value': '1000.0'});
      },
      onConfigure: (db) async {
        // Enable WAL mode for high performance & ACID safety
        await db.execute('PRAGMA journal_mode = WAL');
      },
    );
  }

  // --- EXPENSE CRUD OPERATIONS ---

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SETTINGS OPERATIONS ---

  Future<double> getMonthlyBudget() async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: ['monthly_budget']);
    if (res.isNotEmpty) {
      return double.tryParse(res.first['value'] as String) ?? 1000.0;
    }
    return 1000.0;
  }

  Future<void> setMonthlyBudget(double budget) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'monthly_budget', 'value': budget.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
