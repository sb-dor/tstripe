import 'package:flutter/material.dart';
import 'package:tstripe/src/features/authentication/widget/authentication_scope.dart';

/// {@template signin_screen}
/// Guest display-name entry screen.
/// {@endtemplate}
class SignInScreen extends StatefulWidget {
  /// {@macro signin_screen}
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  bool get _isValid => _nameController.text.trim().length >= 2;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters.');
      return;
    }
    setState(() => _nameError = null);
    AuthenticationScope.controllerOf(context).signIn(name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3460).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            size: 36,
                            color: Color(0xFF0F3460),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your display name to continue',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          autofocus: true,
                          maxLength: 30,
                          onChanged: (_) => setState(() => _nameError = null),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'e.g. Alex Johnson',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            errorText: _nameError,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0F3460), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _nameController,
                          builder: (context, _) => FilledButton(
                            onPressed: _isValid ? _submit : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F3460),
                              disabledBackgroundColor: const Color(
                                0xFF0F3460,
                              ).withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
