import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../providers/auth_notifier.dart';
import '../utils/form_validators.dart';

/// Reset Password screen (after user clicks email link)
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordResetSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(
            _passwordController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _passwordResetSuccess = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lozinka je uspješno promijenjena!'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto-redirect to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.goToLogin();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Molimo potvrdite lozinku';
    }
    if (value != _passwordController.text) {
      return 'Lozinke se ne poklapaju';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postavi novu lozinku'),
        leading: _passwordResetSuccess
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.goToLogin(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _passwordResetSuccess
                  ? _buildSuccessView()
                  : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Postavi novu lozinku',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Unesite vašu novu lozinku. Lozinka mora imati najmanje 6 karaktera.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textColorSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // New password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Nova lozinka',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: FormValidators.validatePassword,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Potvrdi lozinku',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: _validateConfirmPassword,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: 32),

          // Reset button
          FilledButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.textColorInverted,
                    ),
                  )
                : const Text('Resetuj lozinku'),
          ),
          const SizedBox(height: 16),

          // Back to login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Odustani?',
                style: TextStyle(color: context.textColorSecondary),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.goToLogin(),
                child: const Text('Nazad na prijavu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'Lozinka promijen jena!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Message
        Text(
          'Vaša lozinka je uspješno promijenjena. Sada se možete prijaviti sa novom lozinkom.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.textColorSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Auto-redirect message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: context.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preusmeravamo vas na stranicu za prijavu...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.primaryColor,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manual redirect button
        FilledButton(
          onPressed: () => context.goToLogin(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Prijavi se sada'),
        ),
      ],
    );
  }
}
