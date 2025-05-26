import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/product.dart';
import '../models/notification.dart';
import '../models/environment_reading.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // Fetch products ordered by created_at desc
  Future<List<Product>> fetchProducts() async {
    final response = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Add product
  Future<Product> addProduct(Product product) async {
    final response = await supabase
        .from('products')
        .insert({
          'name': product.name,
          'quantity': product.quantity,
          'threshold': product.threshold,
          'expired_date': product.expiredDate,
          'section': product.section,
        })
        .select()
        .single();
    return Product.fromMap(response as Map<String, dynamic>);
  }

  // Update product and handle notification logic
  Future<void> updateProduct(Product oldProduct, Product updatedProduct) async {
    await supabase.from('products').update({
      'name': updatedProduct.name,
      'quantity': updatedProduct.quantity,
      'threshold': updatedProduct.threshold,
      'expired_date': updatedProduct.expiredDate,
      'section': updatedProduct.section,
    }).eq('id', oldProduct.id);

    // Notification logic
    if (oldProduct.quantity != updatedProduct.quantity &&
        updatedProduct.quantity != oldProduct.lastNotifiedQuantity) {
      final changeType = updatedProduct.quantity > oldProduct.quantity
          ? 'increased'
          : 'decreased';
      final diff = (updatedProduct.quantity - oldProduct.quantity).abs();
      final message =
          "Quantity of '${updatedProduct.name}' was $changeType by $diff. New quantity: ${updatedProduct.quantity}.";

      await supabase.from('notifications').insert({
        'type': 'quantity_change',
        'title': 'Quantity Changed',
        'message': message,
        'product_id': oldProduct.id,
        'is_read': false,
      });

      await supabase.from('products').update({
        'last_notified_quantity': updatedProduct.quantity,
      }).eq('id', oldProduct.id);
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }

  // Fetch notifications for a product
  Future<List<ProductNotification>> fetchNotifications(String productId) async {
    final response = await supabase
        .from('notifications')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (response as List)
        .map(
            (item) => ProductNotification.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Fetch all notifications (for notifications screen)
  Future<List<ProductNotification>> fetchAllNotifications() async {
    final response = await supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map(
            (item) => ProductNotification.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await supabase.from('notifications').delete().eq('id', notificationId);
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final response =
        await supabase.from('notifications').select('id').eq('is_read', false);
    return (response as List).length;
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).neq('is_read', true);
  }

  // Fetch the latest environment reading
  Future<EnvironmentReading?> fetchLatestEnvironmentReading() async {
    final response = await supabase.from('sensor_readings').select().limit(1);
    if (response is List && response.isNotEmpty) {
      return EnvironmentReading.fromMap(response.first);
    }
    return null;
  }
}
