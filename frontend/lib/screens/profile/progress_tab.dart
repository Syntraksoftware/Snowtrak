import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:intl/intl.dart';

class ProgressTab extends StatefulWidget {
  final List<Activity> activities;
  
  const ProgressTab({
    super.key,
    required this.activities,
  });

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  // Mock data - will be replaced with backend data
  final Map<String, dynamic> _weeklyStats = {
    'distance': 0.0, // km
    'time': 0, // minutes
    'elevGain': 0.0, // meters
  };
  
  final List<Map<String, dynamic>> _bestEfforts = [];
  final Map<String, dynamic> _goals = {
    'weeklyRuns': {'current': 1, 'target': 4},
    'description': 'Weekly Skiing Goal',
  };
  final Map<String, dynamic> _relativeEffort = {
    'current': 89,
    'previous': 22,
  };
  final Map<String, dynamic> _trainingLog = {
    'distance': 10.9, // km
    'dateRange': 'Jan 5 - Jan 11, 2026',
  };
  
  final Set<DateTime> _activityDays = {}; // Days with activities

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    // Calculate weekly stats
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    double weeklyDistance = 0;
    int weeklyTime = 0;
    double weeklyElevGain = 0;
    
    for (var activity in widget.activities) {
      if (activity.startTime.isAfter(weekStart)) {
        weeklyDistance += activity.distance / 1000; // Convert to km
        weeklyTime += activity.duration ~/ 60; // Convert to minutes
        weeklyElevGain += activity.elevationGain;
        _activityDays.add(DateTime(
          activity.startTime.year,
          activity.startTime.month,
          activity.startTime.day,
        ));
      }
    }
    
    // Calculate best efforts (mock for now)
    if (widget.activities.isNotEmpty) {
      // Sort by distance, time, etc. to find best efforts
      final sortedByDistance = List<Activity>.from(widget.activities)
        ..sort((a, b) => b.distance.compareTo(a.distance));
      
      if (sortedByDistance.isNotEmpty) {
        _bestEfforts.add({
          'type': '5K',
          'time': '26:54',
          'date': sortedByDistance.first.startTime,
          'isPR': true,
        });
      }
    }
    
    setState(() {
      _weeklyStats['distance'] = weeklyDistance;
      _weeklyStats['time'] = weeklyTime;
      _weeklyStats['elevGain'] = weeklyElevGain;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh data from backend
        await Future.delayed(const Duration(seconds: 1));
      },
      color: SyntrakColors.primary,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streaks subsection
            _buildStreaksSection(),
            
            // Weekly activity diagram
            _buildWeeklyActivityDiagram(),
            
            const SizedBox(height: SyntrakSpacing.lg),
            
            // Best Efforts card
            _buildBestEffortsCard(),
            
            const SizedBox(height: SyntrakSpacing.md),
            
            // Goals card
            _buildGoalsCard(),
            
            const SizedBox(height: SyntrakSpacing.md),
            
            // Relative Effort card
            _buildRelativeEffortCard(),
            
            const SizedBox(height: SyntrakSpacing.md),
            
            // Training Log card
            _buildTrainingLogCard(),
            
            const SizedBox(height: SyntrakSpacing.lg),
            
            // Start free trial button
            _buildFreeTrialButton(),
            
            const SizedBox(height: SyntrakSpacing.xl),
            
            // Activity calendar
            _buildActivityCalendar(),
            
            const SizedBox(height: SyntrakSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksSection() {
    return Container(
      margin: const EdgeInsets.all(SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: SyntrakColors.accent,
            size: 24,
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scroll down for streaks',
                  style: SyntrakTypography.labelLarge.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Text(
                  'Build habits with streaks - log one activity a week to keep it alive',
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityDiagram() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: SyntrakTypography.headlineMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          // Weekly stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildStatItem(
                  'Distance',
                  '${_weeklyStats['distance'].toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Time',
                  '${_weeklyStats['time']}m',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Elev Gain',
                  '${_weeklyStats['elevGain'].toStringAsFixed(0)} m',
                ),
              ),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.lg),
          // Past 12 weeks graph
          Text(
            'Past 12 weeks',
            style: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          SizedBox(
            height: 140,
            child: _build12WeeksGraph(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: SyntrakTypography.headlineSmall.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: SyntrakSpacing.xs),
        Text(
          label,
          style: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _build12WeeksGraph() {
    // Calculate weekly distances from activities
    final now = DateTime.now();
    final weeks = List.generate(12, (index) {
      final weekStart = now.subtract(Duration(days: (11 - index) * 7 + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      double weekDistance = 0.0;
      for (var activity in widget.activities) {
        if (activity.startTime.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            activity.startTime.isBefore(weekEnd.add(const Duration(days: 1)))) {
          weekDistance += activity.distance / 1000; // Convert to km
        }
      }
      
      return {
        'date': weekStart,
        'distance': weekDistance,
      };
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: CustomPaint(
            painter: _GraphPainter(weeks),
            child: Container(),
          ),
        ),
        const SizedBox(height: SyntrakSpacing.xs),
        // Month labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (weeks.isNotEmpty)
                Text(
                  DateFormat('MMM').format(weeks[0]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 6)
                Text(
                  DateFormat('MMM').format(weeks[6]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 11)
                Text(
                  DateFormat('MMM').format(weeks[11]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestEffortsCard() {
    return _buildCard(
      title: 'Best Efforts',
      child: _bestEfforts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.md,
                vertical: SyntrakSpacing.lg,
              ),
              child: Text(
                'No best efforts yet. Complete activities to see your records!',
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _bestEfforts.map((effort) {
                return _buildBestEffortItem(
                  isPR: effort['isPR'] ?? false,
                  type: effort['type'] ?? '',
                  time: effort['time'] ?? '',
                  date: effort['date'] as DateTime? ?? DateTime.now(),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildBestEffortItem({
    required bool isPR,
    required String type,
    required String time,
    required DateTime date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPR
                  ? SyntrakColors.accent.withOpacity(0.2)
                  : SyntrakColors.textTertiary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPR ? Icons.emoji_events : Icons.military_tech,
              color: isPR ? SyntrakColors.accent : SyntrakColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPR ? 'PR' : '2nd-fastest',
                      style: SyntrakTypography.labelMedium.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.xs),
                    Flexible(
                      child: Text(
                        type,
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.xs / 2),
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return _buildCard(
      title: 'Goals',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _goals['weeklyRuns']['current'] /
                        _goals['weeklyRuns']['target'],
                    strokeWidth: 4,
                    backgroundColor: SyntrakColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyntrakColors.success,
                    ),
                  ),
                ),
                Icon(
                  Icons.downhill_skiing,
                  color: SyntrakColors.primary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: SyntrakSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _goals['description'],
                    style: SyntrakTypography.bodyMedium.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SyntrakSpacing.xs),
                  Text(
                    '${_goals['weeklyRuns']['current']}/${_goals['weeklyRuns']['target']} activities',
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: SyntrakColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeEffortCard() {
    return _buildCard(
      title: 'Relative Effort',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRelativeEffortItem(
              _relativeEffort['current'],
              'Jan 6 - Jan 12, 2026',
              SyntrakColors.error,
            ),
            Divider(
              height: 1,
              color: SyntrakColors.divider,
            ),
            _buildRelativeEffortItem(
              _relativeEffort['previous'],
              'Dec 30 - Jan 5, 2026',
              SyntrakColors.snowboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeEffortItem(int value, String dateRange, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(SyntrakRadius.md),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Text(
              dateRange,
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingLogCard() {
    return _buildCard(
      title: 'Training Log',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _trainingLog['dateRange'],
                    style: SyntrakTypography.bodyMedium.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_trainingLog['distance']} km',
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SyntrakSpacing.md),
            // Calendar week view
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      day,
                      style: SyntrakTypography.labelSmall.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTrialButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement free trial
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SyntrakColors.accent,
          foregroundColor: SyntrakColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.md),
        ),
        child: Text(
          'Start a free trial',
          style: SyntrakTypography.labelLarge,
        ),
      ),
    );
  }

  Widget _buildActivityCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: SyntrakTypography.headlineSmall.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    day,
                    style: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          // Calendar grid
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final cellSize = (availableWidth - (6 * SyntrakSpacing.xs)) / 7;
              final minCellSize = 35.0;
              final actualCellSize = cellSize < minCellSize ? minCellSize : cellSize;
              
              return Wrap(
                spacing: SyntrakSpacing.xs,
                runSpacing: SyntrakSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                children: List.generate(firstWeekday - 1 + daysInMonth, (index) {
                  if (index < firstWeekday - 1) {
                    return SizedBox(
                      width: actualCellSize,
                      height: actualCellSize,
                    );
                  }
                  final day = index - (firstWeekday - 1) + 1;
                  final date = DateTime(now.year, now.month, day);
                  final hasActivity = _activityDays.contains(
                    DateTime(date.year, date.month, date.day),
                  );
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  return SizedBox(
                    width: actualCellSize,
                    height: actualCellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasActivity
                            ? SyntrakColors.primary.withOpacity(0.2)
                            : SyntrakColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: SyntrakColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: SyntrakTypography.labelSmall.copyWith(
                            color: hasActivity
                                ? SyntrakColors.primary
                                : SyntrakColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: SyntrakColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
          child,
          const SizedBox(height: SyntrakSpacing.sm),
        ],
      ),
    );
  }
}

// Custom painter for the 12 weeks graph
class _GraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> weeks;

  _GraphPainter(this.weeks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SyntrakColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = SyntrakColors.accent
      ..style = PaintingStyle.fill;

    final distances = weeks.map((w) => w['distance'] as double).toList();
    final maxDistance = distances.isEmpty 
        ? 1.0 
        : distances.reduce((a, b) => a > b ? a : b);

    // Prevent division by zero
    final stepX = weeks.length <= 1 ? 0.0 : size.width / (weeks.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < weeks.length; i++) {
      final distance = weeks[i]['distance'] as double;
      final normalizedDistance = maxDistance > 0 ? (distance / maxDistance) : 0.0;
      final y = size.height - (normalizedDistance * size.height);
      final x = weeks.length <= 1 ? size.width / 2 : i * stepX;
      
      // Ensure valid coordinates
      if (x.isFinite && y.isFinite) {
        points.add(Offset(x, y));
      }
    }

    // Draw line (only if we have valid points)
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx.isFinite && 
          points[i].dy.isFinite && 
          points[i + 1].dx.isFinite && 
          points[i + 1].dy.isFinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw points (only valid ones)
    for (final point in points) {
      if (point.dx.isFinite && point.dy.isFinite) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }

    // Highlight last point
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      if (lastPoint.dx.isFinite && lastPoint.dy.isFinite) {
        final highlightPaint = Paint()
          ..color = SyntrakColors.accent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(lastPoint, 6, highlightPaint);
        
        // Draw vertical line
        final linePaint = Paint()
          ..color = SyntrakColors.textPrimary.withOpacity(0.3)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(lastPoint.dx, 0),
          Offset(lastPoint.dx, size.height),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

