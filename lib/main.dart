import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const ChatScreen(),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF1F3F4),
        onSurface: const Color(0xFF202124),
        onSurfaceVariant: const Color(0xFF5F6368),
        primary: const Color(0xFF1A73E8),
        secondary: const Color(0xFFE8EAED),
        onSecondary: const Color(0xFF3C4043),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: Color(0xFF5F6368)),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF131314),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8AB4F8),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF131314),
        surfaceContainerHighest: const Color(0xFF282A2C),
        onSurface: const Color(0xFFE3E3E3),
        onSurfaceVariant: const Color(0xFF9AA0A6),
        primary: const Color(0xFF8AB4F8),
        secondary: const Color(0xFF282A2C),
        onSecondary: const Color(0xFFE3E3E3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131314),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: Color(0xFF9AA0A6)),
      ),
      dividerColor: const Color(0xFF3C4043),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF282A2C),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}