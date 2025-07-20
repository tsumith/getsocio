import 'package:flutter/material.dart';
import 'package:getsocio/home/fav_view.dart';
import 'package:getsocio/home/home_view.dart';
import 'package:getsocio/home/lib_view.dart';
import 'package:getsocio/home/profile_view.dart';
import 'package:getsocio/widgets/shell_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeView(),
    FavView(),
    LibView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          Expanded(child: _screens[_currentIndex]),
          ShellPlayer(),
          BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.05),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            currentIndex: _currentIndex,
            onTap: (val) {
              setState(() {
                _currentIndex = val;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
