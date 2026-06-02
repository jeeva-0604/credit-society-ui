import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';

class CommonBottomBar extends StatelessWidget {
  final bool isVisible;
  final double height;
  final int currentIndex;
  final Function(int) onTap;
  final String studentName;
  final String imagePath;

  const CommonBottomBar({
    super.key,
    required this.isVisible,
    required this.height,
    required this.currentIndex,
    required this.onTap,
    required this.studentName,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔻 Bottom Navigation Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isVisible ? height : 0.0,
            curve: Curves.easeInOut,
            child: Wrap(
              children: [
                BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: onTap,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.purple,
                  unselectedItemColor: Colors.grey,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: SizedBox(height: 0), label: ''),
                    BottomNavigationBarItem(icon: Icon(Icons.bus_alert), label: 'Bus Tracking'),
                    BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 🎯 Floating Profile Image
        Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(imagePath),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
