/// Sign Up Page
///
/// Allows users to create a new account with email, password, and other details.
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verify_email_page.dart';
import 'terms_and_conditions_modal.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Widget for the sign up page.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

/// State for SignUpPage.
class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordFeedback;

  // Track if user has interacted with each field
  final Map<String, bool> _fieldTouched = {
    'username': false,
    'email': false,
    'contact': false,
    'address': false,
    'password': false,
    'confirmPassword': false,
  };

  @override
  void dispose() {
    for (var c in [
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _contactController,
      _addressController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _showSnack('Please select your date of birth');
      return;
    }
    if (!_agreedToTerms) {
      _showSnack('You must agree to the terms');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usernameTaken = await _authService.isUsernameTaken(
        _usernameController.text.trim(),
      );
      if (usernameTaken) {
        _showSnack('Username is already taken');
        setState(() => _isLoading = false);
        return;
      }

      final uid = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        agreedToTerms: _agreedToTerms,
        address: _addressController.text.trim(),
      );

      if (uid != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              uid: uid,
              contactNumber: _contactController.text.trim(),
              dateOfBirth: _dateOfBirth!,
              agreedToTerms: _agreedToTerms,
              address: _addressController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack('Sign up failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        keyName: 'username',
                        controller: _usernameController,
                        label: 'Username',
                        validator: (v) => requiredValidator(v, 'Username'),
                        icon: Icons.person_outline,
                      ),
                      _buildTextField(
                        keyName: 'email',
                        controller: _emailController,
                        label: 'Email',
                        validator: emailValidator,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        keyName: 'contact',
                        controller: _contactController,
                        label: 'Contact Number',
                        keyboardType: TextInputType.phone,
                        validator: phoneValidator,
                        icon: Icons.phone,
                      ),
                      _buildTextField(
                        keyName: 'address',
                        controller: _addressController,
                        label: 'Address',
                        validator: (v) => requiredValidator(v, 'Address'),
                        icon: Icons.home_outlined,
                      ),
                      _buildDOBPicker(),
                      // Password field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autovalidateMode: _fieldTouched['password']!
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final result = passwordValidator(value);
                    
                            return result;
                          },
                          onChanged: (_) {
                            if (!_fieldTouched['password']!) {
                              setState(() => _fieldTouched['password'] = true);
                            } else {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      if (_passwordFeedback != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _passwordFeedback!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      // Confirm Password field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          autovalidateMode: _fieldTouched['confirmPassword']!
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (v) => confirmPasswordValidator(
                            v,
                            _passwordController.text,
                          ),
                          onChanged: (_) {
                            if (!_fieldTouched['confirmPassword']!) {
                              setState(
                                () => _fieldTouched['confirmPassword'] = true,
                              );
                            } else {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _agreedToTerms ? _register : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _agreedToTerms
                              ? Colors.blueAccent
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: _agreedToTerms
                                ? Colors.white
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?'),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/signin',
                            ),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autovalidateMode: _fieldTouched[keyName]!
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator:
            validator ?? (v) => v == null || v.isEmpty ? 'Enter $label' : null,
        onChanged: (_) {
          if (!_fieldTouched[keyName]!) {
            setState(() => _fieldTouched[keyName] = true);
          } else {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildDOBPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000, 1, 1),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              hintText: 'Select your date of birth',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            controller: TextEditingController(
              text: _dateOfBirth == null
                  ? ''
                  : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
            ),
            readOnly: true,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (val) async {
            if (val == true && !_agreedToTerms) {
              final agreed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => const TermsAndConditionsModal(),
              );
              setState(() => _agreedToTerms = agreed == true);
            } else if (val == false) {
              setState(() => _agreedToTerms = false);
            }
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (!_agreedToTerms) {
                final agreed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const TermsAndConditionsModal(),
                );
                setState(() => _agreedToTerms = agreed == true);
              } else {
                setState(() => _agreedToTerms = false);
              }
            },
            child: const Text('I agree to the Terms and Conditions'),
          ),
        ),
      ],
    );
  }
}

