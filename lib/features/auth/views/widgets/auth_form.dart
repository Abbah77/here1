import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../../home/views/screens/main_screen.dart';

class AuthForm extends HookConsumerWidget {
  final bool isLogin;

  const AuthForm({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final theme = Theme.of(context);

    // Watch auth state for loading indicators
    final authState = ref.watch(authStateProvider);
    
    // Access the service for login/register calls
    final authService = ref.read(authServiceProvider);
    
    // Username availability check logic
    final usernameAsync = !isLogin && usernameController.text.isNotEmpty
        ? ref.watch(usernameAvailabilityProvider(usernameController.text))
        : const AsyncValue.data(null);

    // Input formatter for clean usernames
    final usernameFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'[a-zA-Z0-9._]'),
    );

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      bool success = false;
      
      try {
        if (isLogin) {
          // LOGIN LOGIC
          final response = await authService.login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
          
          // FIXED: We check for 'access_token' to match your Python/OAuth2 backend
          success = response['access_token'] != null || response['token'] != null;
          debugPrint('🔑 Login check: Token received = $success');
        } else {
          // SIGNUP LOGIC
          final isAvailable = usernameAsync.value ?? false;
          if (!isAvailable) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username is already taken'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          final response = await authService.register(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            username: usernameController.text.trim(),
            password: passwordController.text,
          );
          success = response['access_token'] != null || response['token'] != null;
        }

        if (success && context.mounted) {
          // Successfully logged in/registered, go to Home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        } else if (context.mounted) {
          throw Exception('Missing token in server response');
        }
      } catch (e) {
        debugPrint('❌ Authentication Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLogin 
                    ? 'Login failed. Check your credentials.'
                    : 'Registration failed. Please try again.'
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Form(
      key: formKey,
      child: Column(
        children: [
          // Name Field (only for signup)
          if (!isLogin) ...[
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (!isLogin && (value == null || value.isEmpty)) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Email Field
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Username Field (only for signup)
          if (!isLogin) ...[
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter unique username',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: usernameController.text.isNotEmpty
                    ? usernameAsync.when(
                        data: (isAvailable) {
                          if (isAvailable == null) return null;
                          return Icon(
                            isAvailable ? Icons.check_circle : Icons.error,
                            color: isAvailable ? Colors.green : Colors.red,
                          );
                        },
                        error: (_, __) => const Icon(Icons.error, color: Colors.red),
                        loading: () => const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : null,
              ),
              inputFormatters: [usernameFormatter],
              validator: (value) {
                if (!isLogin && (value == null || value.isEmpty)) {
                  return 'Please enter a username';
                }
                if (value != null && value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
              onChanged: (_) {
                formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Password Field
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => isPasswordVisible.value = !isPasswordVisible.value,
              ),
            ),
            obscureText: !isPasswordVisible.value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!isLogin && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          // Forgot Password (only for login)
          if (isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(context, ref),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: authState == AuthStatus.authenticating 
                  ? null 
                  : handleSubmit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: authState == AuthStatus.authenticating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLogin ? 'Login' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(context);
              
              try {
                final authService = ref.read(authServiceProvider);
                await authService.resetPassword(emailController.text);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset link sent to your email'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset link: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
