import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../consts.dart';
import '../helpers/login_auth_holder.dart';
import '../repositories/auth_repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart' show LoggedIn;
import '../blocs/auth/auth_state.dart' show AuthAuthenticated, AuthLoading;
import 'homescreen.dart';

class loginscreen extends StatefulWidget {
  const loginscreen({Key? key}) : super(key: key);

  @override
  State<loginscreen> createState() => _loginscreenState();
}

class _loginscreenState extends State<loginscreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final String apiKey = API_TOKEN;
    final String apiUrl = API_URL;
    final url = Uri.parse('${apiUrl}users/login');

    try {
      if (kDebugMode) debugPrint('[Login] Attempting login at $url');
      
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

      if (kDebugMode) debugPrint('[Login] Response status: ${response.statusCode}');

      Map<String, dynamic> data = {};
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 && data['access_token'] != null) {
        final tokenType = (data['token_type'] ?? 'Bearer').toString().trim();
        // Capitalize Bearer
        final formattedTokenType = tokenType.isEmpty ? 'Bearer' : '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()}';
        final accessToken = data['access_token'].toString().trim();
        final authorizationHeader = '$formattedTokenType $accessToken';

        // Default expiry 30 days
        int expiryMillis = DateTime.now().millisecondsSinceEpoch + (30 * 24 * 3600 * 1000);
        if (data.containsKey('expires_in')) {
          final expiresIn = int.tryParse(data['expires_in'].toString()) ?? (30 * 24 * 3600);
          expiryMillis = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
        }

        // We delegate persistence and memory state entirely to AuthBloc to avoid mismatch
        if (mounted) {
          context.read<AuthBloc>().add(LoggedIn(
            token: authorizationHeader, 
            expiryMillis: expiryMillis
          ));
        }
      } else {
        setState(() {
          _error = data['detail']?.toString() ?? data['message']?.toString() ?? 'Invalid credentials';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Login] Error: $e');
      setState(() {
        _error = "Connection failed. Please check your network.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, dynamic>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homescreen()));
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
                  const Icon(Icons.storefront_outlined, size: 80, color: Colors.black87),
                  const SizedBox(height: 32),
                  const Text('POS Login', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 36),
                  Container(
                    width: 430,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: "Email / phone number",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Password",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
                          ),
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
