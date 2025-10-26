// lib\features\cricket_scoring\screens\auth\cricket_signup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../../services/cricket_auth_service.dart';
import 'otp_verification_screen.dart';
import '../../../../home_page.dart';
import '../../../../main.dart';

class CricketSignUpScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final ThemeMode currentTheme;

  const CricketSignUpScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<CricketSignUpScreen> createState() => _CricketSignUpScreenState();
}

class _CricketSignUpScreenState extends State<CricketSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final CricketAuthService _authService = CricketAuthService();

  File? _photo;
  File? _nidPhoto;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, void Function(File) onFilePicked) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        onFilePicked(File(pickedFile.path));
      });
    }
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final username = _usernameController.text.trim();
        final fullName = _fullNameController.text.trim();

        final user = await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: fullName,
        );

        await account.createVerification(
          url: 'https://smart-numerix-cricket.app',
        );

        if (mounted) {
          setState(() => _isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                email: email,
                purpose: 'signup_verification',
                onOTPVerified: (user) {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        onThemeChanged: widget.onThemeChanged,
                        currentTheme: widget.currentTheme,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errorMessage = 'Sign-up failed';
          if (e.toString().contains('user_already_exists')) {
            errorMessage = 'An account with this email already exists';
          } else if (e.toString().contains('invalid_email')) {
            errorMessage = 'Please enter a valid email address';
          } else if (e.toString().contains('password_too_weak')) {
            errorMessage = 'Password is too weak. Please choose a stronger password';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Scorer Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Username is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name (as per NID)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Full name is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true, validator: (v) => v!.length < 8 ? 'Password must be at least 8 characters' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()), obscureText: true, validator: (v) => v! != _passwordController.text ? 'Passwords do not match' : null),
              const SizedBox(height: 24),
              _buildImagePicker('Personal Photo (Optional)', _photo, (file) => _photo = file),
              const SizedBox(height: 16),
              _buildImagePicker('NID Front Picture (for Scorer Verification)', _nidPhoto, (file) => _nidPhoto = file),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _handleSignUp,
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? file, void Function(File) onFilePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: file != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, fit: BoxFit.cover))
              : const Center(child: Text('No image selected')),
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Select from Gallery'),
          onPressed: () => _pickImage(ImageSource.gallery, onFilePicked),
        ),
      ],
    );
  }
}