import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodshare/auth/auth_gate.dart';
import 'package:foodshare/themes/theme_provider.dart';
import 'package:foodshare/themes/light_mode.dart';
import 'package:foodshare/themes/dark_mode.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const FoodShare(),
    ),
  );
}

class FoodShare extends StatelessWidget {
  const FoodShare({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
