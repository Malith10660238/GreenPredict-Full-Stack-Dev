import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import 'inquiry_chat_screen.dart';
import 'hidden_chats_screen.dart';

class ConsumerMessagesScreen extends StatefulWidget {
  const ConsumerMessagesScreen({super.key});

  @override
  State<ConsumerMessagesScreen> createState() => _ConsumerMessagesScreenState();
}

class _ConsumerMessagesScreenState extends State<ConsumerMessagesScreen> {
  final ApiService _apiService = ApiService();
  List<Inquiry> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      print('🔵 Loading consumer messages...');
      final data = await _apiService.getConsumerMessages(authProvider.authToken!);
      
      setState(() {
        _messages = data.map((item) => Inquiry.fromJson(item)).toList();
        _isLoading = false;
      });
      
      print('✅ Loaded ${_messages.length} messages');
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Search button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(),
            ),
          ),
          // Hidden messages button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.visibility_off, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HiddenChatsScreen(isFarmer: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with farmers by tapping "Chat with Farmer" on any product.',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageCard(message);
        },
      ),
    );
  }

  Widget _buildMessageCard(Inquiry message) {
    final statusColor = _getStatusColor(message.status);
    final statusText = _getStatusText(message.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openMessageChat(message),
        onLongPress: () => _showMessageOptions(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(
                      Icons.agriculture,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.farmerName ?? 'Farmer',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.productName != null)
                          Text(
                            'About: ${message.productName}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.message,
                style: AppTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    app_date.AppDateUtils.getRelativeTime(message.createdAt.toIso8601String()),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (message.messages.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${message.messages.length} messages',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'replied':
        return AppTheme.primaryGreen;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'replied':
        return 'Replied';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  void _openMessageChat(Inquiry message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryChatScreen(
          inquiry: message,
          isFarmer: false,
          onInquiryUpdated: (updatedInquiry) {
            // Update the message in the list
            setState(() {
              final index = _messages.indexWhere((m) => m.id == updatedInquiry.id);
              if (index != -1) {
                _messages[index] = updatedInquiry;
              }
            });
          },
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by farmer name or product...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // TODO: Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Searching... (Feature coming soon)'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                _filterByStatus('pending');
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Replied'),
              onTap: () {
                Navigator.pop(context);
                _filterByStatus('replied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Closed'),
              onTap: () {
                Navigator.pop(context);
                _filterByStatus('closed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear Filter'),
              onTap: () {
                Navigator.pop(context);
                _clearFilter();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _filterByStatus(String status) {
    // TODO: Implement filtering logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtering by $status (Feature coming soon)'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _clearFilter() {
    // TODO: Implement clear filter logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter cleared'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'delete_all':
        _deleteAllMessages();
        break;
      case 'export':
        _exportMessages();
        break;
    }
  }

  void _markAllAsRead() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text('Are you sure you want to mark all messages as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All messages marked as read (Feature coming soon)'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark All'),
          ),
        ],
      ),
    );
  }

  void _deleteAllMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Messages'),
        content: const Text('Are you sure you want to delete all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete all messages
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All messages deleted (Feature coming soon)'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _exportMessages() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting messages... (Feature coming soon)'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showMessageOptions(Inquiry message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.orange),
              title: const Text('Hide Chat', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _showHideMessageDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block Farmer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showBlockFarmerDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showMessageDetails(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHideMessageDialog(Inquiry message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide Chat'),
        content: Text(
          'Are you sure you want to hide this chat with ${message.farmerName ?? 'this farmer'}? You can unhide it later from your settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _hideMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hide Chat'),
          ),
        ],
      ),
    );
  }

  void _hideMessage(Inquiry message) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      await _apiService.hideChat(
        inquiryId: message.id,
        token: authProvider.authToken!,
      );
      
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat hidden successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to hide chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBlockFarmerDialog(Inquiry message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Farmer'),
        content: Text(
          'Are you sure you want to block ${message.farmerName ?? 'this farmer'}? You won\'t be able to send messages to them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement blocking functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Farmer blocked (Feature coming soon)'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(Inquiry message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Farmer', message.farmerName ?? 'Unknown'),
            _buildDetailRow('Product', message.productName ?? 'Unknown'),
            _buildDetailRow('Status', message.status.toUpperCase()),
            _buildDetailRow('Created', app_date.AppDateUtils.getRelativeTime(message.createdAt.toIso8601String())),
            _buildDetailRow('Messages', '${message.messages.length} messages'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
