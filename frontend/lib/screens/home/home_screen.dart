import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/screens/activities/activities_screen.dart';
import 'package:syntrak/screens/record/record_screen.dart';
import 'package:syntrak/screens/profile/profile_screen.dart';
import 'package:syntrak/screens/groups/groups_screen.dart';
import 'package:syntrak/screens/community/community_screen.dart';
import 'package:syntrak/screens/home/location_permission_dialog.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/storage_service.dart';
import 'package:syntrak/widgets/groups_icon.dart';
import 'package:syntrak/widgets/logo_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();
  bool _hasCheckedPermission = false;

  final List<Widget> _screens = [
    const RecordScreen(),
    const GroupsScreen(),
    const ActivitiesScreen(), // Home in the middle
    const CommunityScreen(),
    const ProfileScreen(),
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

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is within bounds
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: _screens[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) {
          if (index >= 0 && index < _screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.fiber_manual_record,
              color: safeIndex == 0 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GroupsIcon(
              color: safeIndex == 1 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: safeIndex == 2 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
              color: safeIndex == 3 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
              color: safeIndex == 4 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: '',
          ),
        ],
        selectedItemColor: const Color(0xFFFF4500),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
