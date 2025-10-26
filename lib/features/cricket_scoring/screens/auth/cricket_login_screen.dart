// lib\features\cricket_scoring\screens\auth\cricket_login_screen.dart

import 'package:flutter/material.dart';
import '../../services/cricket_auth_service.dart';
import '../../screens/auth/cricket_signup_screen.dart';
import '../home/cricket_home_screen.dart';


class CricketLoginScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final ThemeMode currentTheme;

  const CricketLoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<CricketLoginScreen> createState() => _CricketLoginScreenState();
}

class _CricketLoginScreenState extends State<CricketLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = CricketAuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        print('Attempting login with email: $email');

        await _authService.signIn(
          email: email,
          password: password,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CricketHomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {

          String errorMessage = 'Login Failed: ';
          if (e.toString().contains('Invalid email or password')) {
            errorMessage += 'Invalid email or password. Please check your credentials.';
          } else if (e.toString().contains('banned')) {
            errorMessage += 'Your account has been banned.';
          } else if (e.toString().contains('network')) {
            errorMessage += 'Network error. Please check your internet connection.';
          } else {
            errorMessage += e.toString();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Scorer Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sports_cricket,
                  size: MediaQuery.of(context).size.width < 360 ? 64 : 80,
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 360 ? 16 : 24),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 24 : Theme.of(context).textTheme.headlineMedium!.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _handleLogin,
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CricketSignUpScreen(
                              onThemeChanged: widget.onThemeChanged,
                              currentTheme: widget.currentTheme,
                            )),
                      );
                    },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}