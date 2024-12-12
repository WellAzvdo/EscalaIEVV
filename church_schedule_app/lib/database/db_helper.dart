import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._() {
    sqfliteFfiInit(); // Inicializa suporte FFI
    databaseFactory = databaseFactoryFfi; // Configura o factory global
  }

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFactory = databaseFactoryFfi; // Certifique-se que o factory está configurado
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/church_schedule.db';

    return await dbFactory.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE departments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    ));
  }

  static Future<List<Map<String, dynamic>>> getDepartments() async {
    final db = await DBHelper().database;
    return await db.query('departments');
  }

  static Future<void> insertDepartment(String name) async {
    final db = await DBHelper().database;
    await db.insert('departments', {'name': name});
  }

  static Future<void> updateDepartment(int id, String newName) async {
    final db = await DBHelper().database;
    await db.update(
      'departments',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteDepartment(int id) async {
    final db = await DBHelper().database;
    await db.delete(
      'departments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
