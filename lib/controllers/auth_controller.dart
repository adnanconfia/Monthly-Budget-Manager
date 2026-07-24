import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:daily_expense_tracker/controllers/expense_controller.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Rxn<User> firebaseUser = Rxn<User>();
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

  // In-memory OTP storage (no DB entries)
  String? _generatedOtp;
  DateTime? _otpExpiry;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

  // --- Strict Validations ---
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 3) return 'Minimum 3 characters required';
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(value.trim())) return 'No numbers or special characters allowed';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email format (e.g., abc@gmail.com)';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain one uppercase letter';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Must contain one lowercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain one number';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Must contain one special character';
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match.';
    return null;
  }

  // --- Send 6-digit OTP directly to Gmail via EmailJS REST API ---
  Future<bool> sendOTP(String email) async {
    try {
      isLoading.value = true;

      // 1. Generate 6-digit random code
      _generatedOtp = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
      _otpExpiry = DateTime.now().add(const Duration(seconds: 60));

      // 2. EmailJS Keys (Replace with your actual keys from EmailJS Dashboard)
      const serviceId = 'service_w3qluoa';
      const templateId = 'template_rf6pxkc';
      const userId = 'CrEzl2yxw1BCS25EO';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': email.trim(),
            'otp_code': _generatedOtp,
          },
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'OTP Sent',
          'Verification code sent to $email',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        // Print exact error response from EmailJS to debug console
        print('EmailJS Error: ${response.body}');
        Get.snackbar(
            'Error',
            'Failed: ${response.body}',
            backgroundColor: Colors.red,
            colorText: Colors.white
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Verify OTP, Create Firebase Account & Auto Login ---
  Future<bool> verifyOtpAndSignUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String enteredOtp,
  }) async {
    try {
      isLoading.value = true;

      // Expiry validation check
      if (_otpExpiry == null || DateTime.now().isAfter(_otpExpiry!.add(const Duration(minutes: 5)))) {
        Get.snackbar('Error', 'Your verification code has expired. Please request a new one.', backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      // Matching OTP check
      if (_generatedOtp == null || enteredOtp.trim() != _generatedOtp) {
        Get.snackbar('Error', 'Invalid verification code.', backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      // 1. Create Firebase Auth account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = credential.user!.uid;

      // 2. Store ONLY user profile under users/$uid
      await _dbRef.child('users').child(uid).set({
        'uid': uid,
        'fullName': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 3. Load user expense data for immediate session
      if (Get.isRegistered<ExpenseController>()) {
        await Get.find<ExpenseController>().loadData();
      }

      Get.snackbar(
        'Success',
        'Email Verified Successfully!',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = e.message ?? message;
      }
      Get.snackbar('Error', message, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Login Action ---
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (Get.isRegistered<ExpenseController>()) {
        await Get.find<ExpenseController>().loadData();
      }

      Get.snackbar(
        'Success',
        'Login Successful!',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'User not found or incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Check your connection.';
      } else {
        message = e.message ?? message;
      }
      Get.snackbar('Error', message, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Forgot Password Action ---
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email.trim());

      Get.snackbar(
        'Reset Link Sent',
        'Password reset instructions have been sent to $email',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Failed to send reset email', backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Logout Action ---
  Future<void> logout() async {
    await _auth.signOut();
  }
}