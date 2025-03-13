import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'JS/Upskills.dart';
import 'LoginPage.dart';
import 'JS/Splash.dart';
import 'JS/Home.dart';
import 'JS/Openings.dart';
import 'JS/Recruiters.dart';
import 'JS/Trends.dart';
import 'JS/Events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAJJeSrJa3smQqOzeFmRfLBpo2qtcQ1KIw",
      appId: "1:238981607787:android:e8fcd195d7223b88c09c2e",
      messagingSenderId: "238981607787",
      projectId: "resumo-lol",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/home':
            return MaterialPageRoute(
              builder: (context) => Home(),
            );
          case '/openings':
            return MaterialPageRoute(
              builder: (context) => Openings(),
            );
          case '/recruiters':
            return MaterialPageRoute(
              builder: (context) => Recruiters(),
            );
          case '/upskills':
            return MaterialPageRoute(
              builder: (context) => Upskills(),
            );
          case '/trends':
            return MaterialPageRoute(
              builder: (context) => Trends(),
            );
          case '/events':
            return MaterialPageRoute(
              builder: (context) => Events(),
            );
          default:
            return MaterialPageRoute(builder: (context) => SplashScreen());
        }
      },
    );
  }
}
