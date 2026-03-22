import 'package:flutter/material.dart';
import 'package:tstripe/src/features/authentication/controller/authentication_controller.dart';
import 'package:tstripe/src/features/authentication/widget/authentication_scope.dart';

/// {@template signin_screen}
/// Sign-in / register screen with email + password auth.
/// {@endtemplate}
class SignInScreen extends StatefulWidget {
  /// {@macro signin_screen}
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isRegister = false;
  bool _obscurePassword = true;
  late final AuthenticationController _controller;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _controller = AuthenticationScope.controllerOf(context);
  }

  bool get _isValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    if (email.isEmpty || !email.contains('@')) return false;
    if (password.length < 6) return false;
    if (_isRegister && name.length < 2) return false;
    return true;
  }

  void _submit(AuthenticationController controller) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    var hasError = false;

    if (_isRegister && name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters.');
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address.');
      hasError = true;
    } else {
      setState(() => _emailError = null);
    }

    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      hasError = true;
    } else {
      setState(() => _passwordError = null);
    }

    if (hasError) return;

    if (_isRegister) {
      controller.register(name: name, email: email, password: password);
    } else {
      controller.signIn(email: email, password: password);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final state = _controller.state;
        final isInProgress = state is Authentication$InProgressState;
        final errorMessage = state is Authentication$ErrorState ? state.error : null;
        return PopScope(
          canPop: !isInProgress,
          child: Scaffold(
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
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F3460).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 36,
                                    color: Color(0xFF0F3460),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _isRegister ? 'Create Account' : 'Welcome Back',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRegister
                                    ? 'Sign up to start shopping'
                                    : 'Sign in to your account',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error banner
                              if (errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: theme.colorScheme.onErrorContainer,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Name field (register only)
                              if (_isRegister) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Name',
                                  hint: 'e.g. Alex',
                                  icon: Icons.person_outline_rounded,
                                  errorText: _nameError,
                                  enabled: !isInProgress,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() => _nameError = null),
                                  onSubmitted: (_) => _submit(_controller),
                                  theme: theme,
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Email field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'alex@example.com',
                                icon: Icons.email_outlined,
                                errorText: _emailError,
                                enabled: !isInProgress,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => setState(() => _emailError = null),
                                onSubmitted: (_) => _submit(_controller),
                                theme: theme,
                                autoCorrect: false,
                              ),
                              const SizedBox(height: 14),

                              // Password field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••',
                                icon: Icons.lock_outline_rounded,
                                errorText: _passwordError,
                                enabled: !isInProgress,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                onChanged: (_) => setState(() => _passwordError = null),
                                onSubmitted: (_) => _submit(_controller),
                                theme: theme,
                              ),
                              const SizedBox(height: 24),

                              // Submit button
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _nameController,
                                  _emailController,
                                  _passwordController,
                                ]),
                                builder: (context, _) => FilledButton(
                                  onPressed: (_isValid && !isInProgress)
                                      ? () => _submit(_controller)
                                      : null,
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
                                  child: isInProgress
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isRegister ? 'Create Account' : 'Sign In',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Toggle login / register
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isRegister
                                        ? 'Already have an account?'
                                        : "Don't have an account?",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isInProgress ? null : _toggleMode,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _isRegister ? 'Sign In' : 'Register',
                                      style: const TextStyle(
                                        color: Color(0xFF0F3460),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    String? errorText,
    bool enabled = true,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool autoCorrect = true,
  }) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    autocorrect: autoCorrect,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),

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
  );
}
