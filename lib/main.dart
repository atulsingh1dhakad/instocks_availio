import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instockavailio/src/screens/homescreen.dart';
import 'package:instockavailio/src/screens/loginscreen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('Authorization');
  final int? expiry = prefs.getInt('TokenExpiry');
  final bool isLoggedIn = (token != null &&
      token.isNotEmpty &&
      expiry != null &&
      expiry > DateTime.now().millisecondsSinceEpoch);

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn
          ? AuthGuard(child: homescreen())
          : loginscreen(),
    );
  }
}

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool isChecking = true;
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }
  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('Authorization');
    final expiry = prefs.getInt('TokenExpiry');
    final valid = (token != null &&
        token.isNotEmpty &&
        expiry != null &&
        expiry > DateTime.now().millisecondsSinceEpoch);

    if (!valid) {
      // Clear token and expiry if needed
      prefs.remove('Authorization');
      prefs.remove('TokenExpiry');
      // Go to login after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => loginscreen()),
              (route) => false,
        );
      });
    } else {
      setState(() {
        isValid = true;
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}