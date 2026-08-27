import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/features/activities/data/activities_context_repository.dart';
import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/activities/activities_screen_controller.dart';
import 'package:snowtrak/screens/activities/widgets/activities_feed_sliver.dart';
import 'package:snowtrak/screens/activities/widgets/activities_header.dart';
import 'package:snowtrak/screens/activities/widgets/introduction_card.dart';
import 'package:snowtrak/screens/activities/widgets/trending_card.dart';
import 'package:snowtrak/screens/activities/widgets/weather_card.dart';
import 'package:snowtrak/screens/home/home_tab_scope.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ActivitiesScreenController _controller = const ActivitiesScreenController();
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider =
          Provider.of<ActivityProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final contextRepository = context.read<ActivitiesContextRepository>();
      _initializeWeather(contextRepository);
      activityProvider.hydrateFromCache();
      _controller.loadInitialData(
        activityProvider: activityProvider,
        authProvider: authProvider,
        contextRepository: contextRepository,
        onWeatherLoaded: _onWeatherLoaded,
      );
    });
  }

  Future<void> _initializeWeather(
    ActivitiesContextRepository contextRepository,
  ) async {
    final cached = await contextRepository.readCachedWeather();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _weatherData = cached;
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });
  }

  Future<void> _loadWeather() async {
    if (_weatherData == null) {
      _setWeatherLoading(true);
    }
    final contextRepository = context.read<ActivitiesContextRepository>();
    await _controller.refreshData(
      activityProvider: context.read<ActivityProvider>(),
      contextRepository: contextRepository,
      onWeatherLoaded: _onWeatherLoaded,
    );
  }

  void _setWeatherLoading(bool isLoading) {
    if (!mounted) return;
    setState(() {
      _isLoadingWeather = isLoading;
    });
  }

  Future<void> _onWeatherLoaded(WeatherData? weather) async {
    if (!mounted) return;
    setState(() {
      _weatherData = weather;
      _isLoadingWeather = false;
    });
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

            return RefreshIndicator(
              onRefresh: () async {
                await _loadWeather();
              },
              color: context.colors.primary,
              child: CustomScrollView(
                slivers: [
                  // Custom header with bell and profile
                  SliverToBoxAdapter(
                    child: ActivitiesHeader(
                      username: username,
                      onAvatarTap: () {
                        HomeTabScope.selectTabOrNull(context, HomeTab.profile);
                      },
                    ),
                  ),

                  // Weather card
                  SliverToBoxAdapter(
                    child: WeatherCard(
                      isLoading: _isLoadingWeather,
                      weatherData: _weatherData,
                    ),
                  ),

                  // Introduction card
                  const SliverToBoxAdapter(child: IntroductionCard()),

                  // Trending card
                  const SliverToBoxAdapter(child: TrendingCard()),
                  ActivitiesFeedSliver(
                    activityProvider: activityProvider,
                    user: user,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}
