import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

// Local feature widgets
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

// Core imports
import 'package:here/core/database/database.dart';
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/constants/app_constants.dart';
import 'package:here/core/services/websocket_service.dart';

// FIXED: Using the clean, absolute path for your auth provider
import 'package:here/features/auth/providers/auth_provider.dart';

class ChatDetailScreen extends HookConsumerWidget {
  final String chatId;
  final String chatName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scrollController = useScrollController();
    
    // Providers
    final messagesAsync = ref.watch(messagesStreamProvider(chatId: chatId));
    final webSocketService = ref.watch(webSocketServiceProvider);
    
    // FIXED: Watch currentUserProvider to get the ID. 
    // authProvider returns AuthStatus (an enum), which doesn't have an 'id' property.
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.maybeWhen(
      data: (user) => user?['id']?.toString() ?? 'guest_user',
      orElse: () => 'guest_user',
    );

    // Local UI State
    final otherUserTyping = useState(false);

    // ================= WebSocket & Lifecycle =================
    useEffect(() {
      webSocketService.on('typing', (data) {
        if (data['chat_id'] == chatId && data['user_id'] != currentUserId) {
          otherUserTyping.value = data['is_typing'] ?? false;
        }
      });
      
      // We include currentUserId in keys to re-bind if the user session changes
      return null; 
    }, [chatId, currentUserId]);

    // Read Status Logic
    useEffect(() {
      messagesAsync.whenData((messages) {
        if (messages.isNotEmpty) {
          final lastMsg = messages.first; // First in DESC list is newest
          if (lastMsg.senderId != currentUserId && 
              lastMsg.status != AppConstants.messageStatusRead) {
            webSocketService.sendReadReceipt(lastMsg.id, chatId);
          }
        }
      });
      return null;
    }, [messagesAsync.value, currentUserId]);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme, otherUserTyping.value),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty 
                  ? _buildEmptyState(theme) 
                  : _buildMessageList(messages, currentUserId, scrollController),
              error: (err, _) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          MessageInput(
            chatId: chatId,
            onMessageSent: () {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  0.0, // List is reversed, 0.0 is the bottom
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, bool typing) {
    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatName,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  typing ? 'Typing...' : 'Online',
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    color: typing ? theme.colorScheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, String currentUserId, ScrollController controller) {
    return ListView.builder(
      controller: controller,
      reverse: true, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        
        final showAvatar = index == messages.length - 1 || 
                           messages[index + 1].senderId != message.senderId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No messages yet', 
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}