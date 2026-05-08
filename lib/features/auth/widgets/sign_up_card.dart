import 'package:flutter/material.dart';
import 'package:personal_fin/features/auth/view_models/sign_up_view_model.dart';

class SignUpCard extends StatelessWidget {
  final SignUpViewModel vm;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSignUp;

  const SignUpCard({
    super.key,
    required this.vm,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF0072FF);

    return Card(
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              "Create Account",
              style: theme.textTheme.headlineSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Email Field
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                labelText: "Email Address",
              ),
              validator: (val) => (val == null || !val.contains('@')) ? "Enter a valid email" : null,
            ),
            const SizedBox(height: 16),

            // Password Field
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
              validator: (val) => (val == null || val.length < 6) ? "Password too short" : null,
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: confirmPasswordController,
              obscureText: !isPasswordVisible,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_reset_outlined),
                labelText: "Confirm Password",
              ),
              validator: (val) => val != passwordController.text ? "Passwords do not match" : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}