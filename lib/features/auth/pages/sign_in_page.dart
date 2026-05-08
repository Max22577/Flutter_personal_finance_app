import 'package:flutter/material.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/features/auth/view_models/sign_in_view_model.dart';
import 'package:personal_fin/features/auth/widgets/footer_link.dart';
import 'package:personal_fin/features/auth/widgets/sign_in_card.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignInViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey, 
                child: Column(
                  children: [
                    SignInCard(
                      vm: vm,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isPasswordVisible: _isPasswordVisible,
                      onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      onSignIn: () => _handleSignIn(context, vm),
                      onGoogleSignIn: () => _handleGoogleSignIn(context, vm),
                    ),
                    const SizedBox(height: 24),
                    FooterLink(
                      text: "New here?",
                      actionText: "Create a secure account",
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Logic Handlers ---
  Future<void> _handleSignIn(BuildContext context, SignInViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texttheme = theme.textTheme;
    
    final error = await vm.signIn(_emailController.text.trim(), _passwordController.text);
    if (error != null && context.mounted) {
      AppFeedback.show(messenger, error, colors: colors, textTheme: texttheme, isError: true);
    } else if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      AppFeedback.show(messenger, 'You have been logged in', colors: colors, textTheme: texttheme, isError: false);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context, SignInViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texttheme = theme.textTheme;

    final error = await vm.signInWithGoogle();
    if (error != null && context.mounted) {
      AppFeedback.show(messenger, error, colors: colors, textTheme: texttheme, isError: true);
    } else if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      AppFeedback.show(messenger, 'You have been logged in', colors: colors, textTheme: texttheme, isError: false);
    }
  }  
}


