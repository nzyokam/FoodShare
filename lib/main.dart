import 'package:flutter/foundation.dart' show kIsWeb;
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
          builder: (context, child) {
            if (kIsWeb) {
              final size = MediaQuery.of(context).size;
              final w = size.width;
              final h = size.height;
              // Large screen (desktop / tablet)
              if (w >= 600 && h >= 500) return const _MobileOnlyGate();
              // Phone rotated to landscape
              if (w > h) return const _PortraitOnlyGate();
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _MobileOnlyGate extends StatelessWidget {
  const _MobileOnlyGate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                isDark ? 'lib/assets/dark-mode.png' : 'lib/assets/light-mode.png',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 32),
              Icon(Icons.phone_iphone_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Mobile only',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'FoodShare is designed for mobile devices.\nPlease open this link on your phone.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurface.withAlpha(160), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortraitOnlyGate extends StatelessWidget {
  const _PortraitOnlyGate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                isDark ? 'lib/assets/dark-mode.png' : 'lib/assets/light-mode.png',
                width: 56,
                height: 56,
              ),
              const SizedBox(height: 32),
              Icon(Icons.screen_rotation_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Rotate your phone',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'FoodShare works best in portrait mode.\nPlease rotate your device.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurface.withAlpha(160), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
