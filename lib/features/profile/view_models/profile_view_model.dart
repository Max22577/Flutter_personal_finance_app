import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // State variables
  bool isLoading = true;
  String? fullName;
  String? bio;
  String? photoUrl;
  String authEmail = 'Loading...';
  
  StreamSubscription? _profileSubscription;

  ProfileViewModel() {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    authEmail = user.email ?? 'N/A';
    photoUrl = user.photoURL;

    // Listen to profile changes in real-time
    _profileSubscription = _getProfileDocRef(user.uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        fullName = data['fullName'] ?? user.displayName;
        bio = data['bio'] ?? '';
      } else {
        fullName = user.displayName;
        bio = '';
      }
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      isLoading = false;
      notifyListeners();
    });
  }

  DocumentReference _getProfileDocRef(String userId) {
    const String appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
    return _db.collection('artifacts').doc(appId).collection('users').doc(userId)
        .collection('profile_data').doc('details_doc');
  }

  Future<void> updateProfile({required String name, required String newBio}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      await _getProfileDocRef(user.uid).set({
        'fullName': name,
        'bio': newBio,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(name);
      await user.reload();
      
      // Local update
      fullName = name;
      bio = newBio;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}