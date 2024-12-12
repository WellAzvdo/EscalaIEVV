class Scale {
  final int? id;
  final int departmentId;
  final DateTime dateTime;
  final List<int> memberIds; // IDs dos membros escalados

  Scale({
    this.id,
    required this.departmentId,
    required this.dateTime,
    required this.memberIds,
  });

  // Método para converter o modelo Scale para um mapa para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departmentId': departmentId,
      'dateTime': dateTime.toIso8601String(),
      'memberIds': memberIds.join(','),
    };
  }

  // Método para converter o mapa do banco de volta para um modelo Scale
  factory Scale.fromMap(Map<String, dynamic> map) {
    return Scale(
      id: map['id'],
      departmentId: map['departmentId'],
      dateTime: DateTime.parse(map['dateTime']),
      memberIds: map['memberIds'].toString().split(',').map((id) => int.parse(id)).toList(),
    );
  }
}
