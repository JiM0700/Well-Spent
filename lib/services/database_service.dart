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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            type TEXT NOT NULL,
            expenseKind TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await db.insert('settings', {'key': 'monthly_budget', 'value': '1000.0'});
        await db.insert('settings', {'key': 'cycle_start_day', 'value': '1'});
        await db.insert('settings', {'key': 'base_monthly_income', 'value': '0.0'});
        await db.insert('settings', {'key': 'pay_day', 'value': '1'});
        await db.insert('settings', {'key': 'summary_enabled', 'value': 'true'});
        await db.insert('settings', {'key': 'summary_period', 'value': 'daily'});
        await db.insert('settings', {'key': 'view_mode', 'value': 'monthly'});
        await db.insert('settings', {'key': 'chart_mode', 'value': 'daywise'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT "expense"');
          await db.execute('ALTER TABLE expenses ADD COLUMN expenseKind TEXT NOT NULL DEFAULT "variable"');
          await db.insert('settings', {'key': 'cycle_start_day', 'value': '1'});
          await db.insert('settings', {'key': 'base_monthly_income', 'value': '0.0'});
          await db.insert('settings', {'key': 'pay_day', 'value': '1'});
          await db.insert('settings', {'key': 'summary_enabled', 'value': 'true'});
          await db.insert('settings', {'key': 'summary_period', 'value': 'daily'});
          await db.insert('settings', {'key': 'view_mode', 'value': 'monthly'});
          await db.insert('settings', {'key': 'chart_mode', 'value': 'daywise'});
        }
      },
      onConfigure: (db) async {
        try {
          await db.execute('PRAGMA journal_mode = WAL');
        } catch (_) {
          // Some macOS sqlite builds do not allow WAL; continue without it.
        }
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

  Future<void> replaceAllExpenses(List<Expense> expenses) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      for (final expense in expenses) {
        final values = Map<String, dynamic>.from(expense.toMap())..remove('id');
        await txn.insert('expenses', values);
      }
    });
  }

  // --- SETTINGS OPERATIONS ---

  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getDoubleSetting(String key, double defaultValue) async {
    final raw = await getSetting(key);
    return raw == null ? defaultValue : double.tryParse(raw) ?? defaultValue;
  }

  Future<int> getIntSetting(String key, int defaultValue) async {
    final raw = await getSetting(key);
    return raw == null ? defaultValue : int.tryParse(raw) ?? defaultValue;
  }

  Future<bool> getBoolSetting(String key, bool defaultValue) async {
    final raw = await getSetting(key);
    if (raw == null) return defaultValue;
    return raw.toLowerCase() == 'true';
  }

  Future<double> getMonthlyBudget() async {
    return getDoubleSetting('monthly_budget', 1000.0);
  }

  Future<void> setMonthlyBudget(double budget) async {
    await setSetting('monthly_budget', budget.toString());
  }

  Future<int> getCycleStartDay() async {
    return getIntSetting('cycle_start_day', 1);
  }

  Future<void> setCycleStartDay(int day) async {
    await setSetting('cycle_start_day', day.toString());
  }

  Future<double> getBaseMonthlyIncome() async {
    return getDoubleSetting('base_monthly_income', 0.0);
  }

  Future<void> setBaseMonthlyIncome(double income) async {
    await setSetting('base_monthly_income', income.toString());
  }

  Future<int> getPayDay() async {
    return getIntSetting('pay_day', 1);
  }

  Future<void> setPayDay(int day) async {
    await setSetting('pay_day', day.toString());
  }

  Future<bool> getSummaryEnabled() async {
    return getBoolSetting('summary_enabled', true);
  }

  Future<void> setSummaryEnabled(bool enabled) async {
    await setSetting('summary_enabled', enabled.toString());
  }

  Future<String> getSummaryPeriod() async {
    final raw = await getSetting('summary_period');
    if (raw == 'daily' || raw == 'weekly' || raw == 'monthly') return raw!;
    return 'daily';
  }

  Future<void> setSummaryPeriod(String period) async {
    await setSetting('summary_period', period);
  }

  Future<String> getViewMode() async {
    final raw = await getSetting('view_mode');
    if (raw == 'weekly' || raw == 'monthly' || raw == 'yearly') return raw!;
    return 'monthly';
  }

  Future<void> setViewMode(String mode) async {
    await setSetting('view_mode', mode);
  }

  Future<String> getChartMode() async {
    final raw = await getSetting('chart_mode');
    if (raw == 'daywise' || raw == 'monthwise') return raw!;
    return 'daywise';
  }

  Future<void> setChartMode(String mode) async {
    await setSetting('chart_mode', mode);
  }
}
