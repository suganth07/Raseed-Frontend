import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signInWithGoogle();

      if (result['success']) {
        _showToast(result['message'], isSuccess: true);

        if (mounted && AuthService.currentUserEmail != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: AuthService.currentUserEmail!,
              ),
            ),
          );
        } else {
          _showToast('Login successful but navigation failed. Please try again.', isSuccess: false);
        }
      } else {
        _showToast(result['message'], isSuccess: false);
      }
    } catch (e) {
      _showToast('Error during Google sign-in: \$e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        _showToast(result['message'], isSuccess: true);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: _emailController.text.trim(),
              ),
            ),
          );
        }
      } else {
        _showToast(result['message'], isSuccess: false);
      }
    } catch (e) {
      _showToast('Error during sign-in: \$e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message, {required bool isSuccess}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and title
                  Column(
                    children: [
                      const AppLogoWidget(),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Raseed',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email/Password Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign In Button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleEmailSignIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.g_mobiledata,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    label: const Text('Continue with Google'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign up'),
                      ),
                    ],
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
