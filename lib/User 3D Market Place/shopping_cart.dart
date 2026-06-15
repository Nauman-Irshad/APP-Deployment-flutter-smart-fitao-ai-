import 'package:flutter/foundation.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.title,
    required this.brandName,
    required this.price,
    required this.size,
    required this.color,
    required this.material,
    required this.quantity,
    this.imagePath,
    this.variantLabel = 'Standard',
    this.isFabric = true,
  });

  final String id;
  final String title;
  final String brandName;
  final int price;
  final String size;
  final String color;
  final String material;
  int quantity;
  final String? imagePath;
  final String variantLabel;
  final bool isFabric;

  int get lineTotal => price * quantity;

  Map<String, dynamic> toDisplayMap() => {
        'id': id,
        'title': title,
        'brandName': brandName,
        'price': price,
        'size': size,
        'color': color,
        'material': material,
        'quantity': quantity,
        'imagePath': imagePath,
        'variantLabel': variantLabel,
        'isFabric': isFabric,
      };
}

class ShoppingCart extends ChangeNotifier {
  ShoppingCart._();
  static final ShoppingCart instance = ShoppingCart._();

  final List<CartItem> items = [];
  VoidCallback? onNavigateToCart;
  void Function(int index)? onNavigateToTab;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  int get deliveryFee => subtotal >= 5000 ? 0 : 1500;

  int get total => subtotal + deliveryFee;

  void addItem(CartItem item) {
    final existing = items.indexWhere(
      (e) =>
          e.id == item.id &&
          e.size == item.size &&
          e.color == item.color &&
          e.material == item.material,
    );
    if (existing >= 0) {
      items[existing].quantity += item.quantity;
    } else {
      items.add(item);
    }
    notifyListeners();
  }

  void addAndOpenCart(CartItem item) {
    addItem(item);
    onNavigateToCart?.call();
  }

  void updateQuantity(int index, int qty) {
    if (index < 0 || index >= items.length) return;
    if (qty < 1) {
      items.removeAt(index);
    } else {
      items[index].quantity = qty;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}

CartItem cartItemFromProduct(
  Map<String, dynamic> product, {
  required String size,
  required String color,
  required String material,
  required int quantity,
}) {
  final price = product['price'] is int
      ? product['price'] as int
      : int.tryParse('${product['price']}') ?? 0;
  return CartItem(
    id: product['id']?.toString() ?? product['title']?.toString() ?? '',
    title: product['title']?.toString() ?? 'Product',
    brandName: product['brandName']?.toString() ?? 'SmartFitao Store',
    price: price,
    size: size,
    color: color,
    material: material,
    quantity: quantity,
    imagePath: product['imagePath']?.toString(),
    isFabric: product['section'] == 'Fabric' || product['category'] == 'Fabric',
  );
}
