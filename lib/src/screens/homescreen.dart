import 'package:flutter/material.dart';
import 'package:instockavailio/src/screens/myinvoices.dart';
import 'package:instockavailio/src/screens/orderscreen.dart';
import 'package:instockavailio/src/screens/profilescreen.dart';
import 'package:instockavailio/src/screens/recylebin.dart';
import 'package:instockavailio/src/screens/staffscreen.dart';
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
        primarySwatch: Colors.green,
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
  int _selectedIndex = 0;

  // List of screens for main content
  final List<Widget> _screens = [
    DashboardScreen(),
    StaffScreen(),
    InventoryScreen(),
    OrdersScreen(),
    BillingScreen(),
    RecycleBinScreen(),
    ProfileScreen(),
    InvoicesScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'DashBoard', 'icon': Icons.dashboard_customize},
    {'title': 'Staff', 'icon': Icons.people},
    {'title': 'Inventory', 'icon': Icons.inventory},
    {'title': 'Orders', 'icon': Icons.shopping_cart_rounded},
    {'title': 'Billing', 'icon': Icons.receipt_long},
    {'title': 'Recyle BIN', 'icon': Icons.delete},
    {'title': 'My Profile', 'icon': Icons.person},
    {'title': 'My Invoices', 'icon': Icons.receipt},

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('token_type');
      await prefs.remove('Authorization');
      await prefs.remove('user_id');
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
      backgroundColor: const Color(0xFFF7FAFC), // panel bg
      body: SafeArea( // ✅ Protects from status bar, notches, gestures
        child: Row(
          children: [
            // Side navigation panel
            Container(
              width: 200,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFC9E7F8),
                    Color(0xFFD0F3DB),
                    Color(0xFFEFF2F6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App logo + name
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 36, bottom: 18),
                    child: Row(
                      children: [
                        _buildLogoDots(),
                        const SizedBox(width: 12),
                        const Text(
                          'Availio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Navigation items
                  ...List.generate(_menuItems.length, (index) {
                    return _buildMenuItem(
                      title: _menuItems[index]['title'],
                      icon: _menuItems[index]['icon'],
                      index: index,
                      selected: _selectedIndex == index,
                    );
                  }),

                  const Spacer(),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 24),
                    child: GestureDetector(
                      onTap: () => _logout(context),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area: Only the selected screen is built/active
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildLogoDots() {
    // Four colored dots (top left in screenshot)
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _circleDot(Colors.green),
          ),
          Positioned(
            left: 14,
            top: 0,
            child: _circleDot(Colors.blue),
          ),
          Positioned(
            left: 0,
            top: 14,
            child: _circleDot(Colors.purple),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _circleDot(Colors.yellow[700]!),
          ),
        ],
      ),
    );
  }

  Widget _circleDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required int index,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? Color(0xFF0C375A) // selected background
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color: selected ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: selected ? Colors.white : Colors.grey[400],
                size: 18,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}