import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

/// Auth state model
class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? username;
  final String? fullName;
  final String? role;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.username,
    this.fullName,
    this.role,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => accessToken != null && userId != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? username,
    String? fullName,
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static const AuthState initial = AuthState();
}

/// Auth state notifier using Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial);

  /// Reset loading state
  void resetLoading() {
    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokens = await ApiService.login(username, password);

      // Store tokens securely
      await SecureStorageService.setAccessToken(tokens['access_token']!);
      await SecureStorageService.setRefreshToken(tokens['refresh_token']!);

      // Configure API service with new token
      ApiService.setToken(tokens['access_token']!);

      // Fetch user profile
      final profile = await ApiService.getMe();

      state = AuthState(
        accessToken: tokens['access_token'],
        refreshToken: tokens['refresh_token'],
        userId: profile['user_id'],
        username: profile['username'],
        fullName: profile['full_name'],
        role: profile['role'],
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      if (!state.isAuthenticated && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register(
      String username, String password, String fullName, String email, String? inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await ApiService.register(username, password, fullName, email, inviteCode);

      // Store tokens securely
      await SecureStorageService.setAccessToken(data['access_token']!);
      await SecureStorageService.setRefreshToken(data['refresh_token']!);

      // Configure API service with new token
      ApiService.setToken(data['access_token']!);

      // Fetch user profile
      final profile = await ApiService.getMe();

      state = AuthState(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        userId: profile['user_id'],
        username: profile['username'],
        fullName: profile['full_name'],
        role: profile['role'],
        isLoading: false,
      );

      return {'success': true, 'role': data['role'], 'message': data['message']};
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return {'success': false};
    } finally {
      if (!state.isAuthenticated && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Logout — clear tokens and state
  Future<void> logout() async {
    try {
      await SecureStorageService.clearAll();
    } catch (_) {}
    ApiService.setToken('');
    state = AuthState.initial;
  }

  /// Rehydrate session from stored tokens
  Future<void> rehydrate() async {
    try {
      final accessToken = await SecureStorageService.getAccessToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (accessToken == null || accessToken.isEmpty) {
        state = AuthState.initial;
        return;
      }

      ApiService.setToken(accessToken);

      final profile = await ApiService.getMe().timeout(const Duration(seconds: 2));
      final refreshToken = await SecureStorageService.getRefreshToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      state = AuthState(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: profile['user_id'],
        username: profile['username'],
        fullName: profile['full_name'],
        role: profile['role'],
        isLoading: false,
      );
    } catch (e) {
      // Token expired or server unreachable — try refresh
      try {
        final refreshToken = await SecureStorageService.getRefreshToken().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final newTokens = await ApiService.refreshTokens(refreshToken).timeout(const Duration(seconds: 2));
          await SecureStorageService.setAccessToken(newTokens['access_token']!);
          await SecureStorageService.setRefreshToken(newTokens['refresh_token']!);
          ApiService.setToken(newTokens['access_token']!);

          final profile = await ApiService.getMe().timeout(const Duration(seconds: 2));
          state = AuthState(
            accessToken: newTokens['access_token'],
            refreshToken: newTokens['refresh_token'],
            userId: profile['user_id'],
            username: profile['username'],
            fullName: profile['full_name'],
            role: profile['role'],
            isLoading: false,
          );
          return;
        }
      } catch (_) {}

      // All failed — reset state safely
      try {
        await logout();
      } catch (_) {
        state = AuthState.initial;
      }
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
