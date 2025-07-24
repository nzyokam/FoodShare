import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/shelter/chat_screen.dart';
import '../../models/donation_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/shelter_model.dart';
import '../../models/user_model.dart';

class ChatsListScreen extends StatefulWidget {
  final UserType userType;
  final Function(int)? onDrawerItemSelected;

  const ChatsListScreen({
    super.key,
    required this.userType,
    this.onDrawerItemSelected,
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _cleanupBrokenChats();
  }

  Future<void> _cleanupBrokenChats() async {
    try {
      final chatsQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where(
            widget.userType == UserType.restaurant
                ? 'restaurantId'
                : 'shelterId',
            isEqualTo: currentUserId,
          )
          .get();

      List<String> brokenChatIds = [];

      for (var chatDoc in chatsQuery.docs) {
        final chatData = chatDoc.data();

        final donationId = chatData['donationId'] as String?;
        final restaurantId = chatData['restaurantId'] as String?;
        final shelterId = chatData['shelterId'] as String?;

        bool isBroken = false;

        if (donationId == null || donationId.isEmpty) {
          isBroken = true;
        }

        if (restaurantId == null || restaurantId.isEmpty) {
          isBroken = true;
        }

        if (shelterId == null || shelterId.isEmpty) {
          isBroken = true;
        }

        if (isBroken) {
          brokenChatIds.add(chatDoc.id);
          continue;
        }

        // Check if donation exists
        try {
          final donationDoc = await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId!)
              .get();

          if (!donationDoc.exists) {
            brokenChatIds.add(chatDoc.id);
          }
        } catch (e) {
          brokenChatIds.add(chatDoc.id);
        }
      }

      if (brokenChatIds.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (String chatId in brokenChatIds) {
          batch.delete(
            FirebaseFirestore.instance.collection('chats').doc(chatId),
          );
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cleaned up ${brokenChatIds.length} broken conversations',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Silent cleanup - don't show errors to user
    }
  }

  Stream<List<ChatItem>> _getChatsStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where(
          widget.userType == UserType.restaurant ? 'restaurantId' : 'shelterId',
          isEqualTo: currentUserId,
        )
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChatItem> chatItems = [];

          for (var chatDoc in snapshot.docs) {
            final chatData = chatDoc.data();

            try {
              // Validate all required fields exist and are not empty
              final donationId = chatData['donationId'] as String?;
              final restaurantId = chatData['restaurantId'] as String?;
              final shelterId = chatData['shelterId'] as String?;

              if (donationId == null ||
                  donationId.isEmpty ||
                  restaurantId == null ||
                  restaurantId.isEmpty ||
                  shelterId == null ||
                  shelterId.isEmpty) {
                continue;
              }

              // Get donation details
              final donationDoc = await FirebaseFirestore.instance
                  .collection('donations')
                  .doc(donationId)
                  .get();

              if (!donationDoc.exists) continue;

              final donation = Donation.fromJson(
                donationDoc.data()!,
                docId: donationDoc.id,
              );

              // Get other party details
              String otherPartyId;
              String otherPartyCollection;

              if (widget.userType == UserType.restaurant) {
                otherPartyId = shelterId;
                otherPartyCollection = 'shelters';
              } else {
                otherPartyId = restaurantId;
                otherPartyCollection = 'restaurants';
              }

              // Get other party info
              final otherPartyDoc = await FirebaseFirestore.instance
                  .collection(otherPartyCollection)
                  .doc(otherPartyId)
                  .get();

              if (!otherPartyDoc.exists) continue;

              String otherPartyName;
              if (widget.userType == UserType.restaurant) {
                final shelter = Shelter.fromJson(otherPartyDoc.data()!);
                otherPartyName = shelter.organizationName;
              } else {
                final restaurant = Restaurant.fromJson(otherPartyDoc.data()!);
                otherPartyName = restaurant.businessName;
              }

              chatItems.add(
                ChatItem(
                  chatId: chatDoc.id,
                  donation: donation,
                  otherPartyName: otherPartyName,
                  otherPartyId: otherPartyId,
                  lastMessage: chatData['lastMessage'] as String? ?? '',
                  lastMessageAt: chatData['lastMessageAt'] as Timestamp?,
                ),
              );
            } catch (e) {
              continue;
            }
          }

          return chatItems;
        });
  }

  // Separate stream for unread counts to get real-time updates
  Stream<int> _getUnreadCountStream(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark messages as read when chat is opened
  Future<void> _markMessagesAsRead(String chatId) async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (var messageDoc in unreadMessages.docs) {
          batch.update(messageDoc.reference, {'read': true});
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Image.asset(
            'lib/assets/2.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          'Chats',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _cleanupBrokenChats();
            },
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.inversePrimary,),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<List<ChatItem>>(
        stream: _getChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _cleanupBrokenChats();
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userType == UserType.restaurant
                        ? 'Start chatting when shelters request your donations'
                        : 'Start chatting by requesting donations from restaurants',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(160),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatListItem(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(ChatItem chat) {
    return StreamBuilder<int>(
      stream: _getUnreadCountStream(chat.chatId),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return Container(
          color: hasUnread
              ? const Color(0xFF2E7D32).withAlpha(10)
              : const Color.fromARGB(0, 0, 0, 0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(20),
                  child: Icon(
                    widget.userType == UserType.restaurant
                        ? Icons.home
                        : Icons.restaurant,
                    color: const Color(0xFF2E7D32),
                    size: 28,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chat.otherPartyName,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chat.lastMessageAt != null
                      ? _formatTime(chat.lastMessageAt!.toDate())
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? const Color(0xFF2E7D32)
                        : Theme.of(context).colorScheme.inversePrimary,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage.isEmpty
                            ? 'No messages yet'
                            : chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.inversePrimary
                              .withAlpha(hasUnread ? 200 : 160),
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          chat.donation.status,
                        ).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chat.donation.status
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          color: _getStatusColor(chat.donation.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  chat.donation.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2E7D32).withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () async {
              // Mark messages as read when opening the chat
              await _markMessagesAsRead(chat.chatId);

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      donation: chat.donation,
                      shelterId: widget.userType == UserType.restaurant
                          ? chat.otherPartyId
                          : null,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return const Color.fromARGB(255, 34, 80, 36);
      case DonationStatus.reserved:
        return const Color.fromARGB(255, 137, 84, 4);
      case DonationStatus.completed:
        return Colors.blue;
      case DonationStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class ChatItem {
  final String chatId;
  final Donation donation;
  final String otherPartyName;
  final String otherPartyId;
  final String lastMessage;
  final Timestamp? lastMessageAt;

  ChatItem({
    required this.chatId,
    required this.donation,
    required this.otherPartyName,
    required this.otherPartyId,
    required this.lastMessage,
    required this.lastMessageAt,
  });
}
