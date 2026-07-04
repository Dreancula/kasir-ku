import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? _tableId;
  String? _tableName;

  List<CartItem> get items => _items;
  int? get tableId => _tableId;
  String? get tableName => _tableName;
  bool get isDineIn => _tableId != null;

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(MenuItem menuItem) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItem.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void decreaseItem(MenuItem menuItem) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItem.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(MenuItem menuItem) {
    _items.removeWhere((item) => item.menuItem.id == menuItem.id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void setTable(int id, String name) {
    _tableId = id;
    _tableName = name;
    notifyListeners();
  }

  void clearTable() {
    _tableId = null;
    _tableName = null;
    notifyListeners();
  }
}
