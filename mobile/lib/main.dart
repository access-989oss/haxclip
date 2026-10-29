import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/hax_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: HaxTheme.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const HaxClipApp());
}

class HaxClipApp extends StatelessWidget {
  const HaxClipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HaxClip',
      debugShowCheckedModeBanner: false,
      theme: HaxTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
