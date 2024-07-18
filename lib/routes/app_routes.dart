import 'package:flutter/material.dart';
import 'package:billiard_x/screens/login_screen.dart';
import 'package:billiard_x/screens/home_screen.dart';
import 'package:billiard_x/screens/register_screen.dart';
import 'package:billiard_x/screens/welcome_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      default:
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
    }
  }
}
