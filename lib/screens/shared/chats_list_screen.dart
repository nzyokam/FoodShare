import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/chats_provider.dart';
import '../../services/chat_service.dart';
import '../shelter/chat_screen.dart';

class ChatsListScreen extends ConsumerWidget {
  final UserType userType;
  final Function(int)? onDrawerItemSelected;

  const ChatsListScreen({super.key, required this.userType, this.onDrawerItemSelected});

  Future<void> _openChat(BuildContext context, WidgetRef ref, Chat chat) async {
    try {
      await ChatService.markRead(chat.id);
    } catch (_) {}
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          title: chat.otherPartyName ?? (userType == UserType.restaurant ? 'Shelter' : 'Restaurant'),
          donationTitle: chat.donationTitle ?? '',
        ),
      ),
    );
    ref.invalidate(chatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(padding: const EdgeInsets.only(left: 15), child: Image.asset('lib/assets/transparent.png', width: 150, height: 150)),
        title: Text('Chats', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 22, color: cs.onSurface)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(chatsProvider),
            icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: chatsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: cs.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.error))),
        data: (chats) => chats.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: cs.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No conversations yet', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Text(
                        userType == UserType.restaurant
                            ? 'Start chatting when shelters request your donations'
                            : 'Start chatting by requesting donations from restaurants',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: cs.primary,
                onRefresh: () async => ref.invalidate(chatsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
                  itemBuilder: (context, i) => _chatTile(context, ref, cs, chats[i]),
                ),
              ),
      ),
    );
  }

  Widget _chatTile(BuildContext context, WidgetRef ref, ColorScheme cs, Chat chat) {
    final diff = DateTime.now().difference(chat.lastMessageAt);
    final timeStr = diff.inDays > 0 ? '${diff.inDays}d' : diff.inHours > 0 ? '${diff.inHours}h' : diff.inMinutes > 0 ? '${diff.inMinutes}m' : 'now';
    final hasUnread = chat.unreadCount > 0;
    final otherName = chat.otherPartyName ?? (userType == UserType.restaurant ? 'Shelter' : 'Restaurant');
    final donationTitle = chat.donationTitle ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: cs.secondaryContainer,
        child: Icon(userType == UserType.restaurant ? Icons.home_rounded : Icons.restaurant_rounded, color: cs.primary, size: 26),
      ),
      title: Row(children: [
        Expanded(child: Text(otherName, style: GoogleFonts.plusJakartaSans(fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700, fontSize: 15, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.onSurfaceVariant)),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 3),
        Text(
          chat.lastMessage ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: hasUnread ? cs.onSurface : cs.onSurfaceVariant, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal),
        ),
        const SizedBox(height: 4),
        Text(donationTitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(
                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                style: GoogleFonts.plusJakartaSans(color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () => _openChat(context, ref, chat),
    );
  }
}
