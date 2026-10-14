import 'package:flutter/material.dart';

import 'screens/library_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SingTunadoApp());
}

class SingTunadoApp extends StatelessWidget {
  const SingTunadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SingTunado',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const LibraryScreen(),
    );
  }
}
