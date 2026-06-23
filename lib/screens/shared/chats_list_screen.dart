import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/donation_service.dart';
import '../../services/profile_service.dart';
import '../shelter/chat_screen.dart';

class ChatListItem {
  final Chat chat;
  final String donationTitle;
  final String otherPartyName;
  ChatListItem({required this.chat, required this.donationTitle, required this.otherPartyName});
}

class ChatsListScreen extends StatefulWidget {
  final UserType userType;
  final Function(int)? onDrawerItemSelected;

  const ChatsListScreen({super.key, required this.userType, this.onDrawerItemSelected});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<ChatListItem> _chats = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadChats());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ChatService.listChats();
      final items = <ChatListItem>[];
      for (final chat in chats) {
        try {
          final donation = await DonationService.getDonation(chat.donationId);
          final String otherName;
          if (widget.userType == UserType.restaurant) {
            final shelter = await ProfileService.getShelter(chat.shelterId);
            otherName = shelter?.organizationName ?? 'Shelter';
          } else {
            final restaurant = await ProfileService.getRestaurant(chat.restaurantId);
            otherName = restaurant?.businessName ?? 'Restaurant';
          }
          items.add(ChatListItem(chat: chat, donationTitle: donation.title, otherPartyName: otherName));
        } catch (_) {
          continue;
        }
      }
      if (mounted) setState(() { _chats = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(ChatListItem item) async {
    try {
      await ChatService.markRead(item.chat.id);
    } catch (_) {}
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: item.chat.id,
      title: item.otherPartyName,
      donationTitle: item.donationTitle,
    )));
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(padding: const EdgeInsets.only(left: 15), child: Image.asset('lib/assets/transparent.png', width: 150, height: 150)),
        title: Text('Chats', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 22, color: cs.onSurface)),
        actions: [IconButton(onPressed: _loadChats, icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant), tooltip: 'Refresh')],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _chats.isEmpty
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
                          widget.userType == UserType.restaurant
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
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
                    itemBuilder: (context, i) => _chatTile(_chats[i]),
                  ),
                ),
    );
  }

  Widget _chatTile(ChatListItem item) {
    final cs = Theme.of(context).colorScheme;
    final diff = DateTime.now().difference(item.chat.lastMessageAt);
    final timeStr = diff.inDays > 0 ? '${diff.inDays}d' : diff.inHours > 0 ? '${diff.inHours}h' : diff.inMinutes > 0 ? '${diff.inMinutes}m' : 'now';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: cs.secondaryContainer,
        child: Icon(
          widget.userType == UserType.restaurant ? Icons.home_rounded : Icons.restaurant_rounded,
          color: cs.primary,
          size: 26,
        ),
      ),
      title: Row(children: [
        Expanded(child: Text(item.otherPartyName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.onSurfaceVariant)),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            item.chat.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            item.donationTitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      onTap: () => _openChat(item),
    );
  }
}
