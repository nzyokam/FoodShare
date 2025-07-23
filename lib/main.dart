import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/auth/auth_gate.dart';

import 'package:foodshare/themes/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),
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
          theme: themeProvider.themeData,
          home: const AuthGate(),
        );
      },
    );
  }
}


