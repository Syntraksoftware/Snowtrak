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
      activityProvider.loadActivities();
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
                await activityProvider.loadActivities();
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
                      child: Center(
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
                                style:
                                    SyntrakTypography.headlineMedium.copyWith(
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
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final activity = activityProvider.activities[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: SyntrakSpacing.md),
                              child: _ActivityCard(activity: activity),
                            );
                          },
                          childCount: activityProvider.activities.length,
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

  const _ActivityCard({required this.activity});

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
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(SyntrakSpacing.sm),
                    decoration: BoxDecoration(
                      color: activityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(SyntrakRadius.md),
                    ),
                    child: Icon(
                      activityIcon,
                      color: activityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.type.displayName,
                          style: SyntrakTypography.headlineSmall.copyWith(
                            color: SyntrakColors.textPrimary,
                          ),
                        ),
                        if (activity.name != null && activity.name!.isNotEmpty)
                          Text(
                            activity.name!,
                            style: SyntrakTypography.bodySmall.copyWith(
                              color: SyntrakColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(activity.startTime),
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SyntrakSpacing.md),
              // Skiing-specific metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Vertical', activity.formattedVerticalDrop),
                  _buildMetric('Distance', activity.formattedDistance),
                  _buildMetric('Time', activity.formattedDuration),
                  _buildMetric('Speed', activity.formattedSpeed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SyntrakTypography.metricMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SyntrakSpacing.xs),
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
}
