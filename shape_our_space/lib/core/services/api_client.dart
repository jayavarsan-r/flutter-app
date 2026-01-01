import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized API client for all backend communication
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  static const String baseUrl = 'http://localhost:5000/api';

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage {
    _setupInterceptors();
  }

  /// Setup interceptors for JWT token attachment
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Set default content-type if not multipart
          if (options.data is! FormData && !options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }
          print('[v0] Request: ${options.method} ${options.uri}');
          print('[v0] Headers: ${options.headers}');
          print('[v0] Has Token: ${token != null}');
          return handler.next(options);
        },
        onError: (error, handler) {
          print('[v0] API Error: ${error.response?.statusCode}');
          print('[v0] API Error Data: ${error.response?.data}');
          print('[v0] API Error Message: ${error.message}');
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            // Clear token and handle re-authentication
            _secureStorage.delete(key: _tokenKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Save JWT token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Get saved JWT token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Clear token on logout
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// AUTH ENDPOINTS
  /// Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (formattedPhone.length > 10) {
        formattedPhone = formattedPhone.substring(formattedPhone.length - 10);
      }
      
      print('[v0] Sending OTP request with phone: $formattedPhone');
      final response = await _dio.post(
        '$baseUrl/auth/send-otp',
        data: {'mobile': formattedPhone},
        options: Options(
          contentType: 'application/json',
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      print('[v0] Send OTP Response Status: ${response.statusCode}');
      print('[v0] Send OTP Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      throw Exception('Failed to send OTP: ${response.statusCode}');
    } on DioException catch (e) {
      print('[v0] Send OTP Error Status: ${e.response?.statusCode}');
      print('[v0] Send OTP Error Data: ${e.response?.data}');
      print('[v0] Send OTP Error Message: ${e.message}');
      throw Exception('Send OTP Error: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  /// Verify OTP and get JWT token
  Future<String> verifyOTP(String phoneNumber, String otp) async {
    try {
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (formattedPhone.length > 10) {
        formattedPhone = formattedPhone.substring(formattedPhone.length - 10);
      }
      
      print('[v0] Verifying OTP with phone: $formattedPhone, otp: $otp');
      
      final response = await _dio.post(
        '$baseUrl/auth/verify-otp',
        data: {
          'mobile': formattedPhone,
          'otp': otp,
        },
        options: Options(
          contentType: 'application/json',
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      print('[v0] Verify OTP Response Status: ${response.statusCode}');
      print('[v0] Verify OTP Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? token;
        
        if (data is Map) {
          token = data['token'] as String?;
          
          if (token == null) {
            token = data['data']?['token'] as String?;
          }
          
          if (token == null && data['data'] is Map) {
            token = (data['data'] as Map)['token'] as String?;
          }
        }
        
        if (token == null) {
          throw Exception('No token found in response: $data');
        }
        
        print('[v0] Token retrieved successfully: ${token.substring(0, 20)}...');
        await saveToken(token);
        return token;
      }
      throw Exception('Failed to verify OTP: ${response.statusCode}');
    } on DioException catch (e) {
      print('[v0] Verify OTP Error Status: ${e.response?.statusCode}');
      print('[v0] Verify OTP Error Data: ${e.response?.data}');
      print('[v0] Verify OTP Error Message: ${e.message}');
      throw Exception('Verify OTP Error: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  /// PROVIDER PROFILE ENDPOINTS
  /// Get provider profile
  Future<Map<String, dynamic>> getProviderProfile() async {
    try {
      final response = await _dio.get('$baseUrl/provider/profile');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Create provider profile
  Future<void> createProviderProfile({
    required String bio,
    required int experienceYears,
    String? profileImage,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/provider/profile',
        data: {
          'bio': bio,
          'experienceYears': experienceYears,
          if (profileImage != null) 'profileImage': profileImage,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Update provider profile
  Future<void> updateProviderProfile({
    required String bio,
    required int experienceYears,
  }) async {
    try {
      await _dio.patch(
        '$baseUrl/provider/profile',
        data: {
          'bio': bio,
          'experienceYears': experienceYears,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Update provider location
  Future<void> updateProviderLocation({
    required double lat,
    required double lng,
    String? googlePlaceId,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/provider/location',
        data: {
          'lat': lat,
          'lng': lng,
          if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Submit verification documents
  Future<void> submitVerificationDocuments({
    required String gstin,
    required String coaLicense,
    required String googleReviewLink,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/provider/verify-documents',
        data: {
          'gstin': gstin,
          'coaLicense': coaLicense,
          'googleReviewLink': googleReviewLink,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// PRICING ENDPOINTS
  /// Add pricing
  Future<Map<String, dynamic>> addPricing({
    required String pricingType,
    required List<String> services,
    required double price,
    required String unit,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/provider/pricing',
        data: {
          'pricingType': pricingType,
          'services': services,
          'price': price,
          'unit': unit,
        },
      );
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Get provider pricing
  Future<List<Map<String, dynamic>>> getProviderPricing() async {
    try {
      final response = await _dio.get('$baseUrl/provider/pricing');
      final data = response.data['data'] ?? response.data;
      return List<Map<String, dynamic>>.from(data ?? []);
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Delete pricing
  Future<void> deletePricing(String pricingId) async {
    try {
      await _dio.delete('$baseUrl/provider/pricing/$pricingId');
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// PORTFOLIO ENDPOINTS
  /// Upload images to backend (which uploads to Cloudinary)
  Future<List<String>> uploadImages(List<dynamic> imageFiles) async {
    try {
      final formData = FormData();
      
      // Add files to form data
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        String fileName = 'image_$i.jpg';
        
        if (file is MultipartFile) {
          formData.files.add(MapEntry('images', file));
        } else {
          // Assume it's a File object
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
            ),
          ));
        }
      }

      print('[v0] Uploading ${imageFiles.length} images to backend');
      
      final response = await _dio.post(
        '$baseUrl/provider/upload-images',
        data: formData,
      );
      
      print('[v0] Upload Response: ${response.data}');
      
      // Backend returns { success: true, data: { urls: [...] } }
      final urls = response.data['data']?['urls'] ?? response.data['urls'];
      return List<String>.from(urls ?? []);
    } on DioException catch (e) {
      print('[v0] Upload Error: ${e.response?.data}');
      rethrow;
    }
  }

  /// Add portfolio project
  Future<Map<String, dynamic>> addPortfolioProject({
    required String title,
    required String description,
    required List<String> images,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/provider/portfolio',
        data: {
          'title': title,
          'description': description,
          'images': images,
        },
      );
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Get portfolio projects
  Future<List<Map<String, dynamic>>> getPortfolioProjects() async {
    try {
      final response = await _dio.get('$baseUrl/provider/portfolio');
      final data = response.data['data'] ?? response.data;
      return List<Map<String, dynamic>>.from(data ?? []);
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Delete portfolio project
  Future<void> deletePortfolioProject(String projectId) async {
    try {
      await _dio.delete('$baseUrl/provider/portfolio/$projectId');
    } on DioException catch (e) {
      rethrow;
    }
  }
}

/// Provider for Dio instance
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ),
  );
});

/// Provider for FlutterSecureStorage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for ApiClient instance
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(dio: dio, secureStorage: secureStorage);
});
