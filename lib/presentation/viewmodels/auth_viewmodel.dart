// File: viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/storage_service.dart';

enum AuthState {
  initial,
  loading,
  googleLoading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  User? _currentUser;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isInitialized = false;

  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;
  bool get isGoogleLoading => _state == AuthState.googleLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get acceptTerms => _acceptTerms;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get shouldShowOnboarding => !StorageService.hasCompletedOnboarding;

  // GoogleSignIn instance avec configuration corrigée
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Pour Android, utiliser le client ID Android depuis google-services.json
    // Pour iOS, utiliser le client ID iOS depuis GoogleService-Info.plist
    // Pour Web, spécifier le client ID Web explicitement
    clientId: '739591056554-l25mkgvuibj557j7e1tgbhn2h4l0ic9l.apps.googleusercontent.com', // Client ID Web
    scopes: [
      'email',
      'profile',
      'openid', // Ajout du scope openid
    ],
  );

  AuthViewModel() {
    _initAuthListener();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('🔍 Initializing AuthViewModel...');
      
      // Initialiser les services nécessaires
      await StorageService.init();
      print('✅ StorageService initialized');
      
      // Vérifier si l'utilisateur est déjà connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('✅ User already authenticated: ${currentUser.email}');
        _currentUser = currentUser;
        _state = AuthState.authenticated;
      } else {
        print('ℹ️ No authenticated user found');
        _state = AuthState.unauthenticated;
      }
      
      _isInitialized = true;
      print('✅ AuthViewModel initialized successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
      _isInitialized = true;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('🔄 Auth state changed: ${user?.email ?? 'null'}');
      _currentUser = user;
      if (_isInitialized) {
        _state = user != null ? AuthState.authenticated : AuthState.unauthenticated;
        notifyListeners();
      }
    });
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void setAcceptTerms(bool value) {
    _acceptTerms = value;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    print('🔍 Starting anonymous sign in...');
    _setState(AuthState.loading);

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      
      if (userCredential.user != null) {
        print('✅ Anonymous sign in successful');
        _currentUser = userCredential.user;
        await _saveUserLocally(userCredential.user!);
        _setState(AuthState.authenticated);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ Anonymous sign in failed: ${e.message}');
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      print('❌ Anonymous sign in error: $e');
      _setError('Erreur lors de la connexion anonyme');
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔍 Starting email sign in for: $email');
    _setState(AuthState.loading);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        print('✅ Email sign in successful');
        _currentUser = userCredential.user;
        await _saveUserLocally(userCredential.user!);
        _setState(AuthState.authenticated);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ Email sign in failed: ${e.message}');
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      print('❌ Email sign in error: $e');
      _setError('Une erreur inattendue s\'est produite');
      return false;
    }
  }

  // Create user with email and password
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_acceptTerms) {
      _setError('Veuillez accepter les conditions d\'utilisation');
      return false;
    }

    print('🔍 Starting user creation for: $email');
    _setState(AuthState.loading);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName.trim());
        await userCredential.user!.reload();
        
        print('✅ User creation successful');
        _currentUser = FirebaseAuth.instance.currentUser;
        await _saveUserLocally(_currentUser!);
        _setState(AuthState.authenticated);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ User creation failed: ${e.message}');
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      print('❌ User creation error: $e');
      _setError('Une erreur inattendue s\'est produite');
      return false;
    }
  }

  // Sign in with Google - VERSION CORRIGÉE
  Future<bool> signInWithGoogle() async {
    print('🔍 Starting Google sign in...');
    _setState(AuthState.googleLoading);

    try {
      // 1. S'assurer que GoogleSignIn est initialisé
      await _googleSignIn.signOut(); // Nettoyer l'état précédent
      
      print('🔍 Initiating Google Sign-In flow...');
      
      // 2. Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // 3. Vérifier si l'utilisateur a annulé
      if (googleUser == null) {
        print('ℹ️ User cancelled Google Sign-In');
        _setState(AuthState.unauthenticated);
        return false;
      }
      
      print('✅ Google user selected: ${googleUser.email}');

      // 4. Obtenir les tokens d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('🔍 Google auth tokens obtained');
      print('Access token: ${googleAuth.accessToken != null ? "✅" : "❌"}');
      print('ID token: ${googleAuth.idToken != null ? "✅" : "❌"}');

      // 5. Vérifier que les tokens sont disponibles
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      // 6. Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔍 Firebase credential created, signing in...');

      // 7. Se connecter à Firebase avec les credentials
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('✅ Firebase authentication successful: ${userCredential.user?.email}');
        _currentUser = userCredential.user;
        await _saveUserLocally(userCredential.user!);
        _setState(AuthState.authenticated);
        return true;
      } else {
        throw Exception('Firebase authentication returned null user');
      }
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      await _cleanupGoogleSignIn();
      _handleFirebaseError(e);
      return false;
    } on Exception catch (e) {
      print('❌ Google Sign-In Exception: $e');
      await _cleanupGoogleSignIn();
      _setError('Échec de la connexion Google: ${e.toString()}');
      return false;
    } catch (e) {
      print('❌ Unexpected Google Sign-In Error: $e');
      await _cleanupGoogleSignIn();
      _setError('Une erreur inattendue s\'est produite lors de la connexion Google');
      return false;
    }
  }

  // Méthode helper pour nettoyer l'état Google Sign-In
  Future<void> _cleanupGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      print('⚠️ Error during Google Sign-In cleanup: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    print('🔍 Sending password reset for: $email');
    _setState(AuthState.loading);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      print('✅ Password reset email sent');
      _setState(AuthState.unauthenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset failed: ${e.message}');
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      print('❌ Password reset error: $e');
      _setError('Erreur lors de l\'envoi de l\'email');
      return false;
    }
  }

  // Sign out - VERSION AMÉLIORÉE
  Future<void> signOut() async {
    print('🔍 Starting sign out...');
    
    try {
      // Déconnexion simultanée de Firebase et Google
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        _googleSignIn.signOut(),
        _googleSignIn.disconnect(), // Déconnexion complète de Google
      ]);
      
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      print('✅ Sign out successful');
    } catch (e) {
      print('⚠️ Error during sign out: $e');
      // Forcer la déconnexion même en cas d'erreur
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e2) {
        print('⚠️ Error during Firebase sign out: $e2');
      }
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    }
  }

  // Private methods
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = AuthState.error;
    notifyListeners();
  }

  Future<void> _saveUserLocally(User user) async {
    try {
      // Sauvegarder les informations utilisateur avec votre StorageService
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'isAnonymous': user.isAnonymous,
        'lastLoginAt': DateTime.now().toIso8601String(),
        'providerData': user.providerData.map((p) => {
          'providerId': p.providerId,
          'uid': p.uid,
          'displayName': p.displayName,
          'email': p.email,
          'photoURL': p.photoURL,
        }).toList(),
      };
      
      await StorageService.put('current_user', userData);
      await StorageService.setOnboardingCompleted(true);
      print('✅ User data saved locally');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'Aucun utilisateur trouvé avec cet email';
        break;
      case 'wrong-password':
        message = 'Mot de passe incorrect';
        break;
      case 'email-already-in-use':
        message = 'Un compte existe déjà avec cet email';
        break;
      case 'weak-password':
        message = 'Le mot de passe est trop faible';
        break;
      case 'invalid-email':
        message = 'Email invalide';
        break;
      case 'user-disabled':
        message = 'Ce compte a été désactivé';
        break;
      case 'too-many-requests':
        message = 'Trop de tentatives. Veuillez réessayer plus tard';
        break;
      case 'operation-not-allowed':
        message = 'Cette méthode de connexion n\'est pas activée';
        break;
      case 'account-exists-with-different-credential':
        message = 'Un compte existe avec cet email mais avec une méthode de connexion différente';
        break;
      case 'credential-already-in-use':
        message = 'Ces identifiants sont déjà utilisés par un autre compte';
        break;
      case 'invalid-credential':
        message = 'Identifiants invalides';
        break;
      case 'network-request-failed':
        message = 'Erreur de connexion réseau. Vérifiez votre connexion internet';
        break;
      case 'popup-closed-by-user':
        message = 'Fenêtre de connexion fermée par l\'utilisateur';
        break;
      case 'cancelled-popup-request':
        message = 'Demande de connexion annulée';
        break;
      default:
        message = e.message ?? 'Erreur d\'authentification';
        print('🔍 Unhandled Firebase Auth error: ${e.code} - ${e.message}');
    }
    _setError(message);
  }

  @override
  void dispose() {
    print('🗑️ Disposing AuthViewModel');
    super.dispose();
  }

  // Placeholder methods for future implementation
  signInWithFacebook() {
    // TODO: Implement Facebook Sign-In
  }

  signInWithApple() {
    // TODO: Implement Apple Sign-In
  }
}