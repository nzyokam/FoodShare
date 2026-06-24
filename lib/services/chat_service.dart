import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';
import '../config/app_config.dart';
import '../models/chat_model.dart';

class ChatService {
  static Future<List<Chat>> listChats() async {
    final res = await ApiClient.get('/chats');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => Chat.fromJson(j)).toList();
  }

  /// Opens or creates a chat for a donation.
  /// [shelterId] is required when called by a restaurant to initiate a new chat.
  static Future<Chat> getOrCreateChat(String donationId, {String? shelterId}) async {
    final body = <String, dynamic>{'donation_id': donationId};
    if (shelterId != null) body['shelter_id'] = shelterId;
    final res = await ApiClient.post('/chats', body: body);
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return Chat.fromJson(jsonDecode(res.body));
  }

  static Future<List<ChatMessage>> listMessages(
    String chatId, {
    String? before,
    int limit = 30,
  }) async {
    final res = await ApiClient.get('/chats/$chatId/messages', query: {
      if (before != null) 'before': before,
      'limit': limit.toString(),
    });
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => ChatMessage.fromJson(j)).toList();
  }

  static Future<ChatMessage> sendMessage(String chatId, String text) async {
    final res = await ApiClient.post('/chats/$chatId/messages', body: {'text': text});
    if (res.statusCode != 201) throw Exception(ApiClient.errorMessage(res));
    return ChatMessage.fromJson(jsonDecode(res.body));
  }

  static Future<void> markRead(String chatId) async {
    await ApiClient.patch('/chats/$chatId/read');
  }

  /// Opens a WebSocket connection to receive new messages in real-time.
  /// [token] is the JWT access token.
  /// [onMessage] is called for each incoming message from the other participant.
  /// Returns the channel — call channel.sink.close() to disconnect.
  static WebSocketChannel connectToChat(
    String chatId,
    String token,
    void Function(ChatMessage) onMessage,
  ) {
    final wsBase = AppConfig.apiUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsBase/chats/$chatId/ws?token=${Uri.encodeComponent(token)}');
    final channel = WebSocketChannel.connect(uri);
    channel.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          onMessage(ChatMessage.fromJson(json));
        } catch (_) {}
      },
      onError: (_) {},
      cancelOnError: false,
    );
    return channel;
  }
}
