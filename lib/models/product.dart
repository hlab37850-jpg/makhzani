class Product {
  final int? id;
  final String name;
  final String barcode;
  final double quantity;
  final double purchasePrice;
  final double salePrice;
  final double minQuantity;
  final String createdAt;

  const Product({
    this.id,
    required this.name,
    this.barcode = '',
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.minQuantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'min_quantity': minQuantity,
      'created_at': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: (map['barcode'] ?? '') as String,
      quantity: (map['quantity'] as num).toDouble(),
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      minQuantity: (map['min_quantity'] as num).toDouble(),
      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}
