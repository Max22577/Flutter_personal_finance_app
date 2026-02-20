import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/services/auth_service.dart';

String getFriendlyErrorMessage(dynamic error) {
  // If the error object has a 'code' property (common in backend SDKs)
  if (error is FirebaseAuthException) { 
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'The password you entered is incorrect.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
  
  // For generic or non-specific errors
  return 'Login failed. Please check your network connection.';
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();
  bool loading = false;

  void signIn() async {
    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      await auth.signIn(emailCtrl.text.trim(), passCtrl.text.trim());
    } catch (e) {
      // 1. Get the friendly message
      final String friendlyMessage = getFriendlyErrorMessage(e); 
      
      // 2. Display the friendly message 
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyMessage,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
    if (!mounted) return;

    setState(() => loading = false);
  }

  void handleGoogleSignIn() async {
    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final user = await auth.signInWithGoogle();
      if (user != null && mounted) {
        // Success! Navigate away
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Google Sign-In failed. Please try again.",
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Prevents overflow on smaller screens
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Card(
                  elevation: 4, // Lower elevation for a "flatter" modern look
                  shadowColor: colors.shadow.withValues(alpha: 0.1),
                  color: colors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome Back",
                          style: text.titleLarge?.copyWith(letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue managing your finances",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 25),

                        // Email Field
                        TextFormField(
                          controller: emailCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelText: "Email Address",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            labelText: "Password",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.secondary,
                              foregroundColor: colors.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: Colors.grey))),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Standard Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: OutlinedButton(
                            onPressed: loading ? null : handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center, 
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                SvgPicture.asset(
                                  'assets/images/google_icon.svg',
                                  height: 25,
                                  width: 25,
                                ),
                                const SizedBox(width: 4),
                                // Flexible ensures the text stays within bounds if the screen is tiny
                                Flexible(
                                  child: Text(
                                    "Continue with Google",
                                    style: text.labelLarge?.copyWith(
                                      color: colors.onSurface, 
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis, // Adds '...' if still too long
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("New here? Create a secure account", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
