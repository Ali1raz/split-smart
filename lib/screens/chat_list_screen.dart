import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _chatService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
              child:
                  user['avatar_url'] == null
                      ? Text(user['display_name'][0].toUpperCase())
                      : null,
            ),
            title: Text(user['display_name'] ?? 'Unknown User'),
            subtitle: Text(user['username'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatDetailScreen(
                        otherUserId: user['id'],
                        otherUserName: user['display_name'] ?? 'Unknown User',
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
