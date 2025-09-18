import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

// Models are at the bottom of the file

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // --- REMOVED: No longer need a GlobalKey for AnimatedList ---
  // final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Inquiries', 'System', 'Orders'];
  
  final List<NotificationItem> _allNotifications = [
     NotificationItem(id: '1', type: NotificationType.inquiry, title: 'New Product Inquiry', message: 'Sarah Johnson is interested in your organic tomatoes. Tap to chat.', time: '2 minutes ago', isRead: false, avatar: 'SJ'),
     NotificationItem(id: '2', type: NotificationType.system, title: 'Weather Alert', message: 'Heavy rain expected in Pannipitiya tomorrow. Protect your crops.', time: '1 hour ago', isRead: false, icon: Icons.cloudy_snowing),
     NotificationItem(id: '3', type: NotificationType.order, title: 'Order Confirmed', message: 'Your order of fresh vegetables from Galle has been confirmed.', time: '2 hours ago', isRead: true, icon: Icons.check_circle),
     NotificationItem(id: '4', type: NotificationType.inquiry, title: 'Chat Message', message: 'Mike Chen: "Are these pesticide-free vegetables?"', time: '3 hours ago', isRead: true, avatar: 'MC'),
     NotificationItem(id: '5', type: NotificationType.system, title: 'AI Analysis Complete', message: 'Your crop prediction analysis is ready. Check results now.', time: '1 day ago', isRead: true, icon: Icons.psychology),
  ];

  List<NotificationItem> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _filterNotifications();
  }

  void _filterNotifications() {
    setState(() {
      if (_selectedTab == 0) {
        _filteredNotifications = List.from(_allNotifications);
      } else {
        NotificationType? filterType;
        switch (_selectedTab) {
          case 1: filterType = NotificationType.inquiry; break;
          case 2: filterType = NotificationType.system; break;
          case 3: filterType = NotificationType.order; break;
        }
        _filteredNotifications = _allNotifications.where((n) => n.type == filterType).toList();
      }
    });
  }

  bool get _hasUnreadNotifications => _allNotifications.any((n) => !n.isRead);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.lightGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTheme.heading2),
        actions: [
          TextButton(
            onPressed: _hasUnreadNotifications ? _markAllAsRead : null,
            child: Text(
              'Mark all read',
              style: AppTheme.bodyMedium.copyWith(
                color: _hasUnreadNotifications ? AppTheme.primaryGreen : AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                // --- MODIFIED: Replaced AnimatedList with ListView.builder ---
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
                _filterNotifications();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppTheme.darkGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    // --- MODIFIED: Wrapper is now just the Dismissible widget ---
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(notification),
      background: Container(
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.transparent : AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: notification.avatar != null
                        ? Center(child: Text(notification.avatar!, style: AppTheme.bodyLarge.copyWith(color: _getNotificationColor(notification.type), fontWeight: FontWeight.bold)))
                        : Icon(notification.icon, color: _getNotificationColor(notification.type), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.title, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(notification.message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray)),
                        const SizedBox(height: 8),
                        Text(notification.time, style: AppTheme.caption.copyWith(color: AppTheme.darkGray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 80, color: AppTheme.mediumGray),
          const SizedBox(height: 20),
          Text('No notifications here', style: AppTheme.heading3.copyWith(color: AppTheme.darkGray)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'When you have new updates, they\'ll appear in this tab.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  // --- MODIFIED: Simplified remove logic ---
  void _removeItem(NotificationItem notification) {
    final originalIndexInAll = _allNotifications.indexOf(notification);
    
    setState(() {
      _allNotifications.remove(notification);
      _filterNotifications();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notification dismissed"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () => _undoRemoveItem(notification, originalIndexInAll),
        ),
      ),
    );
  }

  void _undoRemoveItem(NotificationItem item, int originalIndex) {
    setState(() {
      _allNotifications.insert(originalIndex, item);
      _filterNotifications();
    });
  }

  void _handleNotificationTap(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification.isRead = true;
      }
    });
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.inquiry: return AppTheme.primaryGreen;
      case NotificationType.system: return Colors.blue.shade600;
      case NotificationType.order: return Colors.orange.shade700;
    }
  }
}

// Models
enum NotificationType { inquiry, system, order }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  bool isRead;
  final String? avatar;
  final IconData? icon;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    this.avatar,
    this.icon,
  });
}