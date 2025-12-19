// lib/src/ui/profile_header.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.grey[200],
              width: 96,
              height: 96,
              child: const Icon(Icons.person, size: 64, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xff212121))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                Chip(label: Text(profile.type.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: const Color(0xff66d47e)),
                Chip(label: Text(profile.storeId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: const Color(0xff40bfff)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.email, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(profile.email, style: const TextStyle(color: Color(0xff616161), fontSize: 15)),
                const SizedBox(width: 18),
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(profile.phone, style: const TextStyle(color: Color(0xff616161), fontSize: 15)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.badge, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('User ID: ${profile.userId}', style: const TextStyle(color: Color(0xff616161), fontSize: 15)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}