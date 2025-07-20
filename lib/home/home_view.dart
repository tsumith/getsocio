import 'package:flutter/material.dart';
import 'package:getsocio/authentication/logic/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.menu, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Search music, artists...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Scroll: Albums / Categories
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder:
                (context, index) => Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
          ),
        ),

        const SizedBox(height: 16),

        // Circle Profiles (e.g. Friends, Artists)
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder:
                (context, index) => Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
          ),
        ),

        const SizedBox(height: 16),

        // Featured Track or Playlist Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            authService.logout(context);
          },
          child: Text("sign out"),
        ),
      ],
    );
  }
}
