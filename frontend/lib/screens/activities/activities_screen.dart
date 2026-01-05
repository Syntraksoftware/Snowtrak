import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/activities/activity_detail_screen.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false).loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
            tooltip: 'Filter activities',
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.activities.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
              ),
            );
          }

          if (provider.activities.isEmpty) {
            return Center(
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
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadActivities(),
            color: SyntrakColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(SyntrakSpacing.md),
              itemCount: provider.activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: SyntrakSpacing.md),
              itemBuilder: (context, index) {
                final activity = provider.activities[index];
                return _ActivityCard(activity: activity);
              },
            ),
          );
        },
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

