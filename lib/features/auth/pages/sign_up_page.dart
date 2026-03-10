import 'package:flutter/material.dart';
import 'package:personal_fin/features/auth/view_models/sign_up_view_model.dart';
import 'package:provider/provider.dart';


class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpViewModel(),
      child: Consumer<SignUpViewModel>(
        builder: (context, vm, _) {
          final theme = Theme.of(context);
          
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text("Create Account"),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSignUpCard(context, vm, theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignUpCard(BuildContext context, SignUpViewModel vm, ThemeData theme) {
    return Card(
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sign Up", 
              style: theme.textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF0072FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(emailCtrl, "Email", Icons.email, TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(passCtrl, "Password", Icons.lock, TextInputType.text, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField(confirmPassCtrl, "Confirm Password", Icons.lock_outline, TextInputType.text, isObscure: true),
            const SizedBox(height: 32),
            _buildSubmitButton(context, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, SignUpViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: vm.isLoading ? null : () => _handleSignUp(context, vm),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: vm.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Logic Handler
  void _handleSignUp(BuildContext context, SignUpViewModel vm) async {
    final errorMessage = await vm.signUp(
      email: emailCtrl.text,
      password: passCtrl.text,
      confirmPassword: confirmPassCtrl.text,
    );

    if (!context.mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } else {
      // Success!
      Navigator.pop(context); 
    }
  }

  // Reusable TextField Helper
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, TextInputType type, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}