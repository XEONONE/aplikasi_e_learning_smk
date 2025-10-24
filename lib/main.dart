// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Impor SharedPreferences
import 'auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _currentThemeMode = ThemeMode.dark; // Default ke gelap
  static const String _themeKey = 'themeMode'; // Kunci untuk SharedPreferences

  @override
  void initState() {
    super.initState();
    // Muat preferensi tema saat app start
    _loadThemePreference();
  }

  // Fungsi untuk memuat preferensi tema
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      setState(() {
        _currentThemeMode = themeIndex == 1 ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  // Fungsi untuk menyimpan preferensi tema
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    // 0 untuk light, 1 untuk dark
    await prefs.setInt(_themeKey, mode == ThemeMode.dark ? 1 : 0);
  }

  // Fungsi ini dipanggil dari account_settings_screen.dart
  void changeTheme(ThemeMode newThemeMode) {
    setState(() {
      _currentThemeMode = newThemeMode;
    });
    // Simpan preferensi tema ke SharedPreferences
    _saveThemePreference(newThemeMode);
  }

  ThemeMode get currentThemeMode => _currentThemeMode;

  @override
  Widget build(BuildContext context) {
    // --- TEMA TERANG ---
    final ThemeData baseLightTheme = ThemeData.light();
    final ColorScheme lightColorScheme = ColorScheme.light(
      primary: Colors.indigo.shade700,
      secondary: Colors.indigoAccent.shade400,
      surface: const Color(0xFFF0F2F5),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      error: Colors.redAccent.shade700,
      onError: Colors.white,
      brightness: Brightness.light,
    );
    final TextTheme lightTextTheme = baseLightTheme.textTheme
        .apply(
          bodyColor: lightColorScheme.onSurface, // <<-- Ambil dari onSurface
          displayColor: Colors.black,
        )
        .copyWith(
          titleLarge: baseLightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.black,
          ),
          titleMedium: baseLightTheme.textTheme.titleMedium?.copyWith(
            color: Colors.black87,
          ),
          bodySmall: baseLightTheme.textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
          labelLarge: baseLightTheme.textTheme.labelLarge?.copyWith(
            color: lightColorScheme.onPrimary,
          ),
        );

    final ThemeData lightTheme =
        ThemeData.from(
          colorScheme: lightColorScheme,
          textTheme: lightTextTheme,
          useMaterial3: true,
        ).copyWith(
          scaffoldBackgroundColor: lightColorScheme.surface,
          cardColor: lightColorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            titleTextStyle: lightTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: lightColorScheme.primary,
            unselectedItemColor: Colors.grey.shade600,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.grey.shade700),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: lightColorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIconColor: Colors.grey.shade600,
            suffixIconColor: Colors.grey.shade600,
          ),
          toggleButtonsTheme: ToggleButtonsThemeData(
            selectedColor: lightColorScheme.onPrimary,
            color: lightColorScheme.primary,
            fillColor: lightColorScheme.primary.withAlpha(230),
            selectedBorderColor: lightColorScheme.primary,
            borderColor: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(8),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Colors.grey.shade700),
          listTileTheme: ListTileThemeData(
            iconColor: lightColorScheme.primary,
            textColor: lightColorScheme.onSurface,
            titleTextStyle: lightTextTheme.titleMedium,
            subtitleTextStyle: lightTextTheme.bodySmall,
          ),
          cardTheme: CardThemeData(
            color: lightColorScheme.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              foregroundColor: lightColorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: lightTextTheme.labelLarge,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: lightColorScheme.primary,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: lightColorScheme.primary,
              side: BorderSide(color: lightColorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),
          dividerTheme: DividerThemeData(color: Colors.grey.shade300),
          dialogTheme: DialogThemeData(
            backgroundColor: lightColorScheme.surface,
            titleTextStyle: lightTextTheme.titleLarge,
            contentTextStyle: lightTextTheme.bodyMedium,
          ),
          tabBarTheme: TabBarThemeData(
            indicatorColor: lightColorScheme.primary,
            labelColor: lightColorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? lightColorScheme.primary
                  : null,
            ),
            trackColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? lightColorScheme.primary.withAlpha(128)
                  : null,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : Colors.grey.shade500,
            ),
          ),
        );

    // --- TEMA GELAP ---
    final ThemeData baseDarkTheme = ThemeData.dark();
    final ColorScheme darkColorScheme = const ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.cyanAccent,
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      brightness: Brightness.dark,
    );
    final TextTheme darkTextTheme = baseDarkTheme.textTheme
        .apply(
          bodyColor: darkColorScheme.onSurface.withAlpha(
            178,
          ), // <<-- Ambil dari onSurface (70% opacity)
          displayColor: Colors.white,
        )
        .copyWith(
          titleLarge: baseDarkTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
          titleMedium: baseDarkTheme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
          bodySmall: baseDarkTheme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[400],
          ),
          labelLarge: baseDarkTheme.textTheme.labelLarge?.copyWith(
            color: darkColorScheme.onPrimary,
          ),
        );

    final ThemeData darkTheme =
        ThemeData.from(
          colorScheme: darkColorScheme,
          textTheme: darkTextTheme,
          useMaterial3: true,
        ).copyWith(
          scaffoldBackgroundColor: darkColorScheme.surface,
          cardColor: darkColorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            titleTextStyle: darkTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: darkColorScheme.surface,
            selectedItemColor: darkColorScheme.primary,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.grey.shade400),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade800.withAlpha(128),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: darkColorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIconColor: Colors.grey.shade400,
            suffixIconColor: Colors.grey.shade400,
          ),
          toggleButtonsTheme: ToggleButtonsThemeData(
            selectedColor: darkColorScheme.onSurface,
            color: Colors.grey[400],
            fillColor: darkColorScheme.primary.withAlpha(51),
            selectedBorderColor: Colors.blueAccent.shade100.withAlpha(128),
            borderColor: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Colors.grey[400]),
          listTileTheme: ListTileThemeData(
            iconColor: darkColorScheme.secondary,
            textColor: darkColorScheme.onSurface,
            titleTextStyle: darkTextTheme.titleMedium,
            subtitleTextStyle: darkTextTheme.bodySmall,
          ),
          cardTheme: CardThemeData(
            color: darkColorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkColorScheme.primary,
              foregroundColor: darkColorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: darkTextTheme.labelLarge,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: darkColorScheme.primary,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: darkColorScheme.primary,
              side: BorderSide(color: darkColorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),
          dividerTheme: DividerThemeData(color: Colors.grey.shade800),
          dialogTheme: DialogThemeData(
            backgroundColor: darkColorScheme.surface,
            titleTextStyle: darkTextTheme.titleLarge,
            contentTextStyle: darkTextTheme.bodyMedium,
          ),
          tabBarTheme: TabBarThemeData(
            indicatorColor: darkColorScheme.primary,
            labelColor: darkColorScheme.primary,
            unselectedLabelColor: Colors.grey,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? darkColorScheme.primary
                  : null,
            ),
            trackColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? darkColorScheme.primary.withAlpha(128)
                  : null,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : Colors.grey.shade600,
            ),
          ),
        );

    // --- RETURN MATERIAL APP ---
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Learning App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _currentThemeMode,
      home: const AuthGate(),
    );
  }
}
