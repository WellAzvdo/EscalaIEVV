class Member {
  final int id;
  final String name;
  final int departmentId;

  Member({required this.id, required this.name, required this.departmentId});

  // Converter o Map do banco de dados para a classe
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      departmentId: map['departmentId'],
    );
  }

  // Converter a classe para Map para inserção no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'departmentId': departmentId,
    };
  }
}
