// lib/src/widgets/auth_debug_overlay.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/login_auth_holder.dart';
import '../services/auth_service.dart';

class AuthDebugOverlay extends StatefulWidget {
  const AuthDebugOverlay({super.key});
  @override
  State<AuthDebugOverlay> createState() => _AuthDebugOverlayState();
}

class _AuthDebugOverlayState extends State<AuthDebugOverlay> {
  String _inMemory = '';
  String _persistedAuth = '';
  int? _persistedExpiry;
  int _now = DateTime.now().millisecondsSinceEpoch;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = prefs.getString('Authorization') ?? prefs.getString('access_token') ?? '';
    final expiry = prefs.getInt('TokenExpiry');
    final inMem = AuthHolder.instance.authorizationHeader;
    final valid = await AuthService().isTokenValid();
    setState(() {
      _inMemory = inMem;
      _persistedAuth = auth ?? '';
      _persistedExpiry = expiry;
      _now = DateTime.now().millisecondsSinceEpoch;
      _isValid = valid;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Positioned(
      right: 12,
      top: 12,
      child: Material(
        elevation: 10,
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Auth Debug', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _refresh),
              ]),
              const SizedBox(height: 6),
              _row('In-memory header', _short(_inMemory)),
              _row('Persisted header', _short(_persistedAuth)),
              _row('Persisted expiry', _persistedExpiry?.toString() ?? 'null'),
              _row('Now (ms)', _now.toString()),
              _row('Token valid?', _isValid ? 'YES' : 'NO', valueColor: _isValid ? Colors.green : Colors.red),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () async {
                  // Print raw prefs to console for more detail
                  final prefs = await SharedPreferences.getInstance();
                  if (kDebugMode) {
                    debugPrint('--- PREFS DUMP ---');
                    debugPrint('Authorization: ${prefs.getString('Authorization')}');
                    debugPrint('TokenExpiry: ${prefs.getInt('TokenExpiry')}');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printed prefs to console (debug mode)')));
                },
                child: const Text('Dump prefs to console'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color valueColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: valueColor, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  String _short(String s, [int len = 60]) {
    if (s.isEmpty) return '<empty>';
    return s.length <= len ? s : '${s.substring(0, len)}...';
  }
}