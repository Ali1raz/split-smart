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

  // Create a new group
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      if (memberIds.length > 5) {
        throw Exception('Group can have maximum 5 members');
      }

      // Create the group
      final groupResponse =
          await _supabase
              .from('groups')
              .insert({
                'name': name,
                'created_by': _supabase.auth.currentUser!.id,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

      final groupId = groupResponse['id'];

      // Add members to the group
      final members = [
        {
          'group_id': groupId,
          'user_id': _supabase.auth.currentUser!.id,
        }, // Add creator
        ...memberIds.map((id) => {'group_id': groupId, 'user_id': id}),
      ];

      await _supabase.from('group_members').insert(members);

      return groupId;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's groups
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      final response = await _supabase
          .from('groups')
          .select('*, group_members!inner(*)')
          .eq('group_members.user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('*, profiles!inner(*)')
          .eq('group_id', groupId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get group chat history
  Future<List<Map<String, dynamic>>> getGroupChatHistory(String groupId) async {
    try {
      final response = await _supabase
          .from('group_messages')
          .select('*, profiles!inner(*)')
          .eq('group_id', groupId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Send a message to group
  Future<void> sendGroupMessage({
    required String groupId,
    required String content,
  }) async {
    try {
      await _supabase.from('group_messages').insert({
        'group_id': groupId,
        'sender_id': _supabase.auth.currentUser!.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get direct chat history between two users
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

  // Send a direct message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'sender_id': _supabase.auth.currentUser!.id,
        'receiver_id': receiverId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
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

  // Subscribe to group messages
  Stream<List<Map<String, dynamic>>> subscribeToGroupMessages(String groupId) {
    return _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .map((rows) => rows);
  }

  // Subscribe to direct messages
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String otherUserId) {
    // final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        // .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        // .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
        .order('created_at', ascending: true)
        .map((rows) => rows);
  }
}
