import 'package:flutter/material.dart';
import './weather_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load environment variables
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner:
          false, //removes the debug badge from the screen
      home: const WeatherScreen(),
    );
  }
}
