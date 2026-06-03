import 'package:flutter/foundation.dart';

class CartItem {
  final int menuItemId;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });
}

class CartProvider extends ChangeNotifier {
  int? orderId;
  int? reservationId;
  int? restaurantId;
  String? restaurantName;
  String? orderStatus; // Pending | InProgress | Ready | BillRequested | Paid

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get total =>
      _items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  bool hasItem(int menuItemId) => _items.containsKey(menuItemId);

  int quantityOf(int menuItemId) => _items[menuItemId]?.quantity ?? 0;

  void setContext({
    required int orderId,
    required int? reservationId,
    required int restaurantId,
    required String restaurantName,
    String status = 'Pending',
  }) {
    this.orderId = orderId;
    this.reservationId = reservationId;
    this.restaurantId = restaurantId;
    this.restaurantName = restaurantName;
    this.orderStatus = status;
    notifyListeners();
  }

  void updateStatus(String status) {
    orderStatus = status;
    notifyListeners();
  }

  void addItem({
    required int menuItemId,
    required String name,
    required double price,
    String? imageUrl,
  }) {
    if (_items.containsKey(menuItemId)) {
      _items[menuItemId]!.quantity++;
    } else {
      _items[menuItemId] = CartItem(
        menuItemId: menuItemId,
        name: name,
        price: price,
        imageUrl: imageUrl,
      );
    }
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    if (_items.containsKey(menuItemId)) {
      if (_items[menuItemId]!.quantity > 1) {
        _items[menuItemId]!.quantity--;
      } else {
        _items.remove(menuItemId);
      }
    }
    notifyListeners();
  }

  void deleteItem(int menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    orderId = null;
    reservationId = null;
    restaurantId = null;
    restaurantName = null;
    orderStatus = null;
    notifyListeners();
  }
}