import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user, // Nullable update logic requires care, but for simplicity:
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthController(this._apiService) : super(AuthState());

  Future<void> checkAuthStatus() async {
    final token = storageService.getString(AppConstants.authTokenKey);
    if (token != null) {
      state = AuthState(isAuthenticated: true, isLoading: true);
      try {
        await fetchProfile();
      } catch (e) {
        // If profile fetch fails (e.g. 401), unauthorized
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
    } else {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> fetchProfile() async {
    // The API doesn't have a /users/me endpoint
    // We already have user data from the JWT token in verifyOtp
    // So we just need to maintain the authenticated state
    try {
      if (state.user != null) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        // If we have a token but no user, decode it again
        final token = storageService.getString(AppConstants.authTokenKey);
        if (token != null && !JwtDecoder.isExpired(token)) {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          final user = User(
            id: decodedToken['id'] ?? decodedToken['_id'] ?? '',
            email: decodedToken['email'] ?? 'user@example.com',
            name: decodedToken['name'] ?? 'User',
            role: decodedToken['role'] ?? 'user',
          );
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: user,
          );
        } else {
          // Token expired or invalid
          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      }
    } catch (e) {
      debugPrint('Fetch profile failed: $e');
      state = state.copyWith(isLoading: false, error: null);
    }
  }

  Future<bool> sendOtp(String email) async {
    print('Sending OTP to: $email'); // DEBUG LOG
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.client.post(
        '/auth/email/send-otp',
        data: {'email': email},
      );
      print(
        'Send OTP Response: ${response.statusCode} - ${response.data}',
      ); // DEBUG LOG
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      print('Send OTP Error: ${e.message} - ${e.response?.data}'); // DEBUG LOG
      String errorMessage = 'Failed to send OTP';
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data is String) {
        errorMessage = data;
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      print('Send OTP Generic Error: $e'); // DEBUG LOG
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    print('Sending OTP to verify: $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.client.post(
        '/auth/email/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      print('Verify Response: ${response.data}');

      final token = response.data['token'];
      if (token == null) throw Exception('No token received');

      await storageService.setString(AppConstants.authTokenKey, token);

      // Decode Token to get User Details
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      print('Decoded Token: $decodedToken');

      // Expected claims: { id: "...", email: "...", role: "...", name: "..." }
      // If name is missing, use email part.
      final user = User(
        id: decodedToken['id'] ?? decodedToken['_id'] ?? '',
        email:
            decodedToken['email'] ??
            email, // Prioritize token, fallback to input
        name: decodedToken['name'] ?? email.split('@')[0],
        role: decodedToken['role'] ?? 'user',
      );

      print('DEBUG: User Email Stored: ${user.email}'); // Debug log

      state = AuthState(isAuthenticated: true, isLoading: false, user: user);
      return true;
    } on DioException catch (e) {
      print('Verify Error:Wrapper ${e.response?.data}');
      String errorMessage = 'Invalid OTP';
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data is String) {
        errorMessage = data;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<void> signOut() async {
    await storageService.remove(AppConstants.authTokenKey);
    state = AuthState(isAuthenticated: false);
  }

  Future<bool> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _apiService.client.delete('/auth/me');

      // Clear all local data
      await storageService.remove(AppConstants.authTokenKey);

      // Reset state
      state = AuthState(isAuthenticated: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString()}',
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ApiService());
});
