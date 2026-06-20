class Item {
  int? id;
  String barcode;
  String name;
  double price;
  double costPrice;
  int quantity;
  String? imagePath;
  String? expiryDate;
  double wholesalePrice;
  String? category;
  String unitType;

  Item({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
    this.costPrice = 0.0,
    this.quantity = 0,
    this.imagePath,
    this.expiryDate,
    this.wholesalePrice = 0.0,
    this.category,
    this.unitType = 'دانە',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'quantity': quantity,
      'image_path': imagePath,
      'expiry_date': expiryDate,
      'wholesale_price': wholesalePrice,
      'category': category,
      'unit_type': unitType,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      price: map['price']?.toDouble() ?? 0.0,
      costPrice: map['cost_price']?.toDouble() ?? 0.0,
      quantity: map['quantity'],
      imagePath: map['image_path'],
      expiryDate: map['expiry_date'],
      wholesalePrice: map['wholesale_price']?.toDouble() ?? 0.0,
      category: map['category'],
      unitType: map['unit_type'] ?? 'دانە',
    );
  }

  Item copyWith({
    int? id,
    String? barcode,
    String? name,
    double? price,
    double? costPrice,
    int? quantity,
    String? imagePath,
    String? expiryDate,
    double? wholesalePrice,
    String? category,
    String? unitType,
  }) {
    return Item(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
      expiryDate: expiryDate ?? this.expiryDate,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      category: category ?? this.category,
      unitType: unitType ?? this.unitType,
    );
  }
}
