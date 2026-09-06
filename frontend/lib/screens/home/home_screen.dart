import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/screens/community/community_screen.dart';
import 'package:snowtrak/screens/home/home_feed_screen.dart';
import 'package:snowtrak/screens/home/home_tab_scope.dart';
import 'package:snowtrak/screens/home/location_permission_dialog.dart';
import 'package:snowtrak/screens/maps/maps_screen.dart';
import 'package:snowtrak/screens/profile/profile_screen.dart';
import 'package:snowtrak/screens/record/record_screen.dart';
import 'package:snowtrak/services/location_service.dart';
import 'package:snowtrak/services/storage_service.dart';
import 'package:snowtrak/ui/st/st.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = HomeTab.home;
  final LocationService _locationService = LocationService();
  bool _hasCheckedPermission = false;
  final PageController _pageController =
      PageController(initialPage: HomeTab.home);

  final List<Widget> _screens = const [
    HomeFeedScreen(), // 0: Home
    MapsScreen(), // 1: Map
    RecordScreen(), // 2: Record
    CommunityScreen(), // 3: Community
    ProfileScreen(), // 4: Profile
  ];

  static const List<StNavItem> _items = [
    StNavItem(icon: StIcons.home, label: 'Home'),
    StNavItem(icon: StIcons.map, label: 'Map'),
    StNavItem(icon: StIcons.ski, label: 'Record'),
    StNavItem(icon: StIcons.messageChat, label: 'Community'),
    StNavItem(icon: StIcons.profile, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
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
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return HomeTabScope(
      selectTab: _onTabTapped,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
        bottomNavigationBar: StBottomNav(
          items: _items,
          currentIndex: safeIndex,
          recordIndex: HomeTab.record,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
