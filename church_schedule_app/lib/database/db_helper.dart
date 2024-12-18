//import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';  // Importação da biblioteca 'path'

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._() {
    // Não é mais necessário inicializar o sqflite_ffi
  }

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados e cria as tabelas
  Future<Database> _initDatabase() async {
    //final dbFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/church_schedule.db';
  
    return await openDatabase(path, version: 2, onCreate: (db, version) async {
      // Criação da tabela de departamentos
      await db.execute(''' 
        CREATE TABLE departments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT -- Novo campo para armazenar o ícone do departamento
        )
      ''');

      // Criação da tabela de escalas
      await db.execute(''' 
        CREATE TABLE scales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          departmentId INTEGER,
          positionId INTEGER,  -- A coluna positionId deve ser aqui
          dateTime TEXT,
          memberIds TEXT,
          FOREIGN KEY (departmentId) REFERENCES departments(id)
        )
      ''');

      // Criação da tabela de membros com departmentId
      await db.execute(''' 
        CREATE TABLE members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          departmentId INTEGER,  
          FOREIGN KEY (departmentId) REFERENCES departments(id)
        )
      ''');
        
      await db.execute('''
        CREATE TABLE positions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          departmentId INTEGER NOT NULL,
          name TEXT NOT NULL,
          positionId INTEGER,
          FOREIGN KEY(departmentId) REFERENCES departments(id)
        )
      ''');
    }, 
        onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(''' 
            ALTER TABLE departments ADD COLUMN icon TEXT;
          ''');
        }
    });
  }

  // Posições de cada departamento
  static Future<void> insertPosition(int departmentId, String name) async {
   final db = await DBHelper().database;
   await db.insert(
     'positions',
     {'departmentId': departmentId, 'name': name},
     conflictAlgorithm: ConflictAlgorithm.replace,
   );
  }

  static Future<List<Map<String, dynamic>>> getPositionsByDepartment(int departmentId) async {
    final db = await DBHelper().database;
    return await db.query(
      'positions',
      where: 'departmentId = ?',
      whereArgs: [departmentId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllPositions () async {
    final db = await DBHelper().database;
    return await db.query(
      'positions',
    );
  }

  static Future<void> deletePosition(int id) async {
    final db = await DBHelper().database;
    await db.delete(
      'positions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  static Future<void> updatePosition(int id, String name) async {
    final db = await DBHelper().database;
    await db.update(
      'positions',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<bool> checkIfMemberIsScheduled(String memberName, DateTime dateTime) async {
    final db = await DBHelper().database;
  
    // Converte a data e hora para o formato ISO 8601
    final formattedDateTime = dateTime.toIso8601String();
  
    // Primeiro, obtemos os IDs dos membros com o nome fornecido
    final memberQuery = await db.query(
      'members',
      where: 'name = ?',
      whereArgs: [memberName],
    );
  
    // Se não encontrar nenhum membro com esse nome, retorna falso
    if (memberQuery.isEmpty) {
      return false;
    }
  
    // Extraímos os IDs dos membros encontrados
    final memberIds = memberQuery.map((e) => e['id'] as int).toList();
  
    // Agora, buscamos as escalas para o mesmo horário
    final scaleQuery = await db.query(
      'scales',
      where: 'dateTime = ?',
      whereArgs: [formattedDateTime],
    );
  
    // Verifica se algum membro já está escalado para esse horário
    for (var scale in scaleQuery) {
      final existingMemberIds = (scale['memberIds'] as String)
          .split(',')
          .map((id) => int.parse(id.trim()))
          .toList();
  
      // Se algum dos membros do banco já estiver na lista da escala, retornamos verdadeiro (conflito)
      if (memberIds.any((id) => existingMemberIds.contains(id))) {
        return true; // Conflito encontrado
      }
    }
  
    // Se não encontrar nenhum conflito, retorna falso
    return false;
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

  static Future<void> insertDepartment(String name, String? icon) async {
    final db = await DBHelper().database;
    await db.insert('departments', 
    {
      'name': name,
      'icon': icon // Armazena o ícone, pode ser nulo
    });
  }

  static Future<void> updateDepartment(int id, String newName, String? newIcon) async {
    final db = await DBHelper().database;
    await db.update(
      'departments',
      {
        'name': newName,
        'icon': newIcon // Atualiza o ícone
      },
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

    // Fazemos um JOIN entre as tabelas scales e departments para pegar o nome do departamento
    final result = await db.rawQuery('''
      SELECT scales.*, departments.name AS departmentName
      FROM scales
      JOIN departments ON scales.departmentId = departments.id
    ''');

    return result;
  }
  
  Future<List<Map<String, dynamic>>> getScalesWithPositionNames() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT scales.*, positions.name AS position_name
      FROM scales
      JOIN positions ON scales.positionId = positions.id
    ''');

    return result;
  }



  // Renomeado para 'databaseInstance' para evitar conflito com o membro estático
  static Future<Database> get databaseInstance async {
    final dbPath = await getDatabasesPath();
    return openDatabase(join(dbPath, 'church_schedule.db'));
  }

  // Método para obter a escala por ID
  Future<Map<String, dynamic>> getScaleById(int scaleId) async {
    final db = await databaseInstance; // Acesso ao banco de dados
    final result = await db.query(
      'scales', // Nome da tabela de escalas
      where: 'id = ?', // Condição para buscar pela ID
      whereArgs: [scaleId], // Argumento a ser passado
    );

    if (result.isNotEmpty) {
      return result.first; // Retorna o primeiro (único) item encontrado
    } else {
      throw Exception('Escala não encontrada');
    }
  }

  // Método para buscar o nome da posição com base no positionId e departmentId
  // Remova o 'static' do método, tornando-o um método de instância
  Future<String> getPositionName(int positionId, int departmentId) async {
    final db = await database;
    final result = await db.query(
      'positions',
      where: 'id = ? AND departmentId = ?',
      whereArgs: [positionId, departmentId],
    );

    if (result.isNotEmpty) {
      return result.first['name'] as String; // Garantindo que o valor é retornado como String
    } else {
      return 'Posição não encontrada';
    }
  }



  // Alteração da inserção de escalas
  static Future<void> insertScale(int departmentId, int positionId, DateTime dateTime, List<int> memberIds) async {
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
      'positionId': positionId, // Novo campo no banco
      'dateTime': dateTime.toIso8601String(),
      'memberIds': memberIds.join(','), // Concatena os IDs dos membros em uma string
    });
  }

  static Future<void> updateScale(int id, int departmentId, int positionId, DateTime newDateTime, List<int> newMemberIds) async {
    final db = await DBHelper().database;
    await db.update(
      'scales',
      {
        'departmentId': departmentId,
        'positionId': positionId, // Novo campo no banco
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

  static Future<Map<String, dynamic>> getMemberById(int memberId) async {
    final db = await DBHelper().database;
    final result = await db.query('members', where: 'id = ?', whereArgs: [memberId]);

    print('Resultado da consulta: $result'); // Verifique o que está sendo retornado

    return result.isNotEmpty ? result.first : {}; // Retorna um mapa vazio caso não haja resultado
  }

  // Renomeando o getter de 'database' para 'getDatabase' para evitar conflito
  Future<Database> get getDatabase async {
    var dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'church_schedule.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE members(id INTEGER PRIMARY KEY, name TEXT)',
        );
      },
      version: 1,
    );
  }

  // Método para deletar membro
    Future<void> deleteMember(int id) async {
    final db = await database; // Acessa a instância do banco de dados
    await db.delete(
      'members', // Tabela onde os membros são armazenados
      where: 'id = ?', // Condição de exclusão
      whereArgs: [id], // Argumento do ID
    );
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
