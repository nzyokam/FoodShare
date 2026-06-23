import 'dart:async';
import 'dart:convert';
import 'api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  static Future<List<Chat>> listChats() async {
    final res = await ApiClient.get('/chats');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => Chat.fromJson(j)).toList();
  }

  /// Shelter calls this to open (or fetch existing) chat for a donation.
  static Future<Chat> getOrCreateChat(String donationId) async {
    final res = await ApiClient.post('/chats', body: {'donation_id': donationId});
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

  /// Returns a subscription that polls messages every [interval].
  /// Cancel the subscription in dispose() to stop polling.
  static StreamSubscription<List<ChatMessage>> pollMessages(
    String chatId, {
    required void Function(List<ChatMessage>) onData,
    Duration interval = const Duration(seconds: 3),
  }) {
    final controller = StreamController<List<ChatMessage>>();
    Timer? timer;

    Future<void> fetch() async {
      try {
        final messages = await listMessages(chatId);
        if (!controller.isClosed) controller.add(messages);
      } catch (_) {}
    }

    fetch(); // immediate first fetch
    timer = Timer.periodic(interval, (_) => fetch());

    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };
    return controller.stream.listen(onData);
  }
}
