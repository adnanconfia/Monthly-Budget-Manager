import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_expense_tracker/controllers/auth_controller.dart';
import 'package:daily_expense_tracker/views/auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variables for real-time password validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasNoSpaces = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordChecklist);
  }

  void _updatePasswordChecklist() {
    final val = _passwordController.text;
    setState(() {
      _hasMinLength = val.length >= 8;
      _hasUppercase = val.contains(RegExp(r'[A-Z]'));
      _hasLowercase = val.contains(RegExp(r'[a-z]'));
      _hasNumber = val.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>\-\_=\+\[\]\\/;\`~]'));
      _hasNoSpaces = val.isNotEmpty && val == val.trim();
    });
  }

  // Calculate Password Strength Score (0 to 6)
  int get _strengthScore {
    if (_passwordController.text.isEmpty) return 0;
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    if (_hasNoSpaces) score++;
    return score;
  }

  // Get matching Label
  String get _strengthLabel {
    if (_strengthScore == 0) return '';
    if (_strengthScore < 3) return 'Weak';
    if (_strengthScore < 6) return 'Medium';
    return 'Strong ✓';
  }

  // Get matching Color
  Color get _strengthColor {
    if (_strengthScore == 0) return Colors.grey;
    if (_strengthScore < 3) return Colors.red;
    if (_strengthScore < 6) return Colors.amber;
    return const Color(0xFF10B981);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordChecklist);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Modern Material 3 Dialog for Password Requirements
  void _showPasswordHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final bool isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          elevation: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Text('🔐', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Strong Password Guide',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'A strong password protects your account and your financial data.\n\nTo create a secure password, make sure it meets the following requirements:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Requirements Checklist
                _buildDialogChecklistItem('At least 8 characters', isDark),
                _buildDialogChecklistItem('One uppercase letter (A–Z)', isDark),
                _buildDialogChecklistItem('One lowercase letter (a–z)', isDark),
                _buildDialogChecklistItem('One number (0–9)', isDark),
                _buildDialogChecklistItem('One special character (! @ # \$ % ^ & *)', isDark),
                _buildDialogChecklistItem('No leading or trailing spaces', isDark),
                const SizedBox(height: 20),

                // Tips Section
                Text(
                  '💡 Tips',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogTipItem('Avoid using your name.', isDark),
                _buildDialogTipItem('Avoid your birth date.', isDark),
                _buildDialogTipItem('Don\'t use "123456" or "password".', isDark),
                _buildDialogTipItem('Mix uppercase, lowercase, numbers and symbols.', isDark),
                _buildDialogTipItem('Use something unique that only you can remember.', isDark),
                const SizedBox(height: 24),

                // Example Strong Password
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Example Strong Password',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Finance#Tracker2026',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogChecklistItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTipItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your daily expenses today',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    validator: authController.validateFullName,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Address
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: authController.validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: authController.validatePhone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Obx(() => TextFormField(
                    controller: _passwordController,
                    obscureText: authController.obscurePassword.value,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSpecialChar || !_hasNoSpaces) {
                        return 'Please meet all password requirements';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(authController.obscurePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: authController.togglePasswordVisibility,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  )),
                  const SizedBox(height: 12),

                  // Premium Password Strength Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password Strength',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _strengthLabel,
                              key: ValueKey<String>(_strengthLabel),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _strengthColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: _strengthScore / 6.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              color: _strengthColor,
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // "How to create a strong password?" Help Link
                      GestureDetector(
                        onTap: () => _showPasswordHelpDialog(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'How to create a strong password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  Obx(() => TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: authController.obscureConfirmPassword.value,
                    validator: (val) => authController.validateConfirmPassword(_passwordController.text, val),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(authController.obscureConfirmPassword.value
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: authController.toggleConfirmPasswordVisibility,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  )),
                  const SizedBox(height: 24),

                  // Signup Button
                  Obx(() => ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await authController.signUp(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _phoneController.text.trim(),
                          _passwordController.text,
                        );

                        if (success) {
                          await Future.delayed(const Duration(seconds: 1));
                          Get.offAll(() =>  LoginScreen());
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    child: authController.isLoading.value
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                  const SizedBox(height: 20),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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