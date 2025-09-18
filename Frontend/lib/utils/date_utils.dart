import 'package:intl/intl.dart';

class AppDateUtils {
  /// Format a date string to relative time (e.g., "2 days ago", "3 hours ago")
  static String getRelativeTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown';
    }

    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        if (difference.inDays == 1) {
          return '1 day ago';
        } else if (difference.inDays < 7) {
          return '${difference.inDays} days ago';
        } else if (difference.inDays < 30) {
          final weeks = (difference.inDays / 7).floor();
          return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
        } else {
          final months = (difference.inDays / 30).floor();
          return months == 1 ? '1 month ago' : '$months months ago';
        }
      } else if (difference.inHours > 0) {
        return difference.inHours == 1 
            ? '1 hour ago' 
            : '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return difference.inMinutes == 1 
            ? '1 minute ago' 
            : '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get freshness status based on manufactured date
  static String getFreshnessStatus(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown';
    }

    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Fresh Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays <= 3) {
        return 'Very Fresh';
      } else if (difference.inDays <= 7) {
        return 'Fresh';
      } else if (difference.inDays <= 14) {
        return 'Good';
      } else {
        return 'Older';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get color for freshness status
  static int getFreshnessColor(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 0xFF9CA3AF; // Gray
    }

    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays <= 1) {
        return 0xFF10B981; // Green - Very fresh
      } else if (difference.inDays <= 3) {
        return 0xFF34D399; // Light green - Fresh
      } else if (difference.inDays <= 7) {
        return 0xFFF59E0B; // Yellow - Good
      } else if (difference.inDays <= 14) {
        return 0xFFF97316; // Orange - Fair
      } else {
        return 0xFFEF4444; // Red - Old
      }
    } catch (e) {
      return 0xFF9CA3AF; // Gray
    }
  }

  /// Format date to readable format (e.g., "12 Sep 2024")
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown';
    }

    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }
}
