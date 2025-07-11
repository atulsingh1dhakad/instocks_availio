import 'package:flutter/material.dart';
import 'package:instockavailio/screens/profilescreen.dart';
import 'package:instockavailio/screens/staffscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'InventoryScreen.dart';
import 'billing.dart';
import 'dashboard.dart';
import 'loginscreen.dart';

class homescreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter POS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: POSHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class POSHomeScreen extends StatefulWidget {
  @override
  _POSHomeScreenState createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  int _selectedIndex = 0; // To keep track of the selected screen

  // List of screens for main content
  final List<Widget> _screens = [
    DashboardScreen(),
    StaffScreen(),
    InventoryScreen(),
    OrdersScreen(),
    Billingscreen(),
    ProfileScreen(), // Use ProfileScreen()
  ];

  // Function to handle menu item clicks
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Change the selected index to navigate to the correct screen
    });
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Clear tokens from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('token_type');
      await prefs.remove('Authorization');
      await prefs.remove('user_id');
      // You can also use prefs.clear() if you want to clear everything

      // Go to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => loginscreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Side panel (fixed on the left)
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40)),
              color: Colors.grey[800],
            ),
            width: 150,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      children: [
                        const Text('Availio', style: TextStyle(color: Colors.white, fontSize: 30)),
                        const Text('Instocks', style: TextStyle(color: Colors.white, fontSize: 22)),
                        SizedBox(height:15,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                      ],
                    ),
                  ),
                  // DashBoard
                  _buildMenuItem('DashBoard', Icons.dashboard_customize, 0),
                  SizedBox(height:25,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                  _buildMenuItem('Staff', Icons.people, 1),
                  SizedBox(height:25,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                  _buildMenuItem('Inventory', Icons.inventory, 2),
                  SizedBox(height:25,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                  _buildMenuItem('Orders', Icons.shopping_cart_rounded, 3),
                  SizedBox(height:25,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                  _buildMenuItem('Billing', Icons.receipt_long, 4),
                  SizedBox(height:25,width: 80,child:Divider(color: Colors.grey[400],height: 5,) ,),
                  _buildMenuItem('My Profile', Icons.person, 5), // fixed index for profile
                  Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: GestureDetector(
                      onTap: () => _logout(context),
                      child: Column(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          // Main content area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build each menu item
  GestureDetector _buildMenuItem(String title, IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
      },
      child: Container(
        height: 70,
        width: 120,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: _selectedIndex == index ? const Color(0xFFFAC1D9) : Colors.blue,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(icon, color: Colors.black),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// Dummy Orders screen for completeness
class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Orders Screen', style: TextStyle(fontSize: 24, color: Colors.black)));
  }
}