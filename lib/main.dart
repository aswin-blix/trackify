import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_helper.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper.instance;
  try {
    final categories = await dbHelper.readAllCategories();
    if (categories.isEmpty) {
      for (var category in AppConstants.defaultCategories) {
        await dbHelper.createCategory(category);
      }
    }
  } catch (e) {
    debugPrint("Error seeding database: $e");
  }

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Trackify',
          themeMode: settings.themeMode,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF101622),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF135bec),
              surface: Color(0xFF1c2433),
              error: Color(0xFFff6b6b),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFf6f6f8),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF135bec),
              surface: Colors.white,
              error: Color(0xFFff6b6b),
            ),
            textTheme: GoogleFonts.interTextTheme(),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
