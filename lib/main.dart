// lib/main.dart

import 'package:appwrite/appwrite.dart' hide Locale;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'welcome_page.dart';
import 'config/secrets.dart';

late Client client;
late Account account;
late Databases databases;
late Storage storage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  client = Client()
      .setEndpoint(Secrets.appwriteEndpoint)
      .setProject(Secrets.appwriteProjectId);

  account = Account(client);
  databases = Databases(client);
  storage = Storage(client);

  runApp(const CricketApp());
}

class CricketApp extends StatefulWidget {
  const CricketApp({super.key});

  @override
  State<CricketApp> createState() => _CricketAppState();
}

class _CricketAppState extends State<CricketApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'themeMode';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.green;
    const darkBackgroundColor = Color(0xFF1a233b);

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Colors.orange,
        surface: darkBackgroundColor,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        primary: Colors.green,
        secondary: Colors.orange,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      title: 'Cricket Scoring System',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('bn', ''),
      ],
      home: WelcomePage(
        onThemeChanged: _toggleTheme,
        currentTheme: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}