class Product {
  final String id; // UUID in the database
  final String name;
  final int quantity;
  final int threshold;
  final String? expiredDate; // date in the database
  final String section;
  final String createdAt; // timestamp with time zone
  final int? lastNotifiedQuantity;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.threshold,
    this.expiredDate,
    required this.section,
    required this.createdAt,
    this.lastNotifiedQuantity,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      threshold: map['threshold'],
      expiredDate: map['expired_date'],
      section: map['section'] ?? 'A',
      createdAt: map['created_at'] ?? '',
      lastNotifiedQuantity: map['last_notified_quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'threshold': threshold,
      'expired_date': expiredDate,
      'section': section,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    int? quantity,
    int? threshold,
    String? expiredDate,
    String? section,
    String? createdAt,
    int? lastNotifiedQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
      expiredDate: expiredDate ?? this.expiredDate,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
      lastNotifiedQuantity: lastNotifiedQuantity ?? this.lastNotifiedQuantity,
    );
  }
}
