import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/launch_screen.dart';
import 'core/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await storageService.init();
  runApp(const ProviderScope(child: BunkBiteApp()));
}

class BunkBiteApp extends StatelessWidget {
  const BunkBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BunkBite',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      home: const LaunchScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      brightness: brightness,
      primaryColor: const Color(0xFFF62F56),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF62F56),
        brightness: brightness,
        primary: const Color(0xFFF62F56),
        error: Colors.red,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.urbanistTextTheme(baseTheme.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
