import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: SupermarketApp()));
}

class SupermarketApp extends StatelessWidget {
  const SupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cotizador Supermercado',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
      ),
      home: const HomeScreen(),
    );
  }
}
