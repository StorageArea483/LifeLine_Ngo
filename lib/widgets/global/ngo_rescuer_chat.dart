import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/pages/ngo_contact_page.dart';

import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/providers/ngo_rescuer_chat_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';

class NgoRescuerChat extends ConsumerStatefulWidget {
  final String rescuerId;
  final String rescuerName;
  final String rescuerPhotoUrl;
  const NgoRescuerChat({
    super.key,
    required this.rescuerId,
    required this.rescuerName,
    required this.rescuerPhotoUrl,
  });

  @override
  ConsumerState<NgoRescuerChat> createState() => _NgoRescuerChatState();
}

class _NgoRescuerChatState extends ConsumerState<NgoRescuerChat> {
  final TextEditingController _messageController = TextEditingController();

  StreamSubscription? _messageSubscription;
  StreamSubscription? _presenceSubscription;

  String? currentNgoId;
  String? ngoDocId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  // Builds a deterministic chat id from the two participant ids
  String _generateChatId(String userId, String rescuerId) {
    final ids = [userId, rescuerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _initializeChat() async {
    if (mounted) {
      ref.read(ngoRescuerChatLoadingProvider.notifier).state = true;
    }
    try {
      if (!mounted) return;
      ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;

      if (ngoDocId == null) {
        if (mounted) {
          ref.read(ngoRescuerChatLoadingProvider.notifier).state = false;
          pageMessage(
            'User not found. Please login again.',
            context,
            AppColors.error,
          );
          pageNavigation(const NgoContactPage(), context);
        }
        return;
      }

      currentNgoId = ngoDocId;

      final chatId = _generateChatId(ngoDocId!, widget.rescuerId);
      if (mounted) {
        ref.read(ngoRescuerChatIdProvider.notifier).state = chatId;
      }

      _subscribeToMessages(chatId);
      _subscribeToPresence();

      if (mounted) {
        ref.read(ngoRescuerChatLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(ngoRescuerChatLoadingProvider.notifier).state = false;
        pageMessage(
          'An unexpected error occurred. Please try again.',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoContactPage(), context);
      }
    }
  }

  void _subscribeToMessages(String chatId) {
    try {
      _messageSubscription?.cancel();

      _messageSubscription = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

            final messages = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'senderId': data['senderId'] ?? '',
                'text': data['text'] ?? '',
                'createdAt': data['createdAt'],
              };
            }).toList();

            if (!mounted) return;
            ref.read(ngoRescuerChatMessagesProvider(chatId).notifier).state =
                messages;
          });
    } catch (e) {
      rethrow;
    }
  }

  void _subscribeToPresence() {
    if (ngoDocId == null) return;

    try {
      _presenceSubscription?.cancel();

      _presenceSubscription = FirebaseFirestore.instance
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .doc(widget.rescuerId)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            final isOnline = snapshot.data()?['online'] ?? false;
            ref
                    .read(
                      rescuerOnlineStatusProviderNgo(widget.rescuerId).notifier,
                    )
                    .state =
                isOnline;
          });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendMessage() async {
    try {
      final text = _messageController.text.trim();
      if (text.isEmpty && !mounted) return;
      final userId = ngoDocId;
      if (!mounted) return;
      final currentChatId = ref.read(ngoRescuerChatIdProvider);

      if (userId == null || currentChatId == null) {
        if (mounted) {
          pageMessage(
            'Unable to send message. Please try again.',
            context,
            AppColors.error,
          );
        }
        return;
      }

      _messageController.clear();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(currentChatId)
          .collection('messages')
          .add({
            'chatId': currentChatId,
            'senderId': userId,
            'receiverId': widget.rescuerId,
            'text': text,
            'status': 'sent',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to send message. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      if (!mounted) return;
      final chatId = ref.read(ngoRescuerChatIdProvider);
      if (chatId == null) return;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to delete message. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Widget _buildOptionsMenu(String messageId) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'delete') {
          _deleteMessage(messageId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Message'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkCharcoal.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return _buildHeader(context, ref);
                  },
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      return _buildMessagesList(context, ref);
                    },
                  ),
                ),
                _buildInputSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    const avatarSize = 48.0;
    final isOnline = ref.watch(
      rescuerOnlineStatusProviderNgo(widget.rescuerId),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
            onPressed: () => pageNavigation(const NgoContactPage(), context),
            tooltip: 'Back to contacts',
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                  child: widget.rescuerPhotoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.rescuerPhotoUrl,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: AppColors.primaryMaroon,
                                size: avatarSize * 0.5,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Icon(
                                Icons.person,
                                color: AppColors.primaryMaroon.withOpacity(0.5),
                                size: avatarSize * 0.5,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.primaryMaroon,
                          size: avatarSize * 0.5,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: avatarSize * 0.28,
                    height: avatarSize * 0.28,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rescuerName,
                  style: AppText.fieldLabel.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppText.small.copyWith(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(ngoRescuerChatLoadingProvider);
    final chatId = ref.watch(ngoRescuerChatIdProvider);

    if (isLoading || chatId == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMaroon),
      );
    }

    final messages = ref.watch(ngoRescuerChatMessagesProvider(chatId));

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                'No messages yet',
                style: AppText.subtitle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSentByMe = message['senderId'] == currentNgoId;
        return _buildMessageBubble(context, message, isSentByMe);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isSentByMe,
  ) {
    const bubbleMaxWidth = 480.0;
    final messageId = message['id'] as String;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSentByMe) _buildOptionsMenu(messageId),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxWidth: bubbleMaxWidth),
            decoration: BoxDecoration(
              color: isSentByMe ? AppColors.primaryMaroon : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                bottomRight: Radius.circular(isSentByMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkCharcoal.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isSentByMe ? Colors.white : AppColors.darkCharcoal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryMaroon.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CircleAvatar(
              backgroundColor: AppColors.primaryMaroon,
              radius: 24,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
