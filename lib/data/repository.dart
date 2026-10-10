import 'package:supabase_flutter/supabase_flutter.dart';

class GinulisRepository {
  GinulisRepository._();
  static final instance = GinulisRepository._();

  SupabaseClient get _db => Supabase.instance.client;
  String get _owner => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> customers() async {
    final rows = await _db.from('customers').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> saveCustomer({String? id, required String name,
      required String phone, required String notes}) async {
    final values = {'name': name.trim(), 'phone': phone.trim(), 'notes': notes.trim()};
    if (id == null) {
      await _db.from('customers').insert({...values, 'owner_id': _owner});
    } else {
      await _db.from('customers').update(values).eq('id', id);
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _db.from('customers').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> orders() async {
    final rows = await _db.from('orders')
        .select('*, customers(name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> order(String id) async {
    final row = await _db.from('orders')
        .select('*, customers(name, phone)')
        .eq('id', id).single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> saveOrder({String? id, required String customerId,
      required String title, required String description,
      required int price, String? deadline, required String workStatus}) async {
    final values = {
      'customer_id': customerId, 'title': title.trim(),
      'description': description.trim(), 'price': price,
      'deadline': deadline, 'work_status': workStatus,
    };
    if (id == null) {
      await _db.from('orders').insert({...values, 'owner_id': _owner});
    } else {
      await _db.from('orders').update(values).eq('id', id);
    }
  }

  Future<void> deleteOrder(String id) async {
    await _db.from('orders').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> payments(String orderId) async {
    final rows = await _db.from('payments').select()
        .eq('order_id', orderId).order('paid_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> allPayments() async {
    final rows = await _db.from('payments').select('order_id, amount, paid_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addPayment({required String orderId,
      required int amount, required String method, required String notes}) async {
    await _db.from('payments').insert({
      'owner_id': _owner, 'order_id': orderId,
      'amount': amount, 'method': method, 'notes': notes.trim(),
    });
  }
}
