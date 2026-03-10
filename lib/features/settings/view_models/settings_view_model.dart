import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? get user => _auth.currentUser;
  
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  // Pick image from gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  // Update logic
  Future<bool> updateProfile(String displayName) async {
    if (user == null) return false;
    _isBusy = true;
    notifyListeners();

    try {
      String? photoUrl = user?.photoURL;

      // 1. Upload image if changed
      if (_selectedImage != null) {
        final ref = _storage.ref().child('profile_pics/${user!.uid}.jpg');
        await ref.putFile(_selectedImage!);
        photoUrl = await ref.getDownloadURL();
      }

      // 2. Update Auth Profile
      await user!.updateDisplayName(displayName.trim());
      await user!.updatePhotoURL(photoUrl);
      await user!.reload();
      
      _selectedImage = null; // Reset local selection on success
      return true;
    } catch (e) {
      debugPrint("Update Error: $e");
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}