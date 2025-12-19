import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../consts.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart' show LoggedIn;
import '../blocs/auth/auth_state.dart' show AuthLoading, AuthAuthenticated, AuthUnauthenticated;
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

    final String apiKey = API_TOKEN; // use const from consts.dart
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

      if (response.statusCode == 200 && jsonDecodeSuccess && data['access_token'] != null && data['token_type'] != null) {
        // Build the Authorization header string similar to your other code
        final rawType = data['token_type'].toString();
        final tokenType = rawType.trim().isEmpty ? 'Bearer' : rawType.trim();
        final formattedTokenType = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()}';
        final accessToken = data['access_token'].toString().trim();
        final authorizationHeader = '$formattedTokenType $accessToken';

        // Determine expiry millis (use expires_in if present, otherwise default 30 days)
        int expiryMillis;
        if (data.containsKey('expires_in')) {
          final expiresInRaw = data['expires_in'];
          final expiresInSec = (expiresInRaw is int) ? expiresInRaw : int.tryParse(expiresInRaw?.toString() ?? '') ?? (30 * 24 * 3600);
          expiryMillis = DateTime.now().millisecondsSinceEpoch + (expiresInSec * 1000);
        } else if (data.containsKey('expiry') || data.containsKey('expires_at')) {
          // try to parse absolute expiry if provided
          final raw = data['expiry'] ?? data['expires_at'];
          final parsed = int.tryParse(raw?.toString() ?? '');
          expiryMillis = parsed != null ? parsed : DateTime.now().millisecondsSinceEpoch + (30 * 24 * 3600 * 1000);
        } else {
          expiryMillis = DateTime.now().millisecondsSinceEpoch + (30 * 24 * 3600 * 1000); // 30 days
        }

        // Dispatch LoggedIn to AuthBloc (this will persist token via repository/service)
        context.read<AuthBloc>().add(LoggedIn(token: authorizationHeader, expiryMillis: expiryMillis));

        // Let BlocListener handle navigation when authentication completes.
      } else {
        String backendError = '';
        if (!jsonDecodeSuccess) {
          if (response.body.trim().startsWith('<')) {
            backendError =
            'Received an unexpected server response (possibly an HTML error page).';
          } else {
            backendError = 'Failed to parse server response.';
          }
        } else if (data.containsKey('detail')) {
          backendError = data['detail'].toString();
        } else if (response.body.trim() == '{}' || response.body.trim().isEmpty) {
          backendError = 'Invalid credentials or user not found.';
        } else if (data['message'] != null) {
          backendError = data['message'].toString();
        } else {
          backendError = 'Server error: ${response.body}';
        }
        setState(() {
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
      // We keep _isLoading true briefly until AuthBloc updates state to AuthLoading/AuthAuthenticated,
      // but to ensure UI responsiveness set it false here — navigation is handled by BlocListener.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return BlocListener<AuthBloc, dynamic>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // optionally show a snackbar or keep loading indicator
        } else if (state is AuthAuthenticated) {
          // navigate to homescreen and remove login from stack
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => homescreen()),
          );
        } else if (state is AuthUnauthenticated) {
          // show error if any (AuthBloc does not carry message in this app)
          if (_error != null && _error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed')));
          }
        }
      },
      child: Scaffold(
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
                  const Icon(
                    Icons.storefront_outlined,
                    size: 80,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 32),
                  const Text(
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
                  const Text(
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
                  LayoutBuilder(builder: (context, constraints) {
                    final size = MediaQuery.of(context).size;
                    return Container(
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
                            decoration: const InputDecoration(
                              hintText: "Email  / phone number",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
                            ),
                            style: const TextStyle(fontSize: 16),
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
                                ? const Center(child: CircularProgressIndicator())
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
                                  gradient: const LinearGradient(
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
                                  child: const Text(
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
                            child: const Text(
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
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text(
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
      ),
    );
  }
}