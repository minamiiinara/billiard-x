import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/table_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/booking_payment_screen.dart';
import 'screens/payment_success_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'SFProText',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => WelcomeScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/payment': (context) => PaymentSuccessScreen(),
          '/bookings': (context) => BookingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/tableDetail') {
            final args = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) {
                return TableDetailScreen(tableId: args);
              },
            );
          } else if (settings.name == '/search') {
            return MaterialPageRoute(
              builder: (context) => SearchScreen(),
            );
          } else if (settings.name == '/bookingDetail') {
            final args = settings.arguments as DocumentSnapshot;
            return MaterialPageRoute(
              builder: (context) {
                return BookingDetailScreen(booking: args);
              },
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }
}
