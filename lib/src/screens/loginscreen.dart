import 'package:flutter/foundation.dart' show kIsWeb;

//lo karlo baat
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
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
  bool _rememberMe = false;


  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });


    final String apiKey = '0ff738d516ce887efe7274d43acd8043';
    final String apiUrl = API_URL;
    final url = Uri.parse('${apiUrl}users/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiKey,
        },
        body: jsonEncode({
          'email_or_phone': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      Map<String, dynamic> data = {};
      bool jsonDecodeSuccess = false;
      try {
        data = json.decode(response.body);
        jsonDecodeSuccess = true;
      } catch (_) {}

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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.0,
            colors: [
              Color(0xFFC9E7F8),
              Color(0xFFD0F3DB),
              Color(0xFFEFF2F6),
            ],
            stops: [0.1, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.storefront_outlined,
                  size: 80,
                  color: Colors.black87,
                ),
                const SizedBox(height: 32),
                Text(
                  'POS Login',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage your store with ease',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // Login Card
                Container(
                  width: size.width < 500 ? size.width * 0.97 : 430,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: "Email  / phone number",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.black12, width: 1.3),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.black12, width: 1.3),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 1.9),
                          ),
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.black12, width: 1.3),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.black12, width: 1.3),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 1.9),
                          ),
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      // Remember me checkbox below password
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            activeColor: Colors.blueAccent,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _loginUser,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFB6F5C9),
                                  Color(0xFFBEE7FF),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'New store? Register here.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}