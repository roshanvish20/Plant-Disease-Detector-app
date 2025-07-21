import 'package:flutter/material.dart';
import 'package:demos/PlantDetectorScreen.dart';
import 'package:demos/screens/history_page.dart';
import 'package:demos/screens/profile_page.dart';
import 'dart:ui';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override 
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  // Initialize with late but make sure it's actually initialized in initState
  late AnimationController _animationController;
  bool _isAnimationInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _isAnimationInitialized = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_isAnimationInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        if (_isAnimationInitialized) {
          _animationController.reset();
          _animationController.forward();
        }
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuint,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Let content flow behind navbar
      body: Stack(
        children: [
          // Page content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              PlantDetectorScreen(),
              HistoryPage(),
              ProfilePage(),
            ],
          ),
          
          // Floating action button with grow animation
          if (_currentIndex == 0 && _isAnimationInitialized)
            Positioned(
              right: 20,
              bottom: 100,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _animationController..forward(),
                  curve: Curves.elasticOut,
                ),
                child: FloatingActionButton(
                  heroTag: "capture",
                  backgroundColor: Colors.green.shade600,
                  elevation: 8,
                  onPressed: () {
                    // Show a quick animated feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        width: 200,
                        content: const Text('Capture plant photo'),
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
      
      // Glassmorphism bottom navigation bar
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 10, 143, 72).withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              selectedIconTheme: const IconThemeData(size: 30),
              unselectedIconTheme: const IconThemeData(size: 24),
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.home_rounded),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.history_rounded),
                  ),
                  label: "History",
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.person_rounded),
                  ),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}