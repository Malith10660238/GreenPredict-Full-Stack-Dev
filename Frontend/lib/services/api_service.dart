import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // FastAPI backend URL
  static const String baseUrl = 'http://10.224.79.220:8001'; // FastAPI backend
  
  // API Endpoints
  static const String _authEndpoint = '/auth';
  static const String _listingsEndpoint = '/listings';
  static const String _profileEndpoint = '/profile/';
  
  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  Map<String, String> _authHeaders(String token) {
    print('🔵 Auth token: ${token.substring(0, 20)}...');
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }
  
  // Authentication APIs
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_authEndpoint/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Login failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Login failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during login: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Marketplace APIs
  Future<List<Map<String, dynamic>>> getListings({
    String? cropType,
    String? location,
    double? priceMin,
    double? priceMax,
    bool? isOrganic,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String queryParams = '';
      final params = <String>[];
      if (cropType != null) params.add('crop_type=$cropType');
      if (location != null) params.add('location=$location');
      if (priceMin != null) params.add('price_min=$priceMin');
      if (priceMax != null) params.add('price_max=$priceMax');
      if (isOrganic != null) params.add('is_organic=$isOrganic');
      params.add('limit=$limit');
      params.add('offset=$offset');
      
      if (params.isNotEmpty) {
        queryParams = '?${params.join('&')}';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl$_listingsEndpoint$queryParams'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['listings'] != null) {
          return List<Map<String, dynamic>>.from(responseData['listings']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch listings: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getMyListings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_listingsEndpoint/my'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['listings'] != null) {
          return List<Map<String, dynamic>>.from(responseData['listings']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch my listings: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> createListing(
    Map<String, dynamic> listingData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_listingsEndpoint/'),
        headers: _authHeaders(token),
        body: jsonEncode(listingData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['listing'] != null) {
          return responseData['listing'];
        } else {
          return responseData;
        }
      } else {
        throw Exception('Failed to create listing: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> updateListing(
    String listingId,
    Map<String, dynamic> listingData,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$_listingsEndpoint/$listingId'),
        headers: _authHeaders(token),
        body: jsonEncode(listingData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['listing'] != null) {
          return responseData['listing'];
        } else {
          return responseData;
        }
      } else {
        throw Exception('Failed to update listing: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<void> deleteListing(String listingId, String token) async {
    try {
      final url = '$baseUrl$_listingsEndpoint/$listingId';
      print('🔵 Delete URL: $url');
      print('🔵 Listing ID: $listingId');
      final response = await http.delete(
        Uri.parse(url),
        headers: _authHeaders(token),
      );
      
      print('🔵 Delete response status: ${response.statusCode}');
      print('🔵 Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to delete listing: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Delete error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Profile APIs
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_profileEndpoint'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch profile: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
    String token,
  ) async {
    try {
      print('🔵 API Service - Updating profile with data: $profileData');
      print('🔵 API Service - URL: $baseUrl$_profileEndpoint');
      final response = await http.put(
        Uri.parse('$baseUrl$_profileEndpoint'),
        headers: _authHeaders(token),
        body: jsonEncode(profileData),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Profile update failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update profile: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during profile update: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
    File imageFile,
    String token,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$_profileEndpoint/upload-image'),
      );
      
      request.headers.addAll(_authHeaders(token));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        print('❌ Image upload failed - Status: ${response.statusCode}, Body: $responseBody');
        throw Exception('Failed to upload image: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during image upload: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteProfileImage(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$_profileEndpoint/image'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Image deletion failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to delete image: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during image deletion: $e');
      throw Exception('Network error: $e');
    }
  }
Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_authEndpoint/register'),
        headers: _headers,
        body: jsonEncode(userData),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Registration failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Registration failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during registration: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Email Verification APIs
  Future<Map<String, dynamic>> verifyEmail(String email, String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_authEndpoint/verify-email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'verification_code': verificationCode,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Email verification failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Email verification failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during email verification: $e');
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_authEndpoint/resend-verification'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Resend verification failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to resend verification: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during resend verification: $e');
      throw Exception('Network error: $e');
    }
  }

  // AI Prediction API
  Future<Map<String, dynamic>> getPrediction(Map<String, dynamic> inputData, String token) async {
    try {
      // Convert frontend data format to backend format
      final backendData = {
        'planning_year': inputData['planningYear'] ?? '2025',
        'location': inputData['district'] ?? 'Colombo',
        'season': inputData['season'] ?? 'Yala',
        'temperature': inputData['temperature']?.toString() ?? null,  // Let backend use district defaults
        'soil_type': inputData['soilType'] ?? null,  // Let backend use district defaults
        'land_area': inputData['landArea']?.toString() ?? '1.0',
        'crop': inputData['crop'] ?? 'Cabbage',
      };
      
      print('🔵 Sending prediction request to: $baseUrl/predictions/analyze');
      print('🔵 Request data: $backendData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/predictions/analyze'),
        headers: _authHeaders(token),
        body: jsonEncode(backendData),
      );
      
      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Prediction successful!');
        return result;
      } else {
        print('❌ Prediction failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Prediction failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during prediction: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get prediction history
  Future<List<Map<String, dynamic>>> getPredictionHistory(String token) async {
    try {
      print('🔵 Fetching prediction history from: $baseUrl/predictions/history');
      
      final response = await http.get(
        Uri.parse('$baseUrl/predictions/history'),
        headers: _authHeaders(token),
      );
      
      print('🔵 History response status: ${response.statusCode}');
      print('🔵 History response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        print('✅ Prediction history fetched successfully!');
        print('🔵 API Service: Raw response body: ${response.body}');
        print('🔵 API Service: Parsed result: $result');
        print('🔵 API Service: Result length: ${result.length}');
        return List<Map<String, dynamic>>.from(result);
      } else {
        print('❌ History fetch failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch prediction history: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during history fetch: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete a specific prediction
  Future<Map<String, dynamic>> deletePrediction(String predictionId, String token) async {
    try {
      print('🔵 Deleting prediction: $baseUrl/predictions/$predictionId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/predictions/$predictionId'),
        headers: _authHeaders(token),
      );
      
      print('🔵 Delete response status: ${response.statusCode}');
      print('🔵 Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Prediction deleted successfully!');
        return result;
      } else {
        print('❌ Delete failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to delete prediction: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during delete: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete all predictions
  Future<Map<String, dynamic>> deleteAllPredictions(String token) async {
    try {
      print('🔵 Deleting all predictions: $baseUrl/predictions/');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/predictions/'),
        headers: _authHeaders(token),
      );
      
      print('🔵 Delete all response status: ${response.statusCode}');
      print('🔵 Delete all response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ All predictions deleted successfully!');
        return result;
      } else {
        print('❌ Delete all failed - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to delete all predictions: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Network error during delete all: $e');
      throw Exception('Network error: $e');
    }
  }

}