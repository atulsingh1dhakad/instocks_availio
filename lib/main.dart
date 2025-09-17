import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instockavailio/screens/homescreen.dart';
import 'package:instockavailio/screens/loginscreen.dart';
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

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn ? homescreen() : loginscreen(),
    );
  }
}