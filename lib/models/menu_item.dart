class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String category;

  MenuItem({
    this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  // Ubah dari objek Dart ke Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'category': category};
  }

  // Ubah dari Map (hasil baca database) ke objek Dart
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      category: map['category'],
    );
  }
}
