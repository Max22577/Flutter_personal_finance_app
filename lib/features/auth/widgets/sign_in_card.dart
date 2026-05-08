import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:personal_fin/features/auth/view_models/sign_in_view_model.dart';

class SignInCard extends StatelessWidget {
  final SignInViewModel vm;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;

  const SignInCard({
    super.key,
    required this.vm,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    required this.onSignIn,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Welcome Back", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Sign in to manage your finances", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            
            // Email
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                labelText: "Email Address",
              ),
            ),
            const SizedBox(height: 16),

            // Password with Toggle
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleVisibility,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Main Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: vm.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Sign In"),
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
                onPressed: vm.isLoading ? null : onGoogleSignIn,
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
                          overflow: TextOverflow.ellipsis, 
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
}