import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Chat list with enriched donation title + other party name.
/// autoDispose ensures provider re-fetches on navigation.
final chatsProvider = FutureProvider.autoDispose<List<Chat>>((ref) async {
  return ChatService.listChats();
});
