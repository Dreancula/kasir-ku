class TransactionModel {
  final int id;
  final double total;
  final DateTime createdAt;
  final int? userId;
  final String? userName;
  final String? customerName;

  TransactionModel({
    required this.id,
    required this.total,
    required this.createdAt,
    this.userId,
    this.userName,
    this.customerName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      total: map['total'],
      createdAt: DateTime.parse(map['created_at']),
      userId: map['user_id'],
      userName: map['user_name'],
      customerName: map['customer_name'],
    );
  }
}
