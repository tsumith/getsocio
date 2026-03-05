import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:getsocio/auth/logic/auth_provider.dart'; // Ensure correct path
import 'package:getsocio/auth/logic/auth_service.dart';
import 'package:shimmer/shimmer.dart';
import 'music_lib/lib_provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // Helper Method for Confirmation
    void _showClearCacheDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text("Clear Music Library?",
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                  "This will delete all imported tracks and saved album covers.",
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    context.read<LibProvider>().nukeLibrary();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Library cleared successfully"))
                    );
                  },
                  child: const Text(
                      "Clear All", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: authService.getUserProfile(),
        builder: (context, snapshot) {
          // 1. Check if we are still loading
          final bool isLoading = snapshot.connectionState ==
              ConnectionState.waiting;

          final data = snapshot.data;
          final username = data?['username'] ?? "";
          final email = data?['email'] ?? "";

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // 2. Profile Header (Switches between Skeleton and Real Data)
                isLoading
                    ? const _ProfileSkeleton()
                    : _buildHeader(username, email),

                const SizedBox(height: 40),

                _buildProfileTile(Icons.settings_outlined, "Settings", () {}),
                _buildProfileTile(Icons.history, "Listening History", () {}),
                _buildProfileTile(
                    Icons.download_done_rounded, "Downloads", () {}),
                _buildProfileTile(
                    Icons.delete_outline_rounded, "Clear Cache", () =>
                    _showClearCacheDialog(context)),

                const Divider(color: Colors.white10, indent: 20, endIndent: 20),

                _buildProfileTile(
                  Icons.logout_rounded,
                  "Logout",
                      () =>
                      Provider.of<AuthProvider>(context, listen: false).logout(
                          context),
                  color: Colors.redAccent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
    );
  }

  Widget _buildHeader(String username, String email) {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

}
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Center(
        child: Column(
          children: [
            // Avatar Circle
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(height: 16),
            // Username Bar
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 8),
            // Email Bar
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}