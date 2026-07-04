class TableModel {
  final int? id;
  final String name;
  final String status; // 'kosong' atau 'terisi'

  TableModel({this.id, required this.name, this.status = 'kosong'});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'status': status};
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(id: map['id'], name: map['name'], status: map['status']);
  }
}
