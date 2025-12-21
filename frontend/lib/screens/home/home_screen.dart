import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/screens/activities/activities_screen.dart';
import 'package:syntrak/screens/record/record_screen.dart';
import 'package:syntrak/screens/profile/profile_screen.dart';
import 'package:syntrak/screens/groups/groups_screen.dart';
import 'package:syntrak/screens/home/location_permission_dialog.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/storage_service.dart';
import 'package:syntrak/widgets/groups_icon.dart';

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
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.fiber_manual_record),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: GroupsIcon(
              color: _currentIndex == 1 ? const Color(0xFFFF4500) : Colors.grey,
            ),
            label: 'Groups',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        selectedItemColor: const Color(0xFFFF4500),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
