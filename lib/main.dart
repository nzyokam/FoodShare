import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodshare/auth/auth_gate.dart';
import 'package:foodshare/themes/light_mode.dart';
import 'package:foodshare/themes/dark_mode.dart';
import 'firebase_options.dart';
import 'providers/theme_notifier.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load saved theme before first frame so there's no flash
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  final initialTheme = switch (savedTheme) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  runApp(
    ProviderScope(
      overrides: [
        themeNotifierProvider.overrideWith(() => ThemeNotifier(initialTheme)),
      ],
      child: const FoodShare(),
    ),
  );
}

class FoodShare extends ConsumerStatefulWidget {
  const FoodShare({super.key});

  @override
  ConsumerState<FoodShare> createState() => _FoodShareState();
}

class _FoodShareState extends ConsumerState<FoodShare> {
  bool _notifInitialized = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeMode,
      home: const AuthGate(),
      builder: (context, child) {
        if (!_notifInitialized) {
          _notifInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) NotificationService.initialize();
          });
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ));
        if (kIsWeb) {
          final size = MediaQuery.of(context).size;
          final w = size.width;
          final h = size.height;
          if (w >= 600 && h >= 500) return const _MobileOnlyGate();
          if (w > h) return const _PortraitOnlyGate();
        }
        return child ?? const SizedBox.shrink();
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
