import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/auth/presentation/screens/verify_email_screen.dart';

final selectedAvatarProvider = StateProvider<String?>((ref) => null);

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  
  final List<String> builtinAvatars = [
    'assets/avatars/cat_1.svg',
    'assets/avatars/cat_2.svg',
    'assets/avatars/cat_3.svg',
    'assets/avatars/cat_4.svg',
    'assets/avatars/cat_5.svg',
    'assets/avatars/cat_6.svg',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _setupProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final avatarName = ref.read(selectedAvatarProvider);
    if (avatarName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите аватар')),
      );
      return;
    }

    final code = ref.read(verificationCodeProvider);
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код подтверждения не найден, начните заново')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyEmail(
        code,
        _nameController.text.trim(),
        avatarName: avatarName.split('/').last,
      );

      if (mounted) {
        // Navigate to main app
        context.go('/notes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = ref.watch(selectedAvatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка профиля'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              Text(
                'Расскажите о себе',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите аватар и введите ваше имя',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              // Avatar selection
              Text(
                'Выберите аватар:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Avatar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: builtinAvatars.length,
                itemBuilder: (context, index) {
                  final avatarPath = builtinAvatars[index];
                  final isSelected = selectedAvatar == avatarPath;
                  
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedAvatarProvider.notifier).state = avatarPath;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: SvgPicture.asset(
                            avatarPath,
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Введите ваше имя',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setupProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Завершить регистрацию'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
