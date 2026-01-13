import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/activities/activities_screen.dart';
import 'package:syntrak/screens/record/record_screen.dart';
import 'package:syntrak/screens/profile/profile_screen.dart';
import 'package:syntrak/screens/groups/groups_screen.dart';
import 'package:syntrak/screens/community/community_screen.dart';
import 'package:syntrak/screens/home/location_permission_dialog.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();
  bool _hasCheckedPermission = false;
  final PageController _pageController = PageController();

  // Restructured navigation order: Map, Community, Home, Groups/Activities, You
  final List<Widget> _screens = [
    const RecordScreen(),      // 0: Map (Record Activities)
    const CommunityScreen(),   // 1: Community
    const ActivitiesScreen(),  // 2: Home (Activities Feed)
    const GroupsScreen(),      // 3: Groups/Activities
    const ProfileScreen(),     // 4: You (Profile)
  ];

  @override
  void initState() {
    super.initState();
    // Ensure currentIndex is within bounds on initialization
    _currentIndex = _currentIndex.clamp(0, _screens.length - 1);
    // Check and ask for location permission after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    if (_hasCheckedPermission) return;
    _hasCheckedPermission = true;

    final storageService = Provider.of<StorageService>(context, listen: false);

    // Only ask if we haven't asked before
    if (!storageService.locationPermissionAsked && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final granted = await LocationPermissionDialog.show(
        context,
        _locationService,
      );

      // Mark that we've asked
      if (granted != null) {
        await storageService.setLocationPermissionAsked(true);
      }
    }
  }

  void _onTabTapped(int index) {
    if (index >= 0 && index < _screens.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is within bounds
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: SyntrakElevation.md,
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }
}
