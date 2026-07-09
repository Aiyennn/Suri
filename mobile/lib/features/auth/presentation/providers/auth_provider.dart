import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// ── Repository provider ────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── State ──────────────────────────────────────────────────────────────────

/// Represents all possible states of the authentication session.
sealed class AuthState {
  const AuthState();
}

/// No active session — the user needs to log in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Session is loading (startup token check, login, or register in progress).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session is active.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});
}

/// An auth operation failed.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// ── Notifier ───────────────────────────────────────────────────────────────

/// Manages authentication session state.
///
/// Initializes by checking for a persisted token on startup.
/// Exposes [login], [register], and [logout] actions.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthLoading()) {
    _tryRestoreSession();
  }

  // ── Startup ───────────────────────────────────────────────────────────────

  /// Checks for a saved token and fetches the user profile if one exists.
  Future<void> _tryRestoreSession() async {
    final token = await _repo.readToken();
    if (token == null) {
      state = const AuthUnauthenticated();
      return;
    }
    // No /me call here for simplicity — we mark as unauthenticated so the
    // user logs in again if the token expired. Add a /me call for a better UX.
    state = const AuthUnauthenticated();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Log in with email and password.
  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _repo.login(email: email, password: password);
      await _repo.saveToken(result.token.accessToken);
      state = AuthAuthenticated(
        user: result.user,
        token: result.token.accessToken,
      );
    } on String catch (message) {
      state = AuthError(message);
    } catch (_) {
      state = const AuthError('Unable to connect. Check your network and try again.');
    }
  }

  /// Register a new account.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? sex,
    String? dateOfBirth,
    String? medicalHistory,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        sex: sex,
        dateOfBirth: dateOfBirth,
        medicalHistory: medicalHistory,
      );
      await _repo.saveToken(result.token.accessToken);
      state = AuthAuthenticated(
        user: result.user,
        token: result.token.accessToken,
      );
    } on String catch (message) {
      state = AuthError(message);
    } catch (_) {
      state = const AuthError('Unable to connect. Check your network and try again.');
    }
  }

  /// Clear the stored token and return to unauthenticated state.
  Future<void> logout() async {
    await _repo.deleteToken();
    state = const AuthUnauthenticated();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Convenience provider that returns the current [UserModel] or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.user : null;
});

/// Convenience provider that returns the current JWT token string or null.
final currentTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.token : null;
});
