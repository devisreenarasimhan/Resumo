import 'package:flutter/material.dart';
import '../LoginPage.dart'; // Make sure you import the LoginPage

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin(); // Call the method to navigate after a delay
  }

  // Method to navigate to the Login page after a delay
  _navigateToLogin() async {
    await Future.delayed(Duration(seconds: 3)); // Wait for 3 seconds
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Adjust the background color as needed
      body: Center(
        child: Text(
          'Resumo',
          style: TextStyle(
            fontFamily: 'Poppins', // Use a custom font (make sure it's added to pubspec.yaml)
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Adjust text color as needed
          ),
        ),
      ),
    );
  }
}

// In your main.dart, make this the initial route
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}
