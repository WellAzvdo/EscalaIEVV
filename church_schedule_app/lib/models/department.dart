class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  // Converter o Map do banco de dados para a classe
  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'],
      name: map['name'],
    );
  }

  // Converter a classe para Map para inserção no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
