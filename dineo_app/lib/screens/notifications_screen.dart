import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final notifications = await _apiService.getNotifications(_userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    await _apiService.markAllNotificationsAsRead(_userId);
    await _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await _apiService.deleteNotification(id);
    await _loadNotifications();
  }

  Future<void> _markAsRead(int id) async {
    await _apiService.markNotificationAsRead(id);
    await _loadNotifications();
  }

  String _formatDate(String dateStr) {
  // Adauga Z daca nu exista ca sa foreze UTC parsing
  final utcStr = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
  final date = DateTime.parse(utcStr).toLocal();
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  if (diff.inDays < 7) return "${diff.inDays}d ago";
  return "${date.day}/${date.month}/${date.year}";
}

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains("reservation") || t.contains("confirmed")) {
      return Icons.calendar_today;
    } else if (t.contains("offer") || t.contains("reward")) {
      return Icons.card_giftcard;
    } else if (t.contains("review") || t.contains("experience")) {
      return Icons.star;
    }
    return Icons.notifications;
  }

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: Image.asset('assets/images/logo.png', height: 30),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        "Mark all read",
                        style: TextStyle(
                            color: Color(0xFFB71C1C), fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFB71C1C)),
                ),
              )
            else if (_notifications.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.notifications_none,
                          color: Colors.grey, size: 60),
                      SizedBox(height: 15),
                      Text(
                        "No notifications yet",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "We'll notify you about reservations\nand special offers",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFFB71C1C),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['isRead'] == true;

                      return Dismissible(
                        key: Key(n['id'].toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            _deleteNotification(n['id'] as int),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!isRead) _markAsRead(n['id'] as int);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFF2A1A1A),
                              borderRadius: BorderRadius.circular(15),
                              border: isRead
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFB71C1C)
                                          .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRead
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFB71C1C)
                                            .withValues(alpha: 0.15),
                                  ),
                                  child: Icon(
                                    _getIcon(n['title'] ?? ''),
                                    color: isRead
                                        ? Colors.grey
                                        : const Color(0xFFB71C1C),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n['title'] ?? '',
                                              style: TextStyle(
                                                color: isRead
                                                    ? Colors.grey
                                                    : Colors.white,
                                                fontSize: 14,
                                                fontWeight: isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDate(
                                                n['createdAt'] ?? ''),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n['message'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(
                                        left: 8, top: 4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFB71C1C),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}