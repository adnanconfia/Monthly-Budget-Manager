import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_expense_tracker/controllers/auth_controller.dart';
// Apne premium home screen ka sahi import path yahan confirm kar lein:
import 'package:daily_expense_tracker/views/home/premium_home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;

  const OTPScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
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
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We have sent a 6-digit verification code to',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 6-Digit Code Input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (val.trim().length < 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verify Button
                  Obx(() => ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await authController.verifyOtpAndSignUp(
                          name: widget.name,
                          email: widget.email,
                          phone: widget.phone,
                          password: widget.password,
                          enteredOtp: _otpController.text,
                        );

                        // Debug print to check API result in console
                        print("OTP Verification Result: $success");

                        if (success) {
                          // Direct navigation to PremiumHomeScreen
                          Get.offAll(() => const PremiumHomeScreen());
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: authController.isLoading.value
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                  const SizedBox(height: 20),

                  // 60s Timer & Resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResend ? "Didn't receive code? " : "Resend Code in ",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      _canResend
                          ? GestureDetector(
                        onTap: () async {
                          final sent = await authController.sendOTP(widget.email);
                          if (sent) {
                            startTimer();
                          }
                        },
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                          : Text(
                        '(${_start}s)',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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