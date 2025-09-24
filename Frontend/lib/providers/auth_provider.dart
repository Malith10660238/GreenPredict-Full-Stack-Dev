import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

// --- User Data Model ---
class AppUser {
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? email;
  final String uid;
  final String userType; // 'farmer' or 'consumer'
  final String? phone;
  final String? location;
  final String? bio;
  final DateTime? joinDate;
  final double? rating;
  final int? totalReviews;
  
  // Farmer-specific fields
  final String? farmName;
  final String? farmSize;
  final List<String>? crops;
  final String? farmingExperience;
  final int? totalListings;
  final int? totalSales;
  final String? certification;
  
  // Consumer-specific fields
  final List<String>? preferences;
  final int? totalOrders;
  final double? totalSpent;
  final List<String>? favoriteCrops;

  AppUser({
    this.firstName,
    this.lastName,
    this.displayName,
    this.email,
    required this.uid,
    required this.userType,
    this.phone,
    this.location,
    this.bio,
    this.joinDate,
    this.rating,
    this.totalReviews,
    this.farmName,
    this.farmSize,
    this.crops,
    this.farmingExperience,
    this.totalListings,
    this.totalSales,
    this.certification,
    this.preferences,
    this.totalOrders,
    this.totalSpent,
    this.favoriteCrops,
  });

  // Enhanced copyWith method
  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? displayName,
    String? email,
    String? phone,
    String? location,
    String? bio,
    DateTime? joinDate,
    double? rating,
    int? totalReviews,
    String? farmName,
    String? farmSize,
    List<String>? crops,
    String? farmingExperience,
    int? totalListings,
    int? totalSales,
    String? certification,
    List<String>? preferences,
    int? totalOrders,
    double? totalSpent,
    List<String>? favoriteCrops,
  }) {
    return AppUser(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      uid: uid,
      userType: userType,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      joinDate: joinDate ?? this.joinDate,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      farmName: farmName ?? this.farmName,
      farmSize: farmSize ?? this.farmSize,
      crops: crops ?? this.crops,
      farmingExperience: farmingExperience ?? this.farmingExperience,
      totalListings: totalListings ?? this.totalListings,
      totalSales: totalSales ?? this.totalSales,
      certification: certification ?? this.certification,
      preferences: preferences ?? this.preferences,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      favoriteCrops: favoriteCrops ?? this.favoriteCrops,
    );
  }
}

class AuthProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImageFile;
  String? _profileImageUrl;
  String? _authToken;
  final ApiService _apiService = ApiService();

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get profileImageFile => _profileImageFile;
  String? get profileImageUrl => _profileImageUrl;
  String? get authToken => _authToken;
  bool get isAuthenticated => _user != null;
  bool get isFarmer => _user?.userType == 'farmer';
  bool get isConsumer => _user?.userType == 'consumer';

  Future<void> pickProfileImage() async {
    try {
      _setLoading(true);
      print('🔵 Picking profile image from gallery...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
      );

      if (pickedFile != null) {
        _profileImageFile = File(pickedFile.path);
        print('🔵 Image picked successfully: ${pickedFile.path}');
        notifyListeners();
        
        // Automatically upload the image
        await _uploadProfileImage();
      } else {
        print('🔵 No image selected');
      }
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('❌ Failed to pick image: $e');
      _setError('Could not pick image. Please check permissions.');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImageFile != null && _authToken != null) {
      try {
        print('🔵 Auto-uploading profile image: ${_profileImageFile!.path}');
        final imageResponse = await _apiService.uploadProfileImage(_profileImageFile!, _authToken!);
        print('🔵 Auto-upload response: $imageResponse');
        if (imageResponse['image_url'] != null) {
          _profileImageUrl = imageResponse['image_url'];
          print('🔵 Profile image URL updated: $_profileImageUrl');
          notifyListeners();
          _setError(null); // Clear any previous errors
        } else {
          print('❌ Auto-upload response missing image_url');
          _setError('Failed to save profile image. Please try again.');
        }
      } catch (e) {
        print('❌ Failed to auto-upload profile image: $e');
        _setError('Failed to save profile image. Please try again.');
      }
    }
  }

  // --- NEW: Method to remove profile image ---
  void removeProfileImage() {
    _profileImageFile = null;
    notifyListeners();
  }

  // --- ENHANCED: Method to update user details ---
  Future<void> updateUserProfile({
    required String displayName,
    required String phone,
    required String location,
    String? bio,
    String? farmName,
    String? farmSize,
    String? farmingExperience,
    String? certification,
    List<String>? preferences,
    File? profileImage,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    _setError(null);

    try {
      // Prepare profile data for backend (using camelCase to match backend expectations)
      final profileData = {
        'displayName': displayName,
        'phone': phone,
        'location': location,
        'bio': bio,
        'farmName': farmName,
        'farmSize': farmSize,
        'farmingExperience': farmingExperience,
        'certification': certification,
        'preferences': preferences,
      };
      
      // Extract first and last name from display name
      final nameParts = displayName.trim().split(' ');
      if (nameParts.isNotEmpty) {
        profileData['firstName'] = nameParts[0];
        if (nameParts.length > 1) {
          profileData['lastName'] = nameParts.sublist(1).join(' ');
        } else {
          profileData['lastName'] = '';
        }
      }

      // Call the real backend API to update profile
      if (_authToken == null) {
        _setError('Authentication required. Please login again.');
        _setLoading(false);
        return;
      }
      
      print('🔵 Sending profile update data: $profileData');
      final response = await _apiService.updateProfile(profileData, _authToken!);
      print('🔵 Profile update response: $response');
      
      if (response['uid'] != null || response['user'] != null) {
        // Get user data from response (handle both direct response and nested user object)
        final userData = response['user'] ?? response;
        
        // Update local user data with backend response (handle both camelCase and snake_case)
        _user = _user!.copyWith(
          firstName: userData['firstName'] ?? userData['first_name'],
          lastName: userData['lastName'] ?? userData['last_name'],
          displayName: userData['displayName'] ?? userData['display_name'],
          phone: userData['phone'],
          location: userData['location'],
          bio: userData['bio'],
          farmName: userData['farmerProfile']?['farmName'] ?? userData['farmer_profile']?['farm_name'],
          farmSize: userData['farmerProfile']?['farmSize'] ?? userData['farmer_profile']?['farm_size'],
          farmingExperience: userData['farmerProfile']?['farmingExperience'] ?? userData['farmer_profile']?['farming_experience'],
          certification: userData['farmerProfile']?['certification'] ?? userData['farmer_profile']?['certification'],
          preferences: userData['consumerProfile']?['preferences']?.cast<String>() ?? userData['consumer_profile']?['preferences']?.cast<String>(),
        );
        
        // Handle profile image update if provided
        if (userData['profileImageUrl'] != null) {
          _profileImageUrl = userData['profileImageUrl'];
        } else if (userData['profile_image_url'] != null) {
          _profileImageUrl = userData['profile_image_url'];
        }
        
        print('🔵 Updated local user data: ${_user?.displayName}, ${_user?.phone}, ${_user?.location}');
        
        // Notify listeners that user data has been updated
        notifyListeners();
      }
      
      // Upload profile image if provided
      if (profileImage != null && _authToken != null) {
        try {
          print('🔵 Uploading profile image: ${profileImage.path}');
          final imageResponse = await _apiService.uploadProfileImage(profileImage, _authToken!);
          print('🔵 Image upload response: $imageResponse');
          if (imageResponse['image_url'] != null) {
            _profileImageUrl = imageResponse['image_url'];
            _profileImageFile = profileImage;
            print('🔵 Profile image URL updated: $_profileImageUrl');
            notifyListeners();
          } else if (imageResponse['imageUrl'] != null) {
            _profileImageUrl = imageResponse['imageUrl'];
            _profileImageFile = profileImage;
            print('🔵 Profile image URL updated: $_profileImageUrl');
            notifyListeners();
          } else {
            print('❌ Image upload response missing image_url');
          }
        } catch (e) {
          print('❌ Failed to upload profile image: $e');
          // Don't fail the entire profile update if image upload fails
        }
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update profile. Please try again.');
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (email.isNotEmpty && password.length >= 6) {
        // Call the real backend API
        print('🔵 Attempting login with email: $email');
        final response = await _apiService.login(email, password);
        print('🔵 Login response: $response');
        
        if (response['user'] != null) {
          final userData = response['user'];
          
          // Store the auth token
          _authToken = response['access_token'];
          
          // Debug logging
          print('🔵 User data from backend: $userData');
          print('🔵 Display name: ${userData['displayName'] ?? userData['display_name']}');
          
          // Convert backend user data to AppUser
          _user = AppUser(
            firstName: userData['firstName'] ?? userData['first_name'],
            lastName: userData['lastName'] ?? userData['last_name'],
            displayName: userData['displayName'] ?? userData['display_name'],
            email: userData['email'],
            uid: userData['uid'],
            userType: userData['userType'] ?? userData['user_type'],
            phone: userData['phone'],
            location: userData['location'],
            bio: userData['bio'],
            joinDate: userData['joinDate'] != null
                ? DateTime.parse(userData['joinDate'])
                : userData['join_date'] != null
                    ? DateTime.parse(userData['join_date'])
                    : DateTime.now(),
            rating: userData['rating']?.toDouble(),
            totalReviews: userData['totalReviews'] ?? userData['total_reviews'],
            // Farmer-specific data
            farmName: userData['farmerProfile']?['farmName'] ?? userData['farmer_profile']?['farm_name'],
            farmSize: userData['farmerProfile']?['farmSize'] ?? userData['farmer_profile']?['farm_size'],
            crops: userData['farmerProfile']?['crops']?.cast<String>() ?? userData['farmer_profile']?['crops']?.cast<String>(),
            farmingExperience: userData['farmerProfile']?['farmingExperience'] ?? userData['farmer_profile']?['farming_experience'],
            totalListings: userData['farmerProfile']?['totalListings'] ?? userData['farmer_profile']?['total_listings'],
            totalSales: userData['farmerProfile']?['totalSales'] ?? userData['farmer_profile']?['total_sales'],
            certification: userData['farmerProfile']?['certification'] ?? userData['farmer_profile']?['certification'],
            // Consumer-specific data
            preferences: userData['consumerProfile']?['preferences']?.cast<String>() ?? userData['consumer_profile']?['preferences']?.cast<String>(),
            totalOrders: userData['consumerProfile']?['totalOrders'] ?? userData['consumer_profile']?['total_orders'],
            totalSpent: userData['consumerProfile']?['totalSpent']?.toDouble() ?? userData['consumer_profile']?['total_spent']?.toDouble(),
            favoriteCrops: userData['consumerProfile']?['favoriteCrops']?.cast<String>() ?? userData['consumer_profile']?['favorite_crops']?.cast<String>(),
          );
          
          // Handle profile image if provided
          if (userData['profileImageUrl'] != null) {
            _profileImageUrl = userData['profileImageUrl'];
          } else if (userData['profile_image_url'] != null) {
            _profileImageUrl = userData['profile_image_url'];
          }
          
          // Notify listeners that user data has been set
          notifyListeners();
          _setLoading(false);
          return true;
        } else {
          _setError('Login failed. Please check your credentials.');
          _setLoading(false);
          return false;
        }
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Login failed. Please try again.');
      return false;
    }
  }
  
  Future<bool> signUpWithEmailAndPassword(
    String email, 
    String password, 
    String firstName,
    String lastName,
    String userType,
  ) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (email.isNotEmpty && password.length >= 6 && firstName.isNotEmpty && lastName.isNotEmpty) {
        // Call the real backend API
        final userData = {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'user_type': userType,
        };
        
        print('🔵 Attempting registration with data: $userData');
        final response = await _apiService.register(userData);
        print('🔵 Registration response: $response');
        
        if (response['user'] != null) {
          final userResponse = response['user'];
          
          // Convert backend user data to AppUser
          _user = AppUser(
            firstName: userResponse['first_name'],
            lastName: userResponse['last_name'],
            displayName: userResponse['display_name'],
            email: userResponse['email'],
            uid: userResponse['uid'],
            userType: userResponse['user_type'],
            phone: userResponse['phone'],
            location: userResponse['location'],
            bio: userResponse['bio'],
            joinDate: userResponse['join_date'] != null 
                ? DateTime.parse(userResponse['join_date']) 
                : DateTime.now(),
            rating: userResponse['rating']?.toDouble(),
            totalReviews: userResponse['total_reviews'],
            // Farmer-specific data
            farmName: userResponse['farmer_profile']?['farm_name'],
            farmSize: userResponse['farmer_profile']?['farm_size'],
            crops: userResponse['farmer_profile']?['crops']?.cast<String>(),
            farmingExperience: userResponse['farmer_profile']?['farming_experience'],
            totalListings: userResponse['farmer_profile']?['total_listings'],
            totalSales: userResponse['farmer_profile']?['total_sales'],
            certification: userResponse['farmer_profile']?['certification'],
            // Consumer-specific data
            preferences: userResponse['consumer_profile']?['preferences']?.cast<String>(),
            totalOrders: userResponse['consumer_profile']?['total_orders'],
            totalSpent: userResponse['consumer_profile']?['total_spent']?.toDouble(),
            favoriteCrops: userResponse['consumer_profile']?['favorite_crops']?.cast<String>(),
          );
          
          _setLoading(false);
          return true;
        } else {
          _setError('Registration failed. Please try again.');
          _setLoading(false);
          return false;
        }
      } else {
        _setError('Please fill all required fields correctly');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      
      // Parse specific error messages from the backend
      String errorMessage = 'Registration failed. Please try again.';
      
      if (e.toString().contains('EMAIL_EXISTS') || e.toString().contains('already registered')) {
        errorMessage = 'This email is already registered. Please use a different email or try logging in.';
      } else if (e.toString().contains('INVALID_EMAIL') || e.toString().contains('valid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('WEAK_PASSWORD') || e.toString().contains('too weak')) {
        errorMessage = 'Password is too weak. Please choose a stronger password.';
      } else if (e.toString().contains('Email is required')) {
        errorMessage = 'Email is required.';
      } else if (e.toString().contains('Password is required')) {
        errorMessage = 'Password is required.';
      } else if (e.toString().contains('First name is required')) {
        errorMessage = 'First name is required.';
      } else if (e.toString().contains('Last name is required')) {
        errorMessage = 'Last name is required.';
      } else if (e.toString().contains('User type must be')) {
        errorMessage = 'Please select a valid user type.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('Firebase')) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      _setError(errorMessage);
      return false;
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Implement real Google Sign-In with backend API
      _user = AppUser(
        firstName: 'Google',
        lastName: 'User',
        displayName: 'Google User',
        email: 'user@gmail.com',
        uid: 'google_12345',
        userType: 'consumer',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }
  
  Future<void> signOut() async {
    _user = null;
    _profileImageFile = null;
    _profileImageUrl = null;
    _authToken = null;
    notifyListeners();
  }
  
  Future<bool> verifyEmail(String email, String verificationCode) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.verifyEmail(email, verificationCode);
      
      if (response['email_verified'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError('Email verification failed. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Email verification failed. Please try again.');
      return false;
    }
  }
  
  Future<bool> resendVerification(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.resendVerification(email);
      
      if (response['message'] != null) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to resend verification email.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Failed to resend verification email.');
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Password reset functionality
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Simulate network call for password reset
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if email is valid (basic validation)
      if (email.isEmpty || !email.contains('@')) {
        _setError('Please enter a valid email address');
        _setLoading(false);
        return false;
      }
      
      // Simulate successful password reset
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Password reset failed. Please try again.');
      return false;
    }
  }

  // Change password functionality (for authenticated users)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Simulate network call for password change
      await Future.delayed(const Duration(seconds: 1));
      
      // Basic validation
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        _setError('Please fill in all fields');
        _setLoading(false);
        return false;
      }
      
      if (newPassword.length < 6) {
        _setError('New password must be at least 6 characters long');
        _setLoading(false);
        return false;
      }
      
      // Simulate successful password change
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Password change failed. Please try again.');
      return false;
    }
  }
}