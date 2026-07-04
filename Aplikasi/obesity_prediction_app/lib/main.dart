import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(ObesityPredictionApp());
}

class ObesityPredictionApp extends StatelessWidget {
  const ObesityPredictionApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obesity AI Predictor',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}