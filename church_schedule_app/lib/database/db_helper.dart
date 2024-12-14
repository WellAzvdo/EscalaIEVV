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
    final dbFactory = databaseFactoryFfi;
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

        // Criação da tabela de membros com departmentId
        await db.execute(''' 
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute(''' 
          CREATE TABLE member_departments (
            memberId INTEGER,
            departmentId INTEGER,
            PRIMARY KEY (memberId, departmentId),
            FOREIGN KEY (memberId) REFERENCES members(id),
            FOREIGN KEY (departmentId) REFERENCES departments(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // No caso de uma atualização, se a versão for maior que 1, altere o banco
        if (oldVersion < 2) {
          await db.execute(''' 
            ALTER TABLE members ADD COLUMN departmentId INTEGER;
          ''');
        }
      },
    ));
  }


  // Função para verificar se o membro já existe no banco
  static Future<int?> checkIfMemberExists(String memberName) async {
    final db = await DBHelper().database;
  
    final result = await db.query(
      'members',
      where: 'name = ?',
      whereArgs: [memberName],
    );
  
    if (result.isNotEmpty) {
      return result.first['id'] as int?; // Retorna o ID do membro existente
    } else {
      return null; // Membro não encontrado
    }
  }

  // Função para adicionar ou atualizar um membro com o novo departamento
  static Future<void> addOrUpdateMemberWithDepartment(String memberName, int departmentId) async {
    final db = await DBHelper().database;

    // Verifica se o membro já existe
    final existingMemberId = await checkIfMemberExists(memberName);

    if (existingMemberId != null) {
      // Membro já existe, adiciona a relação com o departamento, se não existir
      final departmentExists = await db.query(
        'member_departments',
        where: 'memberId = ? AND departmentId = ?',
        whereArgs: [existingMemberId, departmentId],
      );

      if (departmentExists.isEmpty) {
        // Se não existir a relação, insere a nova
        await db.insert('member_departments', {
          'memberId': existingMemberId,
          'departmentId': departmentId,
        });
      }
    } else {
      // Caso o membro não exista, cria um novo e insere a relação com o departamento
      final memberId = await db.insert('members', {'name': memberName});
      await db.insert('member_departments', {
        'memberId': memberId,
        'departmentId': departmentId,
      });
    }
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

  // Alteração da inserção de escalas
  static Future<void> insertScale(int departmentId, DateTime dateTime, List<int> memberIds) async {
    final db = await DBHelper().database;

    // Verifica se já existe uma escala para o departamento e horário
    final conflict = await checkForScaleConflict(departmentId, dateTime, memberIds);
    if (conflict) {
      print("Conflito encontrado, não é possível adicionar a escala.");
      return;
    }

    // Insere a escala
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

  // Verifica se há conflito de escala para um membro em um horário
  static Future<bool> checkForScaleConflict(int departmentId, DateTime dateTime, List<int> memberIds) async {
    final db = await DBHelper().database;

    // Verificar se algum membro da lista já está escalado para o mesmo horário em outro departamento
    final scaleResults = await db.query(
      'scales',
      where: 'dateTime = ?',
      whereArgs: [dateTime.toIso8601String()],
    );

    for (var scale in scaleResults) {
      final existingMemberIds = (scale['memberIds'] as String).split(',').map((id) => int.parse(id.trim())).toList();
      
      // Se algum membro da escala existente estiver na nova lista de membros, há um conflito
      if (memberIds.any((memberId) => existingMemberIds.contains(memberId))) {
        return true; // Conflito encontrado
      }
    }

    return false; // Nenhum conflito encontrado
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

  // Métodos de Membros

  // Insere um novo membro no banco de dados
  static Future<void> insertMember(String name, int departmentId) async {
    final db = await DBHelper().database;
    await db.insert(
      'members',
      {'name': name, 'departmentId': departmentId},
    );
  }

  // Retorna todos os membros no banco de dados
  static Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await DBHelper().database;
    return await db.query('members');
  }

}
