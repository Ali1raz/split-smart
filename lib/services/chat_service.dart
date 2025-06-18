import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all users except current user
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', _supabase.auth.currentUser!.id);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get chat history between two users
  Future<List<Map<String, dynamic>>> getChatHistory(String otherUserId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or(
            'sender_id.eq.${_supabase.auth.currentUser!.id},receiver_id.eq.${_supabase.auth.currentUser!.id}',
          )
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'sender_id': _supabase.auth.currentUser!.id,
        'receiver_id': receiverId,
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
    } catch (e) {
      rethrow;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Subscribe to new messages
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String otherUserId) {
    // final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) => rows);
  }
}
