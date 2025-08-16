import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'createAccount.dart';
import 'homescreen.dart';

class loginscreen extends StatefulWidget {
  const loginscreen({super.key});

  @override
  State<loginscreen> createState() => _loginscreenState();
}

class _loginscreenState extends State<loginscreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  String getApiUrl() {
    // Use CORS proxy for web, direct API for mobile/desktop
    if (kIsWeb) {
      return "https://cors-anywhere.herokuapp.com/https://avalio-api.onrender.com/";
    } else {
      return "https://avalio-api.onrender.com/";
    }
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final String apiKey = '0ff738d516ce887efe7274d43acd8043';
    final String apiUrl = getApiUrl();
    final url = Uri.parse('${apiUrl}users/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiKey, // FIXED header name to match backend expectation
        },
        body: jsonEncode({
          'email_or_phone': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      Map<String, dynamic> data = {};
      bool jsonDecodeSuccess = false;
      try {
        data = json.decode(response.body);
        jsonDecodeSuccess = true;
      } catch (_) {
        // Non-JSON response handling below
      }

      if (response.statusCode == 200 &&
          jsonDecodeSuccess &&
          data['access_token'] != null &&
          data['token_type'] != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'access_token', data['access_token'].toString().trim());
        await prefs.setString(
            'token_type', data['token_type'].toString().trim());
        final String token =
            "${data['token_type'].toString().trim()} ${data['access_token'].toString().trim()}";
        await prefs.setString('Authorization', token);

        if (data.containsKey('_id')) {
          await prefs.setString('user_id', data['_id']);
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => homescreen()),
        );
      } else {
        setState(() {
          String backendError = '';
          if (!jsonDecodeSuccess) {
            // Check for HTML error page
            if (response.body.trim().startsWith('<')) {
              backendError =
              'Received an unexpected server response (possibly an HTML error page from a proxy or CORS server).';
            } else {
              backendError = 'Failed to parse server response.';
            }
          } else if (data.containsKey('detail')) {
            backendError = data['detail'].toString();
          } else if (response.body.trim() == '{}' ||
              response.body.trim().isEmpty) {
            backendError = 'Invalid credentials or user not found.';
          } else {
            backendError = 'Server error: ${response.body}';
          }
          _error = backendError;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _error = "Network error: $e";
      });
    } catch (e) {
      setState(() {
        _error = "Login failed. Please check your connection. $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bgbanner.jpg',
              fit: BoxFit.cover,
              width: width,
              height: height,
            ),
            SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: height * 0.02),
                    Image.asset(
                      'assets/images/logo2.png',
                      width: width * 0.2,
                      height: height * 0.09,
                    ),
                    SizedBox(height: height * 0.08),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.01,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 500,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.05),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: Text(
                                      'Login With ID and Password',
                                      style: TextStyle(
                                        fontFamily: 'opensans',
                                        fontSize: width * 0.012,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff280071),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  TextField(
                                    controller: _usernameController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white70,
                                      filled: true,
                                      prefixIcon: Icon(Icons.person),
                                      hintText: 'Enter Email or Phone Number',
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xff280071)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.012),
                                  Text(
                                    'Password',
                                    style: TextStyle(fontSize: width * 0.012),
                                  ),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white70,
                                      filled: true,
                                      prefixIcon: Icon(Icons.lock),
                                      hintText: 'Enter Your Password',
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xff280071)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    SizedBox(height: height * 0.012),
                                    Center(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(color: Colors.red, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: height * 0.04),
                                  Center(
                                    child: _isLoading
                                        ? CircularProgressIndicator()
                                        : ElevatedButton(
                                      onPressed: _loginUser,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(320, 54),
                                        shadowColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        backgroundColor: Color(0xff663390),
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: TextStyle(fontSize: 20),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.04),
                                  Center(
                                    child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const createAccount(),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Text(
                                              "Don't have an account?",
                                              style: TextStyle(
                                                fontFamily: 'opensans',
                                                fontSize: width * 0.009,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff280071),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            Text(
                                              "Create Account",
                                              style: TextStyle(
                                                fontFamily: 'opensans',
                                                fontSize: width * 0.009,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff280071),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        )
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'T&C applied',
                                        style: TextStyle(
                                          fontFamily: 'opensans',
                                          fontSize: width * 0.012,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff280071),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}