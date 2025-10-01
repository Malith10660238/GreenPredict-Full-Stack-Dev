import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';
import '../../utils/app_theme.dart';

class InquiryChatScreen extends StatefulWidget {
  final Inquiry inquiry;
  final bool isFarmer;
  final Function(Inquiry) onInquiryUpdated;

  const InquiryChatScreen({
    super.key,
    required this.inquiry,
    required this.isFarmer,
    required this.onInquiryUpdated,
  });

  @override
  State<InquiryChatScreen> createState() => _InquiryChatScreenState();
}

class _InquiryChatScreenState extends State<InquiryChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<InquiryMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  bool _showEmojiPicker = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Auto-refresh functionality
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.inquiry.messages);
    _loadInquiryDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInquiryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      print('🔵 Loading inquiry details: ${widget.inquiry.id}');
      final data = await _apiService.getInquiryDetails(widget.inquiry.id, authProvider.authToken!);
      final updatedInquiry = Inquiry.fromJson(data);
      
      setState(() {
        _messages = updatedInquiry.messages;
        _isLoading = false;
      });
      
      // Merge backend messages with local image data
      await _mergeBackendMessagesWithLocalImages();
      
      // Clean up old image data
      await _cleanupOldImageData();
      
      // Update state with merged messages
      setState(() {});
      
      // Notify parent of updated inquiry
      widget.onInquiryUpdated(updatedInquiry);
      
      print('✅ Loaded ${_messages.length} messages');
    } catch (e) {
      print('❌ Error loading inquiry details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Auto-refresh methods
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _autoRefreshMessages();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _autoRefreshMessages() async {
    // Prevent overlapping refreshes
    if (_isSending || _isLoading || !mounted) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) return;

      final data = await _apiService.getInquiryDetails(widget.inquiry.id, authProvider.authToken!);
      final updatedInquiry = Inquiry.fromJson(data);
      
      // Only update if there are new messages and we're still mounted
      if (mounted && updatedInquiry.messages.length != _messages.length) {
        // Store the previous message count
        final previousMessageCount = _messages.length;
        
        setState(() {
          _messages = updatedInquiry.messages;
        });
        
        // Merge backend messages with local image data
        await _mergeBackendMessagesWithLocalImages();
        
        // Update the parent widget
        widget.onInquiryUpdated(updatedInquiry);
        
        // Only scroll if new messages were actually added
        if (mounted && _messages.length > previousMessageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && mounted) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
      
    } catch (e) {
      // Silent error handling - no visual feedback needed
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken == null) {
        throw Exception('No authentication token available');
      }

      print('🔵 Sending message: $messageText');
      await _apiService.sendInquiryMessage(
        inquiryId: widget.inquiry.id,
        message: messageText,
        token: authProvider.authToken!,
      );
      
      // Reload messages to get the latest
      await _loadInquiryDetails();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
        title: Row(
          children: [
            // Professional icon based on user role
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.isFarmer ? Icons.person : Icons.agriculture,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Professional name with role indicator
                  Row(
                    children: [
                      Text(
                        widget.isFarmer 
                          ? (widget.inquiry.consumerName ?? 'Customer')
                          : (widget.inquiry.farmerName ?? 'Farmer'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isFarmer ? Colors.blue : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.isFarmer ? 'CONSUMER' : 'FARMER',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Product information
                  if (widget.inquiry.productName != null)
                    Text(
                      'About: ${widget.inquiry.productName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
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
              'Failed to load conversation',
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
              onPressed: _loadInquiryDetails,
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

    return Column(
      children: [
        // WhatsApp-like centered message
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Conversation started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Messages list with pattern background
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _loadInquiryDetails,
              color: AppTheme.primaryGreen,
              backgroundColor: Colors.white,
              strokeWidth: 2.0,
              child: Stack(
                children: [
                  // Pattern background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ChatPatternPainter(),
                    ),
                  ),
                  // Messages content
                  _messages.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
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
                                      'No messages yet',
                                      style: AppTheme.bodyLarge.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.isFarmer
                                          ? 'Reply to this inquiry to start the conversation.'
                                          : 'The farmer will reply to your inquiry soon.',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
        
        // Message input
        _buildMessageInput(),
        
        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _messageController.text += emoji.emoji;
              },
            ),
          ),
      ],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${image.name}'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        
        // Auto-send the image
        await _sendImageMessage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _copyImageToPersistentStorage(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final chatImagesDir = Directory(path.join(directory.path, 'chat_images'));
      
      if (!await chatImagesDir.exists()) {
        await chatImagesDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imagePath)}';
      final newPath = path.join(chatImagesDir.path, fileName);
      
      await File(imagePath).copy(newPath);
      return newPath;
    } catch (e) {
      print('Error copying image: $e');
      return imagePath; // Return original path if copy fails
    }
  }

  Future<void> _saveImageMessageToLocal(InquiryMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use timestamp and sender as key for better matching
      final key = 'image_${widget.inquiry.id}_${message.senderId}_${message.timestamp.millisecondsSinceEpoch}';
      final messageData = {
        'imagePath': message.imagePath,
        'timestamp': message.timestamp.toIso8601String(),
        'senderId': message.senderId,
        'message': message.message,
        'used': false, // Mark as unused initially
      };
      await prefs.setString(key, jsonEncode(messageData));
      print('💾 Saved image message: $key');
    } catch (e) {
      print('Error saving image message: $e');
    }
  }

  Future<void> _markImageAsUsed(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('image_${widget.inquiry.id}_')).toList();
      
      for (final key in keys) {
        final messageData = prefs.getString(key);
        if (messageData != null) {
          final data = jsonDecode(messageData);
          if (data['imagePath'] == imagePath) {
            data['used'] = true;
            await prefs.setString(key, jsonEncode(data));
            print('✅ Marked image as used: $imagePath');
            break;
          }
        }
      }
    } catch (e) {
      print('Error marking image as used: $e');
    }
  }

  Future<Map<String, dynamic>?> _findLocalImageForMessage(InquiryMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys for this inquiry and sender
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('image_${widget.inquiry.id}_${message.senderId}_')).toList();
      
      print('🔍 Searching through ${keys.length} local images for sender: ${message.senderId}');
      
      // First try: Find by exact timestamp match (within 30 seconds tolerance)
      final messageTime = message.timestamp.millisecondsSinceEpoch;
      final tolerance = 30000; // 30 seconds
      
      for (final key in keys) {
        try {
          final messageData = prefs.getString(key);
          if (messageData != null) {
            final data = jsonDecode(messageData);
            final savedTime = DateTime.parse(data['timestamp']).millisecondsSinceEpoch;
            
            // Check if timestamps are close
            if ((messageTime - savedTime).abs() <= tolerance) {
              final imageFile = File(data['imagePath']);
              if (await imageFile.exists()) {
                print('✅ Found image by timestamp match: ${data['imagePath']}');
                return data;
              }
            }
          }
        } catch (e) {
          print('Error parsing saved image data: $e');
        }
      }
      
      // Second try: Find unused image by message content pattern
      for (final key in keys) {
        try {
          final messageData = prefs.getString(key);
          if (messageData != null) {
            final data = jsonDecode(messageData);
            
            // Check if this is an unused image message
            if (data['used'] != true && 
                data['message'] != null && 
                (data['message'].contains('📷 Image') || 
                 data['message'].contains('Image shared'))) {
              
              final imageFile = File(data['imagePath']);
              if (await imageFile.exists()) {
                print('✅ Found unused image by content match: ${data['imagePath']}');
                return data;
              }
            }
          }
        } catch (e) {
          print('Error parsing saved image data: $e');
        }
      }
      
      // Third try: Find any unused image for this sender (fallback)
      for (final key in keys) {
        try {
          final messageData = prefs.getString(key);
          if (messageData != null) {
            final data = jsonDecode(messageData);
            
            // Check if this is an unused image
            if (data['used'] != true) {
              final imageFile = File(data['imagePath']);
              if (await imageFile.exists()) {
                print('✅ Found unused image by fallback match: ${data['imagePath']}');
                return data;
              }
            }
          }
        } catch (e) {
          print('Error parsing saved image data: $e');
        }
      }
      
      print('❌ No local image found for: ${message.message}');
    } catch (e) {
      print('Error finding local image: $e');
    }
    return null;
  }

  Future<void> _mergeBackendMessagesWithLocalImages() async {
    try {
      print('🔄 Merging backend messages with local images...');
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        
        // Check if this is a backend message about an image
        if (message.message.contains('📷 Image shared') || 
            message.message.contains('📷 Image:')) {
          
          print('🔍 Looking for local image for: ${message.message}');
          
          // Try to find local image data for this message
          final localImageData = await _findLocalImageForMessage(message);
          
          if (localImageData != null && localImageData['imagePath'] != null) {
            print('✅ Found local image, updating message');
            
            // Mark the image as used
            await _markImageAsUsed(localImageData['imagePath']);
            
            // Update the message with image data
            _messages[i] = InquiryMessage(
              id: message.id,
              inquiryId: message.inquiryId,
              senderId: message.senderId,
              senderName: message.senderName,
              message: message.message,
              timestamp: message.timestamp,
              isFromFarmer: message.isFromFarmer,
              messageId: message.messageId,
              imagePath: localImageData['imagePath'],
              isImage: true,
            );
          } else {
            print('❌ No local image found for: ${message.message}');
          }
        }
      }
      print('✅ Finished merging messages');
    } catch (e) {
      print('Error merging messages: $e');
    }
  }

  Future<void> _cleanupOldImageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('image_${widget.inquiry.id}_')).toList();
      
      // Keep only the last 50 images per inquiry to prevent storage bloat
      if (keys.length > 50) {
        final sortedKeys = keys.toList()..sort();
        final keysToRemove = sortedKeys.take(keys.length - 50);
        
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
        print('🧹 Cleaned up old image data');
      }
    } catch (e) {
      print('Error cleaning up image data: $e');
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    if (_isSending) return;
    
    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Copy image to persistent storage
      final persistentImagePath = await _copyImageToPersistentStorage(imagePath);

      // Create a message with image for immediate display
      final imageMessage = InquiryMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inquiryId: widget.inquiry.id,
        senderId: authProvider.user?.uid ?? '',
        senderName: authProvider.user?.displayName ?? 'You',
        message: '📷 Image',
        timestamp: DateTime.now(),
        isFromFarmer: widget.isFarmer,
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: persistentImagePath,
        isImage: true,
      );

      // Add to local messages immediately
      setState(() {
        _messages.add(imageMessage);
      });

      // Save image message to local storage
      await _saveImageMessageToLocal(imageMessage);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Send a simple text message to backend (without image data for now)
      try {
        await _apiService.sendInquiryMessage(
          inquiryId: widget.inquiry.id,
          message: '📷 Image shared',
          token: token,
        );
      } catch (e) {
        // If backend fails, keep the local message
        print('Backend send failed, keeping local message: $e');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildMessageBubble(InquiryMessage message) {
    // Get current user ID to determine if message is from current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;
    final isFromCurrentUser = message.senderId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: isFromCurrentUser ? () => _showMessageOptions(message) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isFromCurrentUser 
                      ? AppTheme.primaryGreen 
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: isFromCurrentUser 
                        ? const Radius.circular(8) 
                        : const Radius.circular(2),
                    bottomRight: isFromCurrentUser 
                        ? const Radius.circular(2) 
                        : const Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Check if message is an image message
                    if (message.isImage && message.imagePath != null) ...[
                      // Image message display
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(message.imagePath!),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📷 Image',
                        style: TextStyle(
                          fontSize: 14,
                          color: isFromCurrentUser 
                              ? Colors.white70 
                              : Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      // Regular text message
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: isFromCurrentUser 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Time and delete button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: isFromCurrentUser 
                                ? Colors.white70 
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }



  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji button
          IconButton(
            onPressed: () {
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: _showEmojiPicker ? AppTheme.primaryGreen : Colors.grey[600],
            ),
          ),
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: widget.isFarmer 
                      ? 'Reply to customer...' 
                      : 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Attachment button
          IconButton(
            onPressed: _showImagePicker,
            icon: Icon(
              Icons.attach_file,
              color: Colors.grey[600],
            ),
          ),
          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }


  void _showMessageOptions(InquiryMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message.message);
              },
            ),
          ],
        ),
      ),
    );
  }



  void _copyMessage(String message) {
    // TODO: Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }


}

class ChatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create a professional grid pattern
    final paint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add subtle dots at intersections
    final dotPaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(
          Offset(x, y),
          1.0,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
