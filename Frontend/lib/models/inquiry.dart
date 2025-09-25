class Inquiry {
  final String id;
  final String consumerId;
  final String farmerId;
  final String productId;
  final String message;
  final String status; // 'pending', 'replied', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? farmerName;
  final String? consumerName;
  final String? productName;
  final List<InquiryMessage> messages;

  Inquiry({
    required this.id,
    required this.consumerId,
    required this.farmerId,
    required this.productId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.farmerName,
    this.consumerName,
    this.productName,
    this.messages = const [],
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] ?? '',
      consumerId: json['consumerId'] ?? '',
      farmerId: json['farmerId'] ?? '',
      productId: json['productId'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      farmerName: json['farmerName'],
      consumerName: json['consumerName'],
      productName: json['productName'],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => InquiryMessage.fromJson(msg))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumerId': consumerId,
      'farmerId': farmerId,
      'productId': productId,
      'message': message,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'farmerName': farmerName,
      'consumerName': consumerName,
      'productName': productName,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  Inquiry copyWith({
    String? id,
    String? consumerId,
    String? farmerId,
    String? productId,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmerName,
    String? consumerName,
    String? productName,
    List<InquiryMessage>? messages,
  }) {
    return Inquiry(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      farmerId: farmerId ?? this.farmerId,
      productId: productId ?? this.productId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmerName: farmerName ?? this.farmerName,
      consumerName: consumerName ?? this.consumerName,
      productName: productName ?? this.productName,
      messages: messages ?? this.messages,
    );
  }
}

class InquiryMessage {
  final String id;
  final String inquiryId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromFarmer;
  final String? messageId;
  final String? imagePath;
  final bool isImage;

  InquiryMessage({
    required this.id,
    required this.inquiryId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromFarmer,
    this.messageId,
    this.imagePath,
    this.isImage = false,
  });

  factory InquiryMessage.fromJson(Map<String, dynamic> json) {
    return InquiryMessage(
      id: json['id'] ?? '',
      inquiryId: json['inquiryId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isFromFarmer: json['isFromFarmer'] ?? false,
      messageId: json['messageId'],
      imagePath: json['imagePath'],
      isImage: json['isImage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inquiryId': inquiryId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isFromFarmer': isFromFarmer,
      'messageId': messageId,
      'imagePath': imagePath,
      'isImage': isImage,
    };
  }
}
