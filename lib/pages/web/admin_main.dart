import 'package:flutter/material.dart';
import 'package:pawsense/pages/web/appointment_screen.dart';
import '../../core/widgets/navigation/side_navigation.dart';
import '../../core/widgets/navigation/top_nav_bar.dart';
import '../../core/utils/app_colors.dart';
import '../../pages/web/dashboard_screen.dart';

class AdminMain extends StatefulWidget {
  @override
  _AdminMainState createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    AppointmentManagementScreen(),
  ];

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < _pages.length)
        ? _selectedIndex
        : 0;

    if (safeIndex != _selectedIndex) {
      debugPrint("⚠ Invalid selectedIndex $_selectedIndex — defaulting to 0");
    }

    return Scaffold(
      body: Row(
        children: [
          SideNavigation(
            selectedIndex: _selectedIndex,
            onItemSelected: _onNavItemSelected,
          ),
          Expanded(
            child: Column(
              children: [
                TopNavBar(),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: _pages[safeIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
