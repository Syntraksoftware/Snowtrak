import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadActivities();
  }

  Future<void> _initializeMap() async {
    try {
      // Check permissions
      final hasPermission = await _locationService.checkPermissions();

      if (!hasPermission) {
        // Use default location if no permission
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194), // San Francisco
            zoom: 12,
          );
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      if (position != null) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13,
          );
          _isLoading = false;
        });
      } else {
        // Fallback to default
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(37.7749, -122.4194),
            zoom: 12,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔍 [MapsScreen] Error initializing map: $e');
      setState(() {
        _hasError = true;
        _errorMessage = "Failed to initialize map";
        _isLoading = false;
        _initialCameraPosition = const CameraPosition(
          target: LatLng(37.7749, -122.4194),
          zoom: 12,
        );
      });
    }
  }

  Future<void> _loadActivities() async {
    try {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      await provider.loadActivities();
      
      setState(() {
        _activities = provider.activities;
      });
      
      _updateMapMarkers();
    } catch (e) {
      print('🔍 [MapsScreen] Error loading activities: $e');
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (int i = 0; i < _activities.length; i++) {
      final activity = _activities[i];
      if (activity.locations.isEmpty) continue;

      final startLocation = activity.locations.first;
      final endLocation = activity.locations.last;

      // Create marker for start point
      markers.add(
        Marker(
          markerId: MarkerId('start_${activity.id}'),
          position: LatLng(startLocation.latitude, startLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: activity.type.displayName,
            snippet: 'Start: ${activity.formattedDistance}',
            onTap: () => _showActivityDetails(activity),
          ),
        ),
      );

      // Create marker for end point (if different from start)
      if (activity.locations.length > 1) {
        final distance = _calculateDistance(
          startLocation.latitude,
          startLocation.longitude,
          endLocation.latitude,
          endLocation.longitude,
        );

        if (distance > 50) {
          // Only show end marker if it's more than 50m away
          markers.add(
            Marker(
              markerId: MarkerId('end_${activity.id}'),
              position: LatLng(endLocation.latitude, endLocation.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: activity.type.displayName,
                snippet: 'End: ${activity.formattedDistance}',
                onTap: () => _showActivityDetails(activity),
              ),
            ),
          );
        }
      }

      // Create polyline for route
      if (activity.locations.length > 1) {
        final points = activity.locations
            .map((loc) => LatLng(loc.latitude, loc.longitude))
            .toList();

      // Use different colors for different activity types
      final color = ActivityHelpers.getActivityColor(activity.type);

        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${activity.id}'),
            points: points,
            color: color,
            width: 4,
            patterns: [],
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }


  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Use Geolocator's distance calculation
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void _showActivityDetails(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }

  Future<void> _centerOnMyLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    }
  }

  void _toggleMapType() {
    // This would toggle between map types
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map type toggle coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _initialCameraPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maps'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? "Failed to load map",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _initializeMap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading || _initialCameraPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maps'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnMyLocation,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _toggleMapType,
            tooltip: 'Change map type',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition!,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
          ),
          // Activity list overlay
          if (_activities.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${_activities.length} Activities',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return _ActivityCard(
                            activity: activity,
                            onTap: () => _showActivityDetails(activity),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    ActivityHelpers.getActivityIcon(activity.type),
                    color: ActivityHelpers.getActivityColor(activity.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.type.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.formattedDistance,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
