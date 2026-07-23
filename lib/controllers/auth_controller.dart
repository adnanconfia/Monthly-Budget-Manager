import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Rxn<User> firebaseUser = Rxn<User>();
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

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

  // --- Login Action ---
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Explicitly (re)load this user's data from Firebase right after a
      // successful login, so the Dashboard is guaranteed to show the
      // previously saved income/expenses instead of relying solely on the
      // authStateChanges listener's timing relative to navigation.
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

  // --- Signup Action (Profile Only under 'users/$uid') ---
  Future<bool> signUp(String name, String email, String phone, String password) async {
    try {
      isLoading.value = true;
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = credential.user!.uid;

      // Store ONLY the user profile under users/$uid
      await _dbRef.child('users').child(uid).set({
        'uid': uid,
        'fullName': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Success',
        'Account Created Successfully.',
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