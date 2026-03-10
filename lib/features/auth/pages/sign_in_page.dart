import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:personal_fin/features/auth/view_models/sign_in_view_model.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignInViewModel(),
      child: Consumer<SignInViewModel>(
        builder: (context, vm, _) {
          final theme = Theme.of(context);
          
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSignInCard(context, vm, theme),
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
        },
      ),
    );
  }

  Widget _buildSignInCard(BuildContext context, SignInViewModel vm, ThemeData theme) {
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                onPressed: vm.isLoading ? null : () => _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: vm.isLoading
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
                onPressed: vm.isLoading ? null : () => vm.signInWithGoogle(),
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
    );
  }

  void _handleSignIn(BuildContext context, SignInViewModel vm) async {
    final error = await vm.signIn(emailCtrl.text, passCtrl.text);
    if (error != null && context.mounted) {
      _showErrorSnackBar(context, error);
    } else if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
  
}