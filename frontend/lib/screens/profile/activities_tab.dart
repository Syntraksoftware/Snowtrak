import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/features/activities/data/activities_repository.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/profile/widgets/profile_activity_list_card.dart';
import 'package:snowtrak/screens/profile/widgets/profile_activities_search_bar.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({
    super.key,
    required this.activities,
  });

  final List<Activity> activities;

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  final ActivitiesRepository _repo = sl<ActivitiesRepository>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;
  final Map<String, bool> _kudosMap = {};
  final Map<String, int> _kudosCountMap = {};

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ActivitiesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    final activities = widget.activities.isNotEmpty
        ? List<Activity>.from(widget.activities)
        : await _repo.getMyActivities();
    activities.sort((a, b) => b.startTime.compareTo(a.startTime));

    setState(() {
      _activities = activities;
      _filteredActivities = activities;

      for (final activity in activities) {
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

  SliverAppBar _pinnedSearchBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: innerBoxIsScrolled ? 2 : 0,
      shadowColor: context.colors.scrim,
      toolbarHeight: 72,
      flexibleSpace: ProfileActivitiesSearchBar(
        controller: _searchController,
        onClear: () {
          _searchController.clear();
          _onSearchChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    if (_isLoading) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _pinnedSearchBar(innerBoxIsScrolled),
        ],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredActivities.isEmpty && _searchQuery.isNotEmpty) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _pinnedSearchBar(innerBoxIsScrolled),
        ],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: context.colors.textTertiary,
              ),
              const SizedBox(height: SnowtrakSpacing.md),
              Text(
                'No activities found',
                style: SnowtrakTypography.headlineSmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: SnowtrakSpacing.sm),
              Text(
                'Try a different search term',
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: context.colors.textTertiary,
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
          _pinnedSearchBar(innerBoxIsScrolled),
        ],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(SnowtrakSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.downhill_skiing,
                  size: 80,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(height: SnowtrakSpacing.lg),
                Text(
                  'No activities yet',
                  style: SnowtrakTypography.headlineMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.sm),
                Text(
                  'Start recording your first skiing activity!',
                  style: SnowtrakTypography.bodyMedium.copyWith(
                    color: context.colors.textTertiary,
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
        _pinnedSearchBar(innerBoxIsScrolled),
      ],
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        color: context.colors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(SnowtrakSpacing.md),
          itemCount: _filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = _filteredActivities[index];
            final isFirstActivity = index == 0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _filteredActivities.length - 1
                    ? SnowtrakSpacing.md
                    : 0,
              ),
              child: ProfileActivityListCard(
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

  void _toggleKudos(String activityId) {
    setState(() {
      final currentValue = _kudosMap[activityId] ?? false;
      _kudosMap[activityId] = !currentValue;
      final currentCount = _kudosCountMap[activityId] ?? 0;
      _kudosCountMap[activityId] =
          currentValue ? currentCount - 1 : currentCount + 1;
    });
    // ponytail: kudos backend not wired yet
  }

  void _shareActivity(String activityId) {}

  void _commentActivity(String activityId) {}
}
