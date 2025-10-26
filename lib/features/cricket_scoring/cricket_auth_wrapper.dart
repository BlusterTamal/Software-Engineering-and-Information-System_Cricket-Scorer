// lib\features\cricket_scoring\cricket_auth_wrapper.dart

import 'package:flutter/material.dart';
import 'screens/auth/cricket_login_screen.dart';
import 'screens/home/cricket_home_screen.dart';
import 'services/cricket_auth_service.dart';
import 'models/user_model.dart';

class CricketAuthWrapper extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final ThemeMode? currentTheme;

  const CricketAuthWrapper({
    super.key,
    this.onThemeChanged,
    this.currentTheme,
  });

  @override
  State<CricketAuthWrapper> createState() => _CricketAuthWrapperState();
}

class _CricketAuthWrapperState extends State<CricketAuthWrapper> {
  final CricketAuthService _authService = CricketAuthService();
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {

          return CricketHomeScreen(
            onThemeChanged: widget.onThemeChanged,
            currentTheme: widget.currentTheme,
          );
        } else {

          return CricketLoginScreen(
            onThemeChanged: widget.onThemeChanged ?? () {},
            currentTheme: widget.currentTheme ?? ThemeMode.system,
          );
        }
      },
    );
  }
}