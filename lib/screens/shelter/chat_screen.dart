// screens/shared/chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/donation_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/shelter_model.dart';

class ChatScreen extends StatefulWidget {
  final Donation donation;
  final String? shelterId; // Add this parameter to specify which shelter

  const ChatScreen({
    super.key, 
    required this.donation,
    this.shelterId, // Optional - can be inferred from current user
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final String chatId;
  late final String currentUserId;
  late final String restaurantId;
  late final String shelterId;
  
  Restaurant? _restaurant;
  Shelter? _shelter;
  bool _isCurrentUserRestaurant = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    restaurantId = widget.donation.donorId;
    
    // Determine if current user is restaurant
    _isCurrentUserRestaurant = currentUserId == restaurantId;
    
    // Set shelter ID
    if (_isCurrentUserRestaurant) {
      // Current user is restaurant, shelter ID should be provided or inferred
      shelterId = widget.shelterId ?? '';
      if (shelterId.isEmpty) {
        // If no shelter ID provided, we need to find it from recent requests
        _findShelterIdFromRecentRequest();
        return;
      }
    } else {
      // Current user is shelter
      shelterId = currentUserId;
    }
    
    chatId = _getChatId(restaurantId, shelterId);
    _loadUserData();
    _createChatDocument();
  }

  // Find shelter ID from recent requests if not provided
  Future<void> _findShelterIdFromRecentRequest() async {
    try {
      final requestsQuery = await FirebaseFirestore.instance
          .collection('requests')
          .where('donationId', isEqualTo: widget.donation.id)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (requestsQuery.docs.isNotEmpty) {
        final requestData = requestsQuery.docs.first.data();
        final foundShelterId = requestData['shelterId'] as String;
        
        setState(() {
          // Update the shelter ID and initialize chat
        });
        
        // Reinitialize with found shelter ID
        _initializeWithShelter(foundShelterId);
      }
    } catch (e) {
      print('Error finding shelter ID: $e');
    }
  }
  
  void _initializeWithShelter(String foundShelterId) {
    setState(() {
      shelterId = foundShelterId;
      chatId = _getChatId(restaurantId, shelterId);
    });
    _loadUserData();
    _createChatDocument();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId(String restaurantId, String shelterId) {
    // Ensure consistent chat ID regardless of who initiates
    // Use sorted IDs to ensure consistency
    final sortedIds = [restaurantId, shelterId]..sort();
    return 'donation_${widget.donation.id}_${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> _loadUserData() async {
    try {
      // Always load restaurant data
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      
      // Always load shelter data  
      final shelterDoc = await FirebaseFirestore.instance
          .collection('shelters')
          .doc(shelterId)
          .get();

      if (restaurantDoc.exists && shelterDoc.exists) {
        setState(() {
          _restaurant = Restaurant.fromJson(restaurantDoc.data()!);
          _shelter = Shelter.fromJson(shelterDoc.data()!);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _createChatDocument() async {
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          'donationId': widget.donation.id,
          'restaurantId': restaurantId,
          'shelterId': shelterId,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating chat document: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      // Add message to subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update chat document with last message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if we don't have shelter ID yet (for restaurants)
    if (_isCurrentUserRestaurant && shelterId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Donation Info Header
          _buildDonationHeader(),
          
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
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
                          'Start the conversation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to discuss this donation',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    
                    return _buildMessageBubble(messageData);
                  },
                );
              },
            ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = 'Chat';
    String subtitle = '';

    if (_restaurant != null && !_isCurrentUserRestaurant) {
      title = _restaurant!.businessName;
      subtitle = 'Restaurant';
    } else if (_shelter != null && _isCurrentUserRestaurant) {
      title = _shelter!.organizationName;
      subtitle = 'Shelter';
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Show donation details or other options
          },
          icon: const Icon(Icons.info_outline),
        ),
      ],
    );
  }

  Widget _buildDonationHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.donation.imageUrls.isNotEmpty
                ? Image.network(
                    widget.donation.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.donation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.donation.quantity} ${widget.donation.unit}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${widget.donation.expiryDate.toDate().day}/${widget.donation.expiryDate.toDate().month}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.donation.status).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.donation.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor(widget.donation.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final isMe = messageData['senderId'] == currentUserId;
    final timestamp = messageData['timestamp'] as Timestamp?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32).withAlpha(20),
              child: Icon(
                _isCurrentUserRestaurant ? Icons.home : Icons.restaurant,
                size: 16,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFF2E7D32)
                    : Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messageData['text'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(timestamp.toDate()),
                      style: TextStyle(
                        color: isMe 
                            ? Colors.white.withAlpha(180)
                            : Theme.of(context).colorScheme.onSurface.withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32).withAlpha(20),
              child: Icon(
                _isCurrentUserRestaurant ? Icons.restaurant : Icons.home,
                size: 16,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(10),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return Colors.green;
      case DonationStatus.reserved:
        return Colors.orange;
      case DonationStatus.completed:
        return Colors.blue;
      case DonationStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}