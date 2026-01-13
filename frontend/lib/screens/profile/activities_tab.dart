import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Service class for activity-related API calls
/// This provides clean endpoints for future backend integration
class ActivityService {
  // TODO: Replace with actual API service when backend is ready
  // Example endpoints:
  // - GET /api/v1/activities/me?search={query}&type={type}&date_from={date}&date_to={date}
  // - GET /api/v1/activities/{id}
  // - POST /api/v1/activities/{id}/kudos
  // - DELETE /api/v1/activities/{id}/kudos
  // - GET /api/v1/activities/{id}/comments
  // - POST /api/v1/activities/{id}/comments

  Future<List<Activity>> getUserActivities({
    String? searchQuery,
    ActivityType? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // TODO: Implement actual API call
    // For now, return mock data
    return _getMockActivities();
  }

  Future<void> toggleKudos(String activityId) async {
    // TODO: Implement API call to toggle kudos
  }

  Future<void> shareActivity(String activityId) async {
    // TODO: Implement share functionality
  }

  Future<void> addComment(String activityId, String comment) async {
    // TODO: Implement API call to add comment
  }

  List<Activity> _getMockActivities() {
    // Create a date matching the reference: January 27, 2025 at 9:30 PM
    final activityDate = DateTime(2025, 1, 27, 21, 30);
    final now = DateTime.now();

    return [
      Activity(
        id: '1',
        userId: 'user1',
        type: ActivityType.alpine,
        name: 'Night Hike',
        distance: 1390, // 1.39 km
        duration: 773, // 12m 53s
        elevationGain: 10, // 10m
        startTime: activityDate,
        endTime: activityDate.add(const Duration(minutes: 12, seconds: 53)),
        averagePace: 556, // ~9:16 min/km
        maxPace: 500,
        isPublic: true,
        createdAt: activityDate,
        locations: [],
      ),
      Activity(
        id: '2',
        userId: 'user1',
        type: ActivityType.alpine,
        name: 'Morning Alpine Run',
        distance: 12500, // 12.5 km
        duration: 3600, // 1 hour
        elevationGain: 850, // 850m
        startTime: now.subtract(const Duration(days: 2, hours: 2)),
        endTime: now.subtract(const Duration(days: 2, hours: 1)),
        averagePace: 288, // 4:48 min/km
        maxPace: 240, // 4:00 min/km
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 2)),
        locations: [],
      ),
      Activity(
        id: '3',
        userId: 'user1',
        type: ActivityType.backcountry,
        name: 'Backcountry Adventure',
        distance: 18500, // 18.5 km
        duration: 7200, // 2 hours
        elevationGain: 1200, // 1200m
        startTime: now.subtract(const Duration(days: 5, hours: 3)),
        endTime: now.subtract(const Duration(days: 5, hours: 1)),
        averagePace: 389, // 6:29 min/km
        maxPace: 320, // 5:20 min/km
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 5)),
        locations: [],
      ),
    ];
  }
}

class ActivitiesTab extends StatefulWidget {
  final List<Activity> activities;

  const ActivitiesTab({
    super.key,
    required this.activities,
  });

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  final ActivityService _activityService = ActivityService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;
  final Map<String, bool> _kudosMap = {}; // activityId -> hasKudos
  final Map<String, int> _kudosCountMap = {}; // activityId -> count

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    // Use mock data from ActivityService
    final activities = await _activityService.getUserActivities();

    // Sort activities by startTime (most recent first)
    activities.sort((a, b) => b.startTime.compareTo(a.startTime));

    setState(() {
      _activities = activities;
      _filteredActivities = activities;

      for (var activity in activities) {
        _kudosMap[activity.id] = false;
        _kudosCountMap[activity.id] =
            activity.id == activities.first.id ? 1 : 0;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterActivities();
    });
  }

  void _filterActivities() {
    if (_searchQuery.isEmpty) {
      _filteredActivities = _activities;
    } else {
      _filteredActivities = _activities.where((activity) {
        final name = (activity.name ?? activity.type.displayName).toLowerCase();
        final type = activity.type.displayName.toLowerCase();
        return name.contains(_searchQuery) || type.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    if (_isLoading) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPinnedSearchBar(innerBoxIsScrolled),
        ],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredActivities.isEmpty && _searchQuery.isNotEmpty) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPinnedSearchBar(innerBoxIsScrolled),
        ],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: SyntrakColors.textTertiary,
              ),
              const SizedBox(height: SyntrakSpacing.md),
              Text(
                'No activities found',
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: SyntrakColors.textSecondary,
                ),
              ),
              const SizedBox(height: SyntrakSpacing.sm),
              Text(
                'Try a different search term',
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredActivities.isEmpty) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPinnedSearchBar(innerBoxIsScrolled),
        ],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.downhill_skiing,
                  size: 80,
                  color: SyntrakColors.textTertiary,
                ),
                const SizedBox(height: SyntrakSpacing.lg),
                Text(
                  'No activities yet',
                  style: SyntrakTypography.headlineMedium.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.sm),
                Text(
                  'Start recording your first skiing activity!',
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildPinnedSearchBar(innerBoxIsScrolled),
      ],
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        color: SyntrakColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          itemCount: _filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = _filteredActivities[index];
            // First activity (index 0) is the most recent and should show kudos card
            final isFirstActivity = index == 0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _filteredActivities.length - 1
                    ? SyntrakSpacing.md
                    : 0,
              ),
              child: _ActivityCard(
                activity: activity,
                user: user,
                isFirstActivity: isFirstActivity,
                hasKudos: _kudosMap[activity.id] ?? false,
                kudosCount: _kudosCountMap[activity.id] ?? 0,
                onKudosToggle: () => _toggleKudos(activity.id),
                onShare: () => _shareActivity(activity.id),
                onComment: () => _commentActivity(activity.id),
              ),
            );
          },
        ),
      ),
    );
  }

  // Pinned search bar that stays fixed at top
  SliverAppBar _buildPinnedSearchBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: SyntrakColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: innerBoxIsScrolled ? 2 : 0,
      shadowColor: Colors.black26,
      toolbarHeight: 72,
      flexibleSpace: _buildSearchBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      decoration: BoxDecoration(
        color: SyntrakColors.background,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search and filter your activities',
          hintStyle: SyntrakTypography.bodySmall.copyWith(
            color: SyntrakColors.textTertiary.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: SyntrakColors.textTertiary.withOpacity(0.6),
            size: 18,
          ),
          filled: true,
          fillColor: SyntrakColors.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyntrakRadius.xl),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyntrakRadius.xl),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyntrakRadius.xl),
            borderSide: BorderSide(
              color: SyntrakColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.md,
            vertical: SyntrakSpacing.sm,
          ),
          isDense: true,
        ),
        style: SyntrakTypography.bodySmall.copyWith(
          fontSize: 13,
        ),
      ),
    );
  }

  void _toggleKudos(String activityId) {
    setState(() {
      final currentValue = _kudosMap[activityId] ?? false;
      _kudosMap[activityId] = !currentValue;
      final currentCount = _kudosCountMap[activityId] ?? 0;
      _kudosCountMap[activityId] =
          currentValue ? currentCount - 1 : currentCount + 1;
    });
    _activityService.toggleKudos(activityId);
  }

  void _shareActivity(String activityId) {
    _activityService.shareActivity(activityId);
    // TODO: Show share dialog
  }

  void _commentActivity(String activityId) {
    // TODO: Navigate to comments screen
    _activityService.addComment(activityId, '');
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final User? user;
  final bool isFirstActivity;
  final bool hasKudos;
  final int kudosCount;
  final VoidCallback onKudosToggle;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const _ActivityCard({
    required this.activity,
    required this.user,
    required this.isFirstActivity,
    required this.hasKudos,
    required this.kudosCount,
    required this.onKudosToggle,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Header: User info, date/time, device, location
          Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: SyntrakColors.surfaceVariant,
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: SyntrakColors.textTertiary,
                        ),
                ),
                const SizedBox(width: SyntrakSpacing.md),
                // User info and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name
                      Text(
                        user?.fullName ?? 'User',
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: SyntrakSpacing.xs / 2),

                      Text(
                        '${_formatDateTime(activity.startTime)} • Apple Watch SE',
                        style: SyntrakTypography.labelSmall.copyWith(
                          color: SyntrakColors.textTertiary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SyntrakSpacing.xs / 2),
                      // Location with shoe icon
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: SyntrakColors.textTertiary,
                          ),
                          const SizedBox(width: SyntrakSpacing.xs / 2),
                          Expanded(
                            child: Text(
                              'Finland, Tampere',
                              style: SyntrakTypography.labelSmall.copyWith(
                                color: SyntrakColors.textTertiary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Activity Name and Metrics
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SyntrakSpacing.md,
              0,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name ?? activity.type.displayName,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.sm),
                // Metrics: Distance, Elev Gain, Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child:
                          _buildMetric('Distance', activity.formattedDistance),
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Expanded(
                      child: _buildMetric(
                          'Elev Gain', activity.formattedVerticalDrop),
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Expanded(
                      child: _buildMetric('Time', activity.formattedDuration),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kudos card (if first activity - most recent)
          if (isFirstActivity) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                decoration: BoxDecoration(
                  color: SyntrakColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SyntrakRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SyntrakColors.primary,
                            SyntrakColors.accent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: SyntrakTypography.labelLarge.copyWith(
                            color: SyntrakColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.md),
                    Expanded(
                      child: Text(
                        'Kudos on your first activity!',
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to kudos/achievements screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SyntrakColors.accent,
                        foregroundColor: SyntrakColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.md,
                          vertical: SyntrakSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View',
                        style: SyntrakTypography.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
          ],

          // Map preview (using demo image for now) - Full width
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SyntrakColors.surfaceVariant,
            ),
            child: ClipRRect(
              child: _buildMapPreview(),
            ),
          ),

          const SizedBox(height: SyntrakSpacing.md),

          // Action buttons: Like, Comment, Share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: hasKudos ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  count: kudosCount,
                  color: hasKudos
                      ? SyntrakColors.primary
                      : SyntrakColors.textSecondary,
                  onTap: onKudosToggle,
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: onComment,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: onShare,
                ),
              ],
            ),
          ),

          const SizedBox(height: SyntrakSpacing.md),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: SyntrakSpacing.xs / 2),
        Text(
          value,
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    // Use demo image for now
    // TODO: Replace with actual Google Maps when map services are enabled
    try {
      return Image.asset(
        'assets/images/activities_demo_1.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: SyntrakColors.surfaceVariant,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    color: SyntrakColors.textTertiary,
                    size: 40,
                  ),
                  const SizedBox(height: SyntrakSpacing.sm),
                  Text(
                    'Map preview',
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: SyntrakColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.map,
            color: SyntrakColors.textTertiary,
            size: 40,
          ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? count,
    Color? color,
    required VoidCallback onTap,
  }) {
    final buttonColor = color ?? SyntrakColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SyntrakRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: buttonColor,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: SyntrakSpacing.xs),
              Text(
                count.toString(),
                style: SyntrakTypography.bodySmall.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: SyntrakSpacing.xs),
            Text(
              label,
              style: SyntrakTypography.labelMedium.copyWith(
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final dateFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');
    return dateFormat.format(date);
  }
}
