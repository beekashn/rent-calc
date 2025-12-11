import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/rent_calculator_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'theme_mode_final_v2';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      setState(() {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: _themeMode == ThemeMode.light
            ? Brightness.dark
            : Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );

    await prefs.setString(
      _themeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: RentCalculatorHome(onToggleTheme: toggleTheme),
    );
  }
}
