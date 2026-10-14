import 'package:flutter/material.dart';

/// Colors taken from the SingTunado logo.
class Brand {
  static const navy = Color(0xFF0A0A1A);
  static const surface = Color(0xFF14142B);
  static const blue = Color(0xFF00A8FF);
  static const purple = Color(0xFF7B3FF2);
  static const magenta = Color(0xFFFF2EC4);
  static const orange = Color(0xFFFF9F1C);
  static const yellow = Color(0xFFFFC400);

  static const gradient = LinearGradient(
    colors: [blue, purple, magenta, orange],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.purple,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Brand.magenta,
    secondary: Brand.blue,
    surface: Brand.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.navy,
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.navy,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.magenta,
      foregroundColor: Colors.white,
    ),
  );
}

/// Text painted with the logo gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => Brand.gradient.createShader(r),
      child: Text(text, style: style),
    );
  }
}
