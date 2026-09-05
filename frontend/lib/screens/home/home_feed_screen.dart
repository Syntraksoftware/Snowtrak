import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/features/activities/data/activities_context_repository.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/activities/activities_screen_controller.dart';
import 'package:snowtrak/screens/activities/activity_detail_screen.dart';
import 'package:snowtrak/screens/home/home_tab_scope.dart';
import 'package:snowtrak/screens/home/widgets/recent_activity_section.dart';
import 'package:snowtrak/screens/home/widgets/resort_conditions_card.dart';
import 'package:snowtrak/screens/home/widgets/stats_carousel.dart';
import 'package:snowtrak/screens/notifications/notifications_screen.dart';
import 'package:snowtrak/ui/st/st.dart';

/// The Home tab, built to `12 layout now / Home screen` in the design file:
/// greeting → conditions + the one action → your numbers → what's new.
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final ActivitiesScreenController _controller = const ActivitiesScreenController();
  WeatherData? _weather;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final contextRepository = context.read<ActivitiesContextRepository>();
    final activityProvider = context.read<ActivityProvider>();

    final cached = await contextRepository.readCachedWeather();
    if (!mounted) return;
    setState(() {
      _weather = cached;
      _isLoadingWeather = cached == null;
    });

    final authProvider = context.read<AuthProvider>();
    await activityProvider.hydrateFromCache();
    await _controller.loadInitialData(
      activityProvider: activityProvider,
      authProvider: authProvider,
      contextRepository: contextRepository,
      onWeatherLoaded: _onWeatherLoaded,
    );
  }

  Future<void> _refresh() async {
    if (_weather == null) setState(() => _isLoadingWeather = true);
    await _controller.refreshData(
      activityProvider: context.read<ActivityProvider>(),
      contextRepository: context.read<ActivitiesContextRepository>(),
      onWeatherLoaded: _onWeatherLoaded,
    );
  }

  Future<void> _onWeatherLoaded(WeatherData? weather) async {
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _isLoadingWeather = false;
    });
  }

  void _openActivity(Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Consumer2<ActivityProvider, AuthProvider>(
          builder: (context, activityProvider, authProvider, _) {
            final user = authProvider.user;
            final name = user?.firstName ?? user?.email.split('@').first ?? 'there';
            final activities = activityProvider.activities;

            return Column(
              children: [
                StPageHeader(
                  eyebrow: _greeting(),
                  title: name,
                  actions: [
                    StRoundButton(
                      icon: StIcons.search,
                      tooltip: 'Search',
                      onTap: () => HomeTabScope.selectTabOrNull(context, HomeTab.map),
                    ),
                    StRoundButton(
                      icon: StIcons.bell,
                      tooltip: 'Notifications',
                      badge: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: context.colors.primary,
                    child: ListView(
                      // Cards sit at 16pt gutters, section headers at 20pt —
                      // each block owns its own padding.
                      padding: const EdgeInsets.only(
                        bottom: SnowtrakSpacing.xxl,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SnowtrakSpacing.md,
                          ),
                          child: ResortConditionsCard(
                            weather: _weather,
                            isLoading: _isLoadingWeather,
                            onStartSession: () =>
                                HomeTabScope.selectTabOrNull(context, HomeTab.record),
                          ),
                        ),
                        const SizedBox(height: SnowtrakSpacing.md),
                        StatsCarousel(
                          activities: activities,
                          onOpenActivity: _openActivity,
                        ),
                        const SizedBox(height: SnowtrakSpacing.md),
                        RecentActivitySection(
                          activities: activities,
                          // Profile, not Community: the section lists the
                          // viewer's own activities, and Profile's
                          // Activities tab is where all of them live.
                          onSeeAll: () =>
                              HomeTabScope.selectTabOrNull(context, HomeTab.profile),
                          onOpenActivity: _openActivity,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
