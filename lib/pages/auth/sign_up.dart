import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

String getFriendlyErrorMessage(dynamic error) {
  // Add more specific error handling based on your actual authentication service (e.g., Firebase)
  // For now, we'll check for generic issues.
  if (error.toString().contains('weak-password')) {
    return 'The password is too weak. It must be at least 6 characters long.';
  }
  if (error.toString().contains('email-already-in-use')) {
    return 'An account already exists for that email address.';
  }
  return 'Registration failed. Please try again or check your email format.';
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers to capture user input
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController(); // NEW: Controller for confirmation field
  
  // Service instance for authentication calls
  final auth = AuthService();
  
  // State to manage the loading spinner and button
  bool loading = false;

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the tree
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  void showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void signUp() async {
    // 1. Basic password validation check
    if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
      showSnackbar("Error: Passwords do not match. Please re-enter.");
      return; // Stop the function here if they don't match
    }

    setState(() => loading = true);

    try {
      // 2. Attempt the sign-up call to the backend
      await auth.signUp(emailCtrl.text.trim(), passCtrl.text.trim());
      
      // Check mounted state before navigating away
      if (!mounted) return; 

      // 3. On success, close the Sign Up page and return to the Sign In page
      Navigator.pop(context);
    } catch (e) {
      // 4. On failure, catch the error and display a friendly message
      final String friendlyMessage = getFriendlyErrorMessage(e);
      showSnackbar(friendlyMessage);
    }

    // 5. Always stop the loading spinner (unless the widget was disposed)
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: const Color(0xFF0072FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Blue Gradient Background
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 30,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0072FF),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Email",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Password",
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // NEW: Confirm Password Field
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
                      labelText: "Confirm Password",
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: loading ? null : signUp, // Disabled if loading is true
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0072FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
