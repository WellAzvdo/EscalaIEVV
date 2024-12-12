import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqflite.dart'; // Importando a classe Database

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

  // Inicializa o banco de dados e cria as tabelas
  Future<Database> _initDatabase() async {
    final dbFactory = databaseFactoryFfi; // Certifique-se que o factory está configurado
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/church_schedule.db';
    
    return await dbFactory.openDatabase(path, options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) async {
        // Criação da tabela de departamentos
        await db.execute('''
          CREATE TABLE departments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');

        // Criação da tabela de escalas
        await db.execute('''
          CREATE TABLE scales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            departmentId INTEGER,
            dateTime TEXT,
            memberIds TEXT,
            FOREIGN KEY (departmentId) REFERENCES departments(id)
          )
        ''');

        // Criação da tabela de membros (se necessário)
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
        onUpgrade: (db, oldVersion, newVersion) async {
      // Adicionar alterações necessárias ao banco aqui
      },
    ));
  }

  // Métodos de Departamento
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

  // Métodos de Escala
  static Future<List<Map<String, dynamic>>> getScales() async {
    final db = await DBHelper().database;
    return await db.query('scales');
  }

  static Future<void> insertScale(int departmentId, DateTime dateTime, List<int> memberIds) async {
    final db = await DBHelper().database;
    await db.insert('scales', {
      'departmentId': departmentId,
      'dateTime': dateTime.toIso8601String(),
      'memberIds': memberIds.join(','), // Concatena os IDs dos membros em uma string
    });
  }

  static Future<void> updateScale(int id, int departmentId, DateTime newDateTime, List<int> newMemberIds) async {
    final db = await DBHelper().database;
    await db.update(
      'scales',
      {
        'departmentId': departmentId,
        'dateTime': newDateTime.toIso8601String(),
        'memberIds': newMemberIds.join(','), // Atualiza os IDs dos membros
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteScale(int id) async {
    final db = await DBHelper().database;
    await db.delete(
      'scales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Verifica se já existe uma escala para o departamento no horário
  static Future<bool> checkForScaleConflict(int departmentId, DateTime dateTime) async {
    final db = await DBHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scales',
      where: 'departmentId = ? AND dateTime = ?',
      whereArgs: [departmentId, dateTime.toIso8601String()],
    );

    return maps.isNotEmpty; // Se houver alguma escala, há conflito
  }

  // Verifica se há conflito de membros para a mesma data e horário
  static Future<bool> checkMemberConflict(List<int> memberIds, DateTime dateTime) async {
    final db = await DBHelper().database;

    // Converte os IDs dos membros para a string usada no banco
    String memberIdsPattern = memberIds.map((id) => '%,$id,%').join('|');

    // Consulta para verificar conflitos
    final query = '''
      SELECT * FROM scales
      WHERE dateTime = ? 
      AND (
        ',' || memberIds || ',' GLOB ? 
      )
    ''';

    final args = [dateTime.toIso8601String(), '*,' + memberIds.join(',*,') + ',*'];

    final result = await db.rawQuery(query, args);

    // Retorna verdadeiro se encontrar algum conflito
    return result.isNotEmpty;
  }

  // Função de Debug para verificar as tabelas no banco de dados
  static Future<void> logTables() async {
    final db = await DBHelper().database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table';"
    );
    print("Tabelas no banco de dados: $tables");
  }
}
