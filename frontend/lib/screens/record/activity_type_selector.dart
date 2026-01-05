import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';

class ActivityTypeSelector extends StatelessWidget {
  const ActivityTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Activity Type'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(SyntrakSpacing.lg),
        crossAxisSpacing: SyntrakSpacing.md,
        mainAxisSpacing: SyntrakSpacing.md,
        childAspectRatio: 1.1,
        children: [
          _buildActivityTypeCard(context, ActivityType.alpine),
          _buildActivityTypeCard(context, ActivityType.crossCountry),
          _buildActivityTypeCard(context, ActivityType.freestyle),
          _buildActivityTypeCard(context, ActivityType.backcountry),
          _buildActivityTypeCard(context, ActivityType.snowboard),
          _buildActivityTypeCard(context, ActivityType.other),
        ],
      ),
    );
  }

  Widget _buildActivityTypeCard(
    BuildContext context,
    ActivityType type,
  ) {
    final color = ActivityHelpers.getActivityColor(type);
    final icon = ActivityHelpers.getActivityIcon(type);
    final label = type.displayName;
    final description = ActivityHelpers.getActivityDescription(type);
    
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
        onTap: () => Navigator.pop(context, type),
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: SyntrakSpacing.md),
              Text(
                label,
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: SyntrakColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SyntrakSpacing.xs),
              Text(
                description,
                style: SyntrakTypography.bodySmall.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

