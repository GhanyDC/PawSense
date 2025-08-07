import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final uid = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );
      if (uid != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              uid: uid,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _register,
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class VerifyEmailPage extends StatefulWidget {
  final String username;
  final String email;
  final String uid;
  const VerifyEmailPage({super.key, required this.username, required this.email, required this.uid});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _saved = false;
  bool _navigated = false;

  Future<void> _resendEmail() async {
    setState(() => _isLoading = true);
    await _authService.resendVerificationEmail();
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email resent.')),
    );
  }

  Future<void> _saveUserIfNeeded() async {
    final currentUser = _authService.currentUser;
    debugPrint('Attempting to save user. Current user: \\${currentUser?.uid}, email: \\${currentUser?.email}');
    if (!_saved && currentUser != null) {
      await _authService.saveUser(
        uid: widget.uid,
        username: widget.username,
        email: widget.email,
      );
      setState(() {
        _saved = true;
      });
    } else if (currentUser == null) {
      debugPrint('No authenticated user found when trying to save!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: StreamBuilder<bool>(
                  stream: _authService.emailVerifiedStream,
                  builder: (context, snapshot) {
                    final verified = snapshot.data ?? false;
                    if (verified && !_saved && !_navigated) {
                      _navigated = true;

                      _saveUserIfNeeded().then((_) {
                        if (mounted) {
                          setState(() {
                            _saved = true;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email verified!')),
                          );

                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      });

                      return const SizedBox.shrink();
                    } else if (_navigated) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'A verification email has been sent. Please check your inbox and click the link.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _resendEmail,
                          child: const Text('Resend Verification Email'),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
