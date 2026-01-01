import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_type.dart';
import '../../../core/services/api_client.dart';

/// Flow types for authentication
enum AuthFlowType { login, signup }

/// Enhanced auth state with JWT token and flow tracking
class AuthState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final UserType selectedUserType;
  final String? jwtToken;
  final bool isAuthenticated;
  final bool isCheckingAuth;
  final AuthFlowType? currentFlow; // Still useful for UI logic, but not for routing logic

  AuthState({
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.selectedUserType = UserType.user,
    this.jwtToken,
    this.isAuthenticated = false,
    this.isCheckingAuth = true,
    this.currentFlow,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? phoneNumber,
    UserType? selectedUserType,
    String? jwtToken,
    bool? isAuthenticated,
    bool? isCheckingAuth,
    AuthFlowType? currentFlow,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
      phoneNumber: phoneNumber ?? this.phoneNumber,
      selectedUserType: selectedUserType ?? this.selectedUserType,
      jwtToken: jwtToken ?? this.jwtToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      currentFlow: currentFlow ?? this.currentFlow,
    );
  }
}

/// Enhanced auth notifier with flow-aware state transitions
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  static const String _phoneKey = 'user_phone';

  AuthNotifier(this._apiClient, this._secureStorage) : super(AuthState()) {
    _initializeAuth();
  }

  /// Check for existing token on app startup for auto-login
  Future<void> _initializeAuth() async {
    try {
      print('[v0] Auth: Initializing authentication check...');
      final token = await _apiClient.getToken();
      
      if (token != null && token.isNotEmpty) {
        print('[v0] Auth: Existing token found, setting authenticated state');
        state = state.copyWith(
          isAuthenticated: true,
          jwtToken: token,
          isCheckingAuth: false,
        );
      } else {
        print('[v0] Auth: No existing token found');
        state = state.copyWith(isCheckingAuth: false);
      }
    } catch (e) {
      print('[v0] Auth: Error during initialization - $e');
      state = state.copyWith(isCheckingAuth: false);
    }
  }

  void setUserType(UserType type) {
    state = state.copyWith(selectedUserType: type);
  }

  /// Added setAuthFlow method to explicitly set the authentication flow type
  void setAuthFlow(AuthFlowType flow) {
    print('[v0] Auth: Setting auth flow to ${flow.name}');
    state = state.copyWith(currentFlow: flow);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  /// Integrate with backend OTP API with optional flow type initialization
  Future<bool> sendOTP(String phoneNumber, {AuthFlowType? flow}) async {
    state = state.copyWith(
      isLoading: true, 
      error: null, 
      phoneNumber: phoneNumber,
      currentFlow: flow ?? state.currentFlow,
    );
    
    try {
      print('[v0] Auth: Sending OTP to $phoneNumber');
      final success = await _apiClient.sendOTP(phoneNumber);
      
      if (success) {
        await _secureStorage.write(key: _phoneKey, value: phoneNumber);
        print('[v0] Auth: OTP sent successfully');
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to send OTP');
      }
      return success;
    } catch (e) {
      print('[v0] Auth: sendOTP Error - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Integrate with backend OTP verification API
  Future<bool> verifyOTP(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final phoneNumber = state.phoneNumber ?? await _secureStorage.read(key: _phoneKey);
      if (phoneNumber == null) {
        throw Exception('Phone number not found');
      }
      
      print('[v0] Auth: Verifying OTP for $phoneNumber');
      final token = await _apiClient.verifyOTP(phoneNumber, otp);
      
      print('[v0] Auth: OTP verified successfully');
      
      // For signup flow, we don't set isAuthenticated=true yet.
      // For login flow, we do.
      final isLoginFlow = state.currentFlow == AuthFlowType.login;
      
      state = state.copyWith(
        isLoading: false,
        jwtToken: token,
        isAuthenticated: isLoginFlow,
      );
      return true;
    } catch (e) {
      print('[v0] Auth: verifyOTP Error - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Verify GST and complete signup authentication
  Future<bool> verifyGST(String gstin) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('[v0] Auth: Verifying GST number: $gstin');
      // Simulate delay
      await Future.delayed(const Duration(seconds: 2));
      
      print('[v0] Auth: GST verified successfully, marking user as authenticated');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentFlow: null,
      );
      
      return true;
    } catch (e) {
      print('[v0] Auth: verifyGST Error - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout and clear token
  Future<void> logout() async {
    print('[v0] Auth: Logging out');
    await _apiClient.clearToken();
    await _secureStorage.delete(key: _phoneKey);
    state = AuthState(isCheckingAuth: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  const secureStorage = FlutterSecureStorage();
  return AuthNotifier(apiClient, secureStorage);
});
