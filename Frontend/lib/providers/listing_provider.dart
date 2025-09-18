import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ListingProvider with ChangeNotifier {
  // final ApiService _apiService = ApiService(); // Reserved for future API integration
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _listings = [];
  // Store favorites per user ID: Map<userId, Set<listingId>>
  final Map<String, Set<String>> _userFavorites = {};
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Map<String, dynamic>> get listings => _listings;
  
  // Get favorites for a specific user
  List<Map<String, dynamic>> getFavoritesForUser(String? userId) {
    if (userId == null) return [];
    final userFavorites = _userFavorites[userId] ?? <String>{};
    return _listings.where((e) => userFavorites.contains(e['id'])).toList();
  }
  
  List<File> get selectedImages => _selectedImages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Pick multiple images
  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
      );
      
      if (pickedFiles.length > 5) {
        _setError('Maximum 5 images allowed');
        return;
      }
      
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to pick images: $e');
    }
  }

  // Pick single image from camera
  Future<void> takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      
      if (pickedFile != null) {
        if (_selectedImages.length >= 5) {
          _setError('Maximum 5 images allowed');
          return;
        }
        _selectedImages.add(File(pickedFile.path));
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to take photo: $e');
    }
  }

  // Remove image
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Clear all selected images
  void clearSelectedImages() {
    _selectedImages.clear();
    notifyListeners();
  }
  
  Future<void> loadListings() async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Call the real backend API
      final apiService = ApiService();
      final listings = await apiService.getListings();
      
      _listings = listings;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load listings. Please try again.');
    }
  }
  
Future<void> addListing(Map<String, dynamic> listingData, String token) async {
  try {
    _setLoading(true);
    _setError(null);
    
    // Convert File objects to paths for storage
    List<String> imagePaths = _selectedImages.map((file) => file.path).toList();
    
    // Prepare listing data for backend
    final listingPayload = {
      ...listingData,
      'images': imagePaths,
    };
    
    // Call the real backend API
    final apiService = ApiService();
    final newListing = await apiService.createListing(listingPayload, token);
    
    _listings.insert(0, newListing);
    _selectedImages.clear(); // Clear selected images after adding
    _setLoading(false);
  } catch (e) {
    _setLoading(false);
    _setError('Failed to add listing. Please try again.');
  }
}
  
  Future<void> searchListings(String query) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Call the real backend API with search query
      final apiService = ApiService();
      final listings = await apiService.getListings();
      
      if (query.isEmpty) {
        _listings = listings;
      } else {
        // Filter listings based on search query
        _listings = listings
            .where((listing) =>
                listing['cropName']
                    ?.toLowerCase()
                    ?.contains(query.toLowerCase()) ??
                false ||
                listing['location']
                    ?.toLowerCase()
                    ?.contains(query.toLowerCase()) ??
                false)
            .toList();
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Search failed. Please try again.');
    }
  }
  

  // Favorites - now user-specific
  void toggleFavorite(String listingId, String? userId) {
    if (userId == null) return;
    
    // Initialize user's favorites set if it doesn't exist
    _userFavorites[userId] ??= <String>{};
    
    if (_userFavorites[userId]!.contains(listingId)) {
      _userFavorites[userId]!.remove(listingId);
    } else {
      _userFavorites[userId]!.add(listingId);
    }
    notifyListeners();
  }

  bool isFavorite(String listingId, String? userId) {
    if (userId == null) return false;
    return _userFavorites[userId]?.contains(listingId) ?? false;
  }

  // Delete listing functionality
  Future<void> deleteListing(String listingId, String token) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Call the real backend API
      final apiService = ApiService();
      await apiService.deleteListing(listingId, token);
      
      // Remove from local listings
      _listings.removeWhere((listing) => listing['id'] == listingId);
      
      // Remove from all users' favorites
      for (final userId in _userFavorites.keys) {
        _userFavorites[userId]?.remove(listingId);
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete listing. Please try again.');
    }
  }

  // Update listing functionality
  Future<void> updateListing(String listingId, Map<String, dynamic> updatedData, String token) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Call the real backend API
      final apiService = ApiService();
      final updatedListing = await apiService.updateListing(listingId, updatedData, token);
      
      // Update the listing in local list
      final index = _listings.indexWhere((listing) => listing['id'] == listingId);
      if (index != -1) {
        _listings[index] = updatedListing;
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update listing. Please try again.');
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}