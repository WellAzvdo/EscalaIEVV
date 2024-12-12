import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DBHelper {
  static const _databaseName = "church_schedule.db";
  static const _databaseVersion = 1;

  static final DBHelper instance = DBHelper._privateConstructor();
  DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use sqflite_common_ffi for desktop platforms
    databaseFactory = databaseFactoryFfi;
   

    String path = join(await getDatabasesPath(), _databaseName);
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        department_id INTEGER NOT NULL,
        FOREIGN KEY (department_id) REFERENCES departments (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY,
        date TEXT NOT NULL,
        person_id INTEGER NOT NULL,
        FOREIGN KEY (person_id) REFERENCES people (id)
      )
    ''');
  }
}
