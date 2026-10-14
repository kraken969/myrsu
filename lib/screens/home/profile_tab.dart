import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_photo_picker.dart';
import '../onboarding/select_major_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return StreamBuilder<AppUser?>(
      stream: FirestoreService.instance.watchUser(uid),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      ProfilePhotoPicker(photoUrl: user.photoUrl, name: user.name, radius: 40),
                      const SizedBox(height: 8),
                      Text('Tap to change photo', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Column(
                    children: [
                      _InfoTile(icon: Icons.badge_outlined, label: 'Student ID', value: user.studentId ?? 'Not set'),
                      const Divider(height: 1),
                      _InfoTile(icon: Icons.school_outlined, label: 'Major', value: user.majorName ?? 'Not set'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectMajorScreen())),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change major / student ID'),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: RsuColors.danger),
                  onPressed: () => AuthService.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: RsuColors.navy),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}
