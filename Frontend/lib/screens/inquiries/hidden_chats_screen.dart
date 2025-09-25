import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import 'inquiry_chat_screen.dart';

class HiddenChatsScreen extends StatefulWidget {
  final bool isFarmer;
  
  const HiddenChatsScreen({
    super.key,
    required this.isFarmer,
  });

  @override
  State<HiddenChatsScreen> createState() => _HiddenChatsScreenState();
}

class _HiddenChatsScreenState extends State<HiddenChatsScreen> {
  final ApiService _apiService = ApiService();
  List<Inquiry> _hiddenChats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHiddenChats();
  }

  Future<void> _loadHiddenChats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      print('🔵 Loading hidden chats...');
      final data = await _apiService.getHiddenChats(authProvider.authToken!);
      
      setState(() {
        _hiddenChats = data.map((item) => Inquiry.fromJson(item)).toList();
        _isLoading = false;
      });
      
      print('✅ Loaded ${_hiddenChats.length} hidden chats');
    } catch (e) {
      print('❌ Error loading hidden chats: $e');
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
        title: Text(widget.isFarmer ? 'Hidden Inquiries' : 'Hidden Messages'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHiddenChats,
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
              'Failed to load hidden chats',
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
              onPressed: _loadHiddenChats,
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

    if (_hiddenChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Hidden Chats',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isFarmer
                  ? 'You haven\'t hidden any inquiries yet.'
                  : 'You haven\'t hidden any messages yet.',
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
      onRefresh: _loadHiddenChats,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hiddenChats.length,
        itemBuilder: (context, index) {
          final chat = _hiddenChats[index];
          return _buildHiddenChatCard(chat);
        },
      ),
    );
  }

  Widget _buildHiddenChatCard(Inquiry chat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openHiddenChat(chat),
        onLongPress: () => _showChatOptions(chat),
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
                      widget.isFarmer ? Icons.person : Icons.agriculture,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isFarmer 
                              ? (chat.consumerName ?? 'Customer')
                              : (chat.farmerName ?? 'Farmer'),
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (chat.productName != null)
                          Text(
                            'About: ${chat.productName}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Hidden indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hidden',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                chat.message,
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
                    app_date.AppDateUtils.getRelativeTime(chat.createdAt.toIso8601String()),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (chat.messages.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${chat.messages.length} messages',
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

  void _openHiddenChat(Inquiry chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryChatScreen(
          inquiry: chat,
          isFarmer: widget.isFarmer,
          onInquiryUpdated: (updatedInquiry) {
            // Update the chat in the list
            setState(() {
              final index = _hiddenChats.indexWhere((c) => c.id == updatedInquiry.id);
              if (index != -1) {
                _hiddenChats[index] = updatedInquiry;
              }
            });
          },
        ),
      ),
    );
  }

  void _showChatOptions(Inquiry chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.primaryGreen),
              title: const Text('Unhide Chat', style: TextStyle(color: AppTheme.primaryGreen)),
              onTap: () {
                Navigator.pop(context);
                _showUnhideDialog(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showChatDetails(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUnhideDialog(Inquiry chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unhide Chat'),
        content: Text(
          'Are you sure you want to unhide this chat with ${widget.isFarmer ? chat.consumerName ?? 'this customer' : chat.farmerName ?? 'this farmer'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unhideChat(chat);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unhide'),
          ),
        ],
      ),
    );
  }

  void _unhideChat(Inquiry chat) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      await _apiService.unhideChat(
        inquiryId: chat.id,
        token: authProvider.authToken!,
      );
      
      setState(() {
        _hiddenChats.removeWhere((c) => c.id == chat.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat unhidden successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unhide chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChatDetails(Inquiry chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              widget.isFarmer ? 'Customer' : 'Farmer', 
              widget.isFarmer ? (chat.consumerName ?? 'Unknown') : (chat.farmerName ?? 'Unknown')
            ),
            _buildDetailRow('Product', chat.productName ?? 'Unknown'),
            _buildDetailRow('Status', chat.status.toUpperCase()),
            _buildDetailRow('Created', app_date.AppDateUtils.getRelativeTime(chat.createdAt.toIso8601String())),
            _buildDetailRow('Messages', '${chat.messages.length} messages'),
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
