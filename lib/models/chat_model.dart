class Chat {
  final String id;
  final String donationId;
  final String restaurantId;
  final String shelterId;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.donationId,
    required this.restaurantId,
    required this.shelterId,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      donationId: json['donation_id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      shelterId: json['shelter_id'] ?? '',
      lastMessage: json['last_message'],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final bool read;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.read,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      text: json['text'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
