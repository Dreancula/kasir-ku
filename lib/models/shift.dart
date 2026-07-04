class Shift {
  final int? id;
  final int userId;
  final String userName;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalSales;

  Shift({
    this.id,
    required this.userId,
    required this.userName,
    required this.startTime,
    this.endTime,
    this.totalSales = 0,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get durationString {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_sales': totalSales,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_name'] ?? 'Unknown',
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0,
    );
  }

  Shift copyWith({
    int? id,
    int? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    double? totalSales,
  }) {
    return Shift(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}
