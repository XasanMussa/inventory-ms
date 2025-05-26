class ProductNotification {
  final String id; // UUID
  final String? userId; // UUID
  final String? type;
  final String? title;
  final String message;
  final bool isRead;
  final String timestamp;
  final String? productId; // UUID
  final String createdAt;

  ProductNotification({
    required this.id,
    this.userId,
    this.type,
    this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.productId,
    required this.createdAt,
  });

  factory ProductNotification.fromMap(Map<String, dynamic> map) {
    return ProductNotification(
      id: map['id'],
      userId: map['user_id'],
      type: map['type'],
      title: map['title'],
      message: map['message'],
      isRead: map['is_read'] ?? false,
      timestamp: map['timestamp'] ?? map['created_at'],
      productId: map['product_id'],
      createdAt: map['created_at'],
    );
  }
}
