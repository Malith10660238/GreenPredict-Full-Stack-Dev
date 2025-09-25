import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import 'inquiry_chat_screen.dart';
import 'hidden_chats_screen.dart';

class FarmerInquiriesScreen extends StatefulWidget {
  const FarmerInquiriesScreen({super.key});

  @override
  State<FarmerInquiriesScreen> createState() => _FarmerInquiriesScreenState();
}

class _FarmerInquiriesScreenState extends State<FarmerInquiriesScreen> {
  final ApiService _apiService = ApiService();
  List<Inquiry> _inquiries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      print('🔵 Loading farmer inquiries...');
      final data = await _apiService.getFarmerInquiries(authProvider.authToken!);
      
      setState(() {
        _inquiries = data.map((item) => Inquiry.fromJson(item)).toList();
        _isLoading = false;
      });
      
      print('✅ Loaded ${_inquiries.length} inquiries');
    } catch (e) {
      print('❌ Error loading inquiries: $e');
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
        title: const Text('Inquiries'),
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
                    builder: (context) => const HiddenChatsScreen(isFarmer: true),
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
              'Failed to load inquiries',
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
              onPressed: _loadInquiries,
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

    if (_inquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Inquiries Yet',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see customer inquiries here when they contact you about your products.',
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
      onRefresh: _loadInquiries,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inquiries.length,
        itemBuilder: (context, index) {
          final inquiry = _inquiries[index];
          return _buildInquiryCard(inquiry);
        },
      ),
    );
  }

  Widget _buildInquiryCard(Inquiry inquiry) {
    final statusColor = _getStatusColor(inquiry.status);
    final statusText = _getStatusText(inquiry.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openInquiryChat(inquiry),
        onLongPress: () => _showInquiryOptions(inquiry),
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
                      Icons.person,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inquiry.consumerName ?? 'Customer',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (inquiry.productName != null)
                          Text(
                            'About: ${inquiry.productName}',
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
                inquiry.message,
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
                    app_date.AppDateUtils.getRelativeTime(inquiry.createdAt.toIso8601String()),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (inquiry.messages.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${inquiry.messages.length} messages',
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

  void _openInquiryChat(Inquiry inquiry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryChatScreen(
          inquiry: inquiry,
          isFarmer: true,
          onInquiryUpdated: (updatedInquiry) {
            // Update the inquiry in the list
            setState(() {
              final index = _inquiries.indexWhere((i) => i.id == updatedInquiry.id);
              if (index != -1) {
                _inquiries[index] = updatedInquiry;
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
        title: const Text('Search Inquiries'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by customer name, product, or message...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ],
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
            },
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
        title: const Text('Filter Inquiries'),
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
      case 'mark_all_replied':
        _markAllAsReplied();
        break;
      case 'close_all':
        _closeAllInquiries();
        break;
      case 'export':
        _exportInquiries();
        break;
    }
  }

  void _markAllAsReplied() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Replied'),
        content: const Text('Are you sure you want to mark all inquiries as replied?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement mark all as replied
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All inquiries marked as replied (Feature coming soon)'),
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

  void _closeAllInquiries() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close All Inquiries'),
        content: const Text('Are you sure you want to close all inquiries? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement close all inquiries
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All inquiries closed (Feature coming soon)'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close All'),
          ),
        ],
      ),
    );
  }

  void _exportInquiries() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting inquiries... (Feature coming soon)'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showInquiryOptions(Inquiry inquiry) {
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
                _showHideInquiryDialog(inquiry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showBlockUserDialog(inquiry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showInquiryDetails(inquiry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHideInquiryDialog(Inquiry inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide Chat'),
        content: Text(
          'Are you sure you want to hide this chat with ${inquiry.consumerName ?? 'this customer'}? You can unhide it later from your settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _hideInquiry(inquiry);
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

  void _hideInquiry(Inquiry inquiry) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      await _apiService.hideChat(
        inquiryId: inquiry.id,
        token: authProvider.authToken!,
      );
      
      setState(() {
        _inquiries.removeWhere((i) => i.id == inquiry.id);
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

  void _showBlockUserDialog(Inquiry inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${inquiry.consumerName ?? 'this customer'}? You won\'t be able to receive messages from them.',
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
                  content: Text('User blocked (Feature coming soon)'),
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

  void _showInquiryDetails(Inquiry inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inquiry Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Customer', inquiry.consumerName ?? 'Unknown'),
            _buildDetailRow('Product', inquiry.productName ?? 'Unknown'),
            _buildDetailRow('Status', inquiry.status.toUpperCase()),
            _buildDetailRow('Created', app_date.AppDateUtils.getRelativeTime(inquiry.createdAt.toIso8601String())),
            _buildDetailRow('Messages', '${inquiry.messages.length} messages'),
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
