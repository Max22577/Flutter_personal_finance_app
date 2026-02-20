import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' ;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    // Note: If on Web, you must pass clientId here
    await _googleSignIn.initialize(); 
  }

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // 1. Authentication (Sign-in)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Get ID Token (Authentication info)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      // 3. Get Access Token (Authorization info - New step)
      // We request the basic profile scopes to ensure we get a valid access token
      final List<String> scopes = ['email', 'profile', 'openid'];
      final authorization = await googleUser.authorizationClient.authorizeScopes(scopes);
      final String accessToken = authorization.accessToken;

      if (idToken != null) {
        // 4. Create Firebase Credential
        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint("Google Auth Error: $e");
      rethrow;
    }
    return null;
  }


  // Sign Out
  Future<void> signOut() async => await _auth.signOut();

  // Stream for auth changes
  Stream<User?> get authState => _auth.authStateChanges();
}
