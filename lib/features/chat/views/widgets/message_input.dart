import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

// Unified Imports
import 'package:here/features/auth/providers/auth_provider.dart';
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/providers/media_provider.dart';
import 'package:here/shared/widgets/media_picker_sheet.dart';

class MessageInput extends HookConsumerWidget {
  final String chatId;
  final VoidCallback onMessageSent;

  const MessageInput({
    super.key,
    required this.chatId,
    required this.onMessageSent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final isComposing = useState(false);
    final isSending = useState(false);
    final theme = Theme.of(context);

    // FIXED: Correctly obtaining the User ID from the Map
    final userAsync = ref.watch(currentUserProvider);
    final String currentUserId = userAsync.value?['id']?.toString() ?? '';

    useEffect(() {
      void listener() {
        isComposing.value = textController.text.trim().isNotEmpty;
      }
      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    // ================= MESSAGE LOGIC =================

    Future<void> _sendMessage() async {
      final messageText = textController.text.trim();
      if (messageText.isEmpty || isSending.value || currentUserId.isEmpty) return;

      isSending.value = true;
      textController.clear();

      try {
        // Assuming chatRepositoryProvider is defined in your core/providers
        final chatRepo = ref.read(chatRepositoryProvider);
        
        await chatRepo.sendMessage(
          chatId: chatId,
          senderId: currentUserId, // FIXED: Now matches the variable defined above
          content: messageText, 
        );

        onMessageSent();
      } catch (e) {
        textController.text = messageText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      } finally {
        isSending.value = false;
      }
    }

    // ================= MEDIA LOGIC =================

    Future<void> _pickMedia() async {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MediaPickerSheet(
          onMediaSelected: (media) {
            ref.read(selectedMediaProvider.notifier).addMedia(media);
            // Implement _showMediaPreview logic if needed
          },
          allowMultiple: false,
          allowVideos: true,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 8, right: 8, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _pickMedia,
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildSendButton(isSending.value, isComposing.value, theme, _sendMessage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(bool sending, bool composing, ThemeData theme, VoidCallback onSend) {
    if (sending) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return IconButton(
      icon: Icon(composing ? Icons.send_rounded : Icons.thumb_up_rounded),
      color: theme.colorScheme.primary,
      onPressed: composing ? onSend : () { /* Send Like logic */ },
    );
  }
}