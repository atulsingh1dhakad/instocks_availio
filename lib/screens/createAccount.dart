import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../consts.dart';

class createAccount extends StatefulWidget {
  const createAccount({super.key});

  @override
  State<createAccount> createState() => _createAccountState();
}

class _createAccountState extends State<createAccount> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _storeIdController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    final String? apiKey = dotenv.env['API_KEY'];
    final url = Uri.parse('${API_URL}users/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          X_api_token: apiKey ?? '',
        },
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "type": _typeController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": int.tryParse(_phoneController.text.trim()) ?? 0,
          "user_id": _userIdController.text.trim(),
          "store_id": _storeIdController.text.trim(),
          "branch": _branchController.text.trim(),
          "password": _passwordController.text,
        }),
      );
      Map<String, dynamic> data = {};
      try {
        data = json.decode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _success = 'Account created successfully. You can now log in.';
        });
      } else {
        setState(() {
          String backendError = '';
          if (data.containsKey('detail')) {
            backendError = data['detail'].toString();
          } else if (response.body.trim() == '{}' || response.body.trim().isEmpty) {
            backendError = 'Failed to create account. Check your details.';
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
        _error = "Registration failed. Please check your connection. $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userIdController.dispose();
    _storeIdController.dispose();
    _branchController.dispose();
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
                                      'Create Account',
                                      style: TextStyle(
                                        fontFamily: 'opensans',
                                        fontSize: width * 0.012,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff280071),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  _buildTextField(_nameController, 'Name', Icons.person),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_typeController, 'Type', Icons.info),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_emailController, 'Email', Icons.email, inputType: TextInputType.emailAddress),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_phoneController, 'Phone', Icons.phone, inputType: TextInputType.number),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_userIdController, 'User ID', Icons.badge),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_storeIdController, 'Store ID', Icons.store),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_branchController, 'Branch', Icons.account_tree),
                                  SizedBox(height: height * 0.012),
                                  _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
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
                                  if (_success != null) ...[
                                    SizedBox(height: height * 0.012),
                                    Center(
                                      child: Text(
                                        _success!,
                                        style: TextStyle(color: Colors.green, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: height * 0.04),
                                  Center(
                                    child: _isLoading
                                        ? CircularProgressIndicator()
                                        : ElevatedButton(
                                      onPressed: _registerUser,
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
                                        'Create Account',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.04),
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            'Already have an account?',
                                            style: TextStyle(
                                              fontFamily: 'opensans',
                                              fontSize: width * 0.009,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff280071),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          Text(
                                            'Login',
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType inputType = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      decoration: InputDecoration(
        fillColor: Colors.white70,
        filled: true,
        prefixIcon: Icon(icon),
        hintText: 'Enter $hint',
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
    );
  }
}