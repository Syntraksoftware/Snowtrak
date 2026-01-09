import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/weather.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:syntrak/services/weather_service.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider =
          Provider.of<ActivityProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Load activities - will automatically fall back to mock data if API fails or returns empty
      activityProvider.loadActivities(refresh: true).then((_) {
        // If no activities loaded after API call, load mock data for demonstration
        if (activityProvider.activities.isEmpty &&
            !activityProvider.isLoading) {
          activityProvider.loadMockActivities();
        }
      });
      authProvider.refreshUserData(); // Refresh user data to get latest profile
      _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final weather = await _weatherService.getWeather(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (mounted) {
          setState(() {
            _weatherData = weather;
            _isLoadingWeather = false;
          });
        }
      } else {
        // Fallback to default coordinates if location not available
        final weather = await _weatherService.getWeather(
          latitude: 52.52, // Default: Berlin
          longitude: 13.41,
        );
        if (mounted) {
          setState(() {
            _weatherData = weather;
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<ActivityProvider, AuthProvider>(
          builder: (context, activityProvider, authProvider, _) {
            final user = authProvider.user;
            // Use firstName if available, otherwise fallback to email prefix
            final username =
                user?.firstName ?? user?.email.split('@')[0] ?? 'User';

            // Debug: Print user data to help diagnose issues
            if (user != null) {
              print(
                  '🔍 [ActivitiesScreen] User data - firstName: ${user.firstName}, lastName: ${user.lastName}, email: ${user.email}');
            }

            return RefreshIndicator(
              onRefresh: () async {
                await activityProvider.loadActivities(refresh: true);
                await _loadWeather();
              },
              color: SyntrakColors.primary,
              child: CustomScrollView(
                slivers: [
                  // Custom header with bell and profile
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // Welcome message
                  SliverToBoxAdapter(
                    child: _buildWelcomeMessage(username),
                  ),

                  // Weather card
                  SliverToBoxAdapter(
                    child: _buildWeatherCard(),
                  ),

                  // Introduction card
                  SliverToBoxAdapter(
                    child: _buildIntroductionCard(),
                  ),

                  // Trending card
                  SliverToBoxAdapter(
                    child: _buildTrendingCard(),
                  ),

                  // Activities section header
                  if (activityProvider.activities.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SyntrakSpacing.md,
                          SyntrakSpacing.lg,
                          SyntrakSpacing.md,
                          SyntrakSpacing.md,
                        ),
                        child: Text(
                          'Your Activities',
                          style: SyntrakTypography.headlineMedium.copyWith(
                            color: SyntrakColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                  // Activities list
                  if (activityProvider.isLoading &&
                      activityProvider.activities.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (activityProvider.activities.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height -
                                MediaQuery.of(context).padding.top -
                                MediaQuery.of(context).padding.bottom -
                                200,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(SyntrakSpacing.xl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.downhill_skiing,
                                    size: 80,
                                    color: SyntrakColors.textTertiary,
                                  ),
                                  const SizedBox(height: SyntrakSpacing.lg),
                                  Text(
                                    'No activities yet',
                                    style: SyntrakTypography.headlineMedium
                                        .copyWith(
                                      color: SyntrakColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: SyntrakSpacing.sm),
                                  Text(
                                    'Start recording your first skiing activity!',
                                    style:
                                        SyntrakTypography.bodyMedium.copyWith(
                                      color: SyntrakColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Load more when near the end
                            if (index >=
                                    activityProvider.activities.length - 3 &&
                                activityProvider.hasMore &&
                                !activityProvider.isLoadingMore) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                activityProvider.loadMore();
                              });
                            }

                            if (index >= activityProvider.activities.length) {
                              // Loading more indicator
                              return const Padding(
                                padding: EdgeInsets.all(SyntrakSpacing.lg),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final activity = activityProvider.activities[index];
                            // Get athlete info - for now use current user if it's their activity
                            final isCurrentUser = activity.userId == user?.id;
                            final athleteName = isCurrentUser
                                ? (user?.firstName ??
                                    user?.email.split('@')[0] ??
                                    'You')
                                : 'Athlete'; // TODO: Fetch actual athlete name from API

                            return _ActivityCard(
                              activity: activity,
                              athleteName: athleteName,
                            );
                          },
                          childCount: activityProvider.activities.length +
                              (activityProvider.isLoadingMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - can add logo or menu here
          const SizedBox(width: 40),

          // Right side - bell icon and profile picture
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
                tooltip: 'Notifications',
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to profile
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: SyntrakColors.primary,
                      child: user?.firstName != null
                          ? Text(
                              user!.firstName![0].toUpperCase(),
                              style: SyntrakTypography.headlineSmall.copyWith(
                                color: SyntrakColors.textOnPrimary,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: SyntrakColors.textOnPrimary,
                              size: 20,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(String username) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
        SyntrakSpacing.md,
        SyntrakSpacing.lg,
      ),
      child: Text(
        'Welcome back, $username!',
        style: SyntrakTypography.displayMedium.copyWith(
          color: SyntrakColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        0,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: BorderSide(
            color: SyntrakColors.divider,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SyntrakRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyntrakColors.primary.withOpacity(0.1),
                SyntrakColors.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Highlights",
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.md),
                if (_isLoadingWeather)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(SyntrakSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_weatherData != null)
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Weather icon and temperature
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weatherData!.condition.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(width: SyntrakSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                                  style:
                                      SyntrakTypography.displaySmall.copyWith(
                                    color: SyntrakColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: SyntrakSpacing.xs),
                                Text(
                                  _weatherData!.condition.description,
                                  style: SyntrakTypography.bodyMedium.copyWith(
                                    color: SyntrakColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Right side: Weekly forecast preview
                        if (_weatherData!.weeklyForecast.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ..._weatherData!.weeklyForecast
                                  .take(3)
                                  .map((forecast) {
                                final dayName =
                                    DateFormat('E').format(forecast.date);
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: SyntrakSpacing.xs),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dayName,
                                        style: SyntrakTypography.labelSmall
                                            .copyWith(
                                          color: SyntrakColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(width: SyntrakSpacing.xs),
                                      Text(
                                        '${forecast.maxTemp.toStringAsFixed(0)}°',
                                        style: SyntrakTypography.labelSmall
                                            .copyWith(
                                          color: SyntrakColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(SyntrakSpacing.md),
                    child: Text(
                      'Weather data unavailable',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        0,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: BorderSide(
            color: SyntrakColors.divider,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New to Syntrak?',
                      style: SyntrakTypography.headlineSmall.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.sm),
                    Text(
                      'Get started and explore new features. Track your skiing activities, connect with friends, and discover amazing trails!',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SyntrakRadius.md),
                          color: SyntrakColors.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.downhill_skiing,
                          size: 30,
                          color: SyntrakColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New to Syntrak?',
                            style: SyntrakTypography.headlineSmall.copyWith(
                              color: SyntrakColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: SyntrakSpacing.sm),
                          Text(
                            'Get started and explore new features. Track your skiing activities, connect with friends, and discover amazing trails!',
                            style: SyntrakTypography.bodyMedium.copyWith(
                              color: SyntrakColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.md),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SyntrakRadius.md),
                        color: SyntrakColors.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.downhill_skiing,
                        size: 40,
                        color: SyntrakColors.primary,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        0,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: BorderSide(
            color: SyntrakColors.divider,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SyntrakRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyntrakColors.accent.withOpacity(0.1),
                SyntrakColors.primary.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: SyntrakColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: SyntrakSpacing.sm),
                    Text(
                      'Trending Now',
                      style: SyntrakTypography.headlineSmall.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.md),
                Text(
                  'Join the community and see what\'s popular this week!',
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to trending/community
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SyntrakColors.accent,
                    foregroundColor: SyntrakColors.textOnPrimary,
                  ),
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final String? athleteName;

  const _ActivityCard({
    required this.activity,
    this.athleteName,
  });

  @override
  Widget build(BuildContext context) {
    final activityColor = ActivityHelpers.getActivityColor(activity.type);
    final activityIcon = ActivityHelpers.getActivityIcon(activity.type);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(
          color: SyntrakColors.divider,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(activityId: activity.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Athlete info, timestamp, privacy, activity type
            Padding(
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              child: Row(
                children: [
                  // Athlete avatar
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to profile
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: SyntrakColors.primary,
                      child: _buildDefaultAvatar(),
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  // Athlete name and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              athleteName ?? 'You',
                              style: SyntrakTypography.bodyMedium.copyWith(
                                color: SyntrakColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: SyntrakSpacing.xs),
                            // Privacy icon
                            if (!activity.isPublic)
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: SyntrakColors.textTertiary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatRelativeTime(activity.startTime),
                              style: SyntrakTypography.labelSmall.copyWith(
                                color: SyntrakColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: SyntrakSpacing.xs),
                            // Activity type icon
                            Icon(
                              activityIcon,
                              size: 14,
                              color: activityColor,
                            ),
                            const SizedBox(width: SyntrakSpacing.xs),
                            // Device source tag (placeholder - would come from activity metadata)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SyntrakSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: SyntrakColors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(SyntrakRadius.sm),
                              ),
                              child: Text(
                                'Phone',
                                style: SyntrakTypography.labelSmall.copyWith(
                                  color: SyntrakColors.textTertiary,
                                  fontSize: 10,
                                ),
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

            // Body: Activity title
            if (activity.name != null && activity.name!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SyntrakSpacing.md,
                  0,
                  SyntrakSpacing.md,
                  SyntrakSpacing.sm,
                ),
                child: Text(
                  activity.name!,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SyntrakSpacing.md,
                  0,
                  SyntrakSpacing.md,
                  SyntrakSpacing.sm,
                ),
                child: Text(
                  '${activity.type.displayName} Activity',
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
              ),

            // Key stats row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Distance', activity.formattedDistance),
                  _buildStat('Time', _formatMovingTime(activity.duration)),
                  _buildStat('Elevation',
                      '${activity.elevationGain.toStringAsFixed(0)}m'),
                  _buildStat('Speed', activity.formattedSpeed),
                ],
              ),
            ),

            const SizedBox(height: SyntrakSpacing.md),

            // Rich media: Map thumbnail
            if (activity.locations.isNotEmpty)
              _buildMapThumbnail(activity.locations, activityColor)
            else
              Container(
                height: 200,
                color: SyntrakColors.surfaceVariant,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: SyntrakColors.textTertiary,
                        size: 40,
                      ),
                      const SizedBox(height: SyntrakSpacing.sm),
                      Text(
                        'No route data',
                        style: SyntrakTypography.bodySmall.copyWith(
                          color: SyntrakColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Derived badges
            if (_hasBadges(activity))
              Padding(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                child: Wrap(
                  spacing: SyntrakSpacing.sm,
                  runSpacing: SyntrakSpacing.xs,
                  children: _buildBadges(activity, activityColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      (athleteName ?? 'U')[0].toUpperCase(),
      style: SyntrakTypography.headlineSmall.copyWith(
        color: SyntrakColors.textOnPrimary,
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatMovingTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SyntrakSpacing.xs / 2),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapThumbnail(List locations, Color routeColor) {
    // For now, use a placeholder. In production, this would generate a static map image
    // or use Google Maps Static API
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SyntrakColors.surfaceVariant,
      ),
      child: Stack(
        children: [
          // Placeholder map background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SyntrakColors.primary.withOpacity(0.1),
                  SyntrakColors.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 60,
                color: SyntrakColors.textTertiary.withOpacity(0.3),
              ),
            ),
          ),
          // Route indicator overlay
          if (locations.length > 1)
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(
                  locations: locations,
                  color: routeColor,
                ),
              ),
            ),
          // Map overlay label
          Positioned(
            bottom: SyntrakSpacing.sm,
            right: SyntrakSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.sm,
                vertical: SyntrakSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(SyntrakRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: SyntrakSpacing.xs / 2),
                  Text(
                    'View on map',
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: Colors.white,
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

  bool _hasBadges(Activity activity) {
    // MVP: Simple PR badge logic (can be enhanced later)
    // For now, we'll show a badge if it's a long activity or has high elevation
    return activity.distance > 5000 || activity.elevationGain > 500;
  }

  List<Widget> _buildBadges(Activity activity, Color activityColor) {
    final badges = <Widget>[];

    // Longest activity badge (simplified - would compare with user's history)
    if (activity.distance > 10000) {
      badges.add(_buildBadge(
        icon: Icons.emoji_events,
        label: 'Long',
        color: SyntrakColors.accent,
      ));
    }

    // High elevation badge
    if (activity.elevationGain > 1000) {
      badges.add(_buildBadge(
        icon: Icons.trending_up,
        label: 'Elevation',
        color: SyntrakColors.secondary,
      ));
    }

    // PR badge (placeholder - would require comparing with user's history)
    if (activity.distance > 5000 && activity.elevationGain > 500) {
      badges.add(_buildBadge(
        icon: Icons.star,
        label: 'PR',
        color: SyntrakColors.accent,
      ));
    }

    return badges;
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.sm,
        vertical: SyntrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SyntrakRadius.md),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: SyntrakSpacing.xs / 2),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple route painter for map thumbnail
class _RoutePainter extends CustomPainter {
  final List locations;
  final Color color;

  _RoutePainter({
    required this.locations,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Normalize locations to canvas coordinates
    // This is a simplified version - in production, use proper map projection
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var loc in locations) {
      minLat = minLat < loc.latitude ? minLat : loc.latitude;
      maxLat = maxLat > loc.latitude ? maxLat : loc.latitude;
      minLng = minLng < loc.longitude ? minLng : loc.longitude;
      maxLng = maxLng > loc.longitude ? maxLng : loc.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    if (latRange == 0 || lngRange == 0) return;

    bool isFirst = true;
    for (var loc in locations) {
      final x = ((loc.longitude - minLng) / lngRange) * size.width;
      final y =
          size.height - ((loc.latitude - minLat) / latRange) * size.height;

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) {
    return oldDelegate.locations != locations || oldDelegate.color != color;
  }
}
