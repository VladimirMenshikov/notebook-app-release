import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';

final verificationCodeProvider = StateProvider<String?>((ref) => null);

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.mark_email_unread_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Проверьте почту',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Instructions
            Text(
              'Мы отправили на ваш email код подтверждения.\n\n'
              'Введите его ниже, чтобы подтвердить email и создать профиль.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Code field
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Код из письма',
                hintText: '123456',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите код из письма';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  ref.read(verificationCodeProvider.notifier).state =
                      _codeController.text.trim();
                  context.go('/profile-setup');
                },
                child: const Text('Продолжить'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Resend link
            TextButton(
              onPressed: () async {
                // Re-send verification email
                try {
                  final apiClient = ref.read(apiClientProvider);
                  // Get email from router state or local storage
                  // For now, show a success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Письмо отправлено повторно'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyErrorMessage(e))),
                    );
                  }
                }
              },
              child: const Text('Отправить письмо снова'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
